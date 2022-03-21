use strict;
use utf8;
$| = 1;

# core_uni/pub/base 以下に：
#	/web
#	/win_pkg  →現行のWindows版パッケージを解凍しておく
#	# /win_upd  →現行のWindows版バイナリを解凍しておく
#	# /win_strb →現行のWindows・Strawberry版を解凍しておく

# 配布パッケージに新しいファイルを加える場合は @cp_f を編集（後ろに追加）
# 新たなPerlモジュールを使い始める場合にはStrawberry Perlの編集が必要

$Archive::Tar::DO_NOT_USE_PREFIX = 1;

# 初期設定
require "../kh_lib/kh_about.pm";
my $V = kh_about->version_short;
my $V_full = kh_about->version;

# マニュアル・チュートリアルのPDFを再作成するか
my $pdf = 0;

# 環境設定
my $github_token;

if ( -e "f:/home/Koichi/Google Drive/KHC/SSH-Key-Github/token" ) { # Home
	$github_token = "f:/home/Koichi/Google Drive/KHC/SSH-Key-Github/token";
}
elsif (-e "hoge") { # Vaio
	$github_token = "hoge";
} else {
	die("No GitHub Token!");
}

# 更新するファイルの指定
my @cp_f = (
	['kh_coder.exe' , 'kh_coder.exe'  ],
	['config/msg.en', 'config/msg.en' ],
	['config/msg.jp', 'config/msg.jp' ],
	['config/msg.es', 'config/msg.es' ],
	['config/msg.cn', 'config/msg.cn' ],
	['config/msg.kr', 'config/msg.kr' ],
);

use File::Find 'find';
find(
	sub {
		if ($_ =~ /\.pm$/ || $_ =~ /\.r$/){
			push @cp_f, ['plugin_en/'.$_, 'plugin_en/'.$_]
				unless -d $File::Find::name
			;
		}
	},
	'../plugin_en'
);

find(
	sub {
		if ($_ =~ /\.pm$/ || $_ =~ /\.r$/){
			push @cp_f, ['plugin_jp/'.$_, 'plugin_jp/'.$_]
				unless -d $File::Find::name
			;
		}
	},
	'../plugin_jp'
);

# 古いプラグインはすべて削除
find(
	sub {
		unlink $_ or die($File::Find::name) unless -d $_;
	},
	'../pub/win_pkg/plugin_en'
);

find(
	sub {
		unlink $_ or die unless -d $_;
	},
	'../pub/win_pkg/plugin_jp'
);


#------------------------------------------------------------------------------
#                                     実行
#------------------------------------------------------------------------------

&web;
	#&pdfs if $pdf;
	#&source_tgz;
&win_pkg;
	#&win_upd;
	#&win_strb;
&upload;

use Archive::Tar;
use File::Copy;
use File::Copy::Recursive 'dircopy';
use Win32::Process;
use Time::Piece;
use Net::SFTP::Foreign;
use LWP::UserAgent;
use File::Path 'rmtree';
use Encode;

sub upload{
	# getting ready
	open my $fh, '<', $github_token or die;
	my $token = <$fh>;
	close $fh;
	$ENV{GITHUB_TOKEN} = $token;

	use Net::GitHub;
	my $gh = Net::GitHub->new(
		version => 3,
		login => 'ko-ichi-h',
		access_token => $token
	);
	my $repos = $gh->repos;
	$repos->set_default_user_repo('ko-ichi-h', 'khcoder');

	if (1) {
		# Create a tag on Github
		system("git tag -a $V_full -m \"$V\"");
		system("git push origin $V_full");
		
		# Create a release on Github
		my $release_new = $repos->create_release({
			"tag_name"         => $V_full,
			"target_commitish" => "master",
			"name"             => $V_full,
			"body"             => $V,
			"draft"            => \0,
		});
	}

	# Upload Windows binary to the release
	my $release;
	my @releases = $repos->releases();
	foreach my $i (@releases) {
		if ($i->{name} eq $V_full ){
			$release = $i;
			last;
		}
	}
	
	unless ( $release->{id} ){
		for (my $n = 0; $n < 10; ++$n){
			print "kh: waiting for github to create the release ($n)...\n";
			sleep 10;
			my @releases = $repos->releases();
			foreach my $i (@releases) {
				if ($i->{name} eq $V_full ){
					$release = $i;
					last;
				}
			}
			if ($release->{id}){
				last;
			}
		}
	}
	print "kh: Release id: $release->{id}\n";

	
	open my $fh, '<', "builds/khcoder-$V.exe" or die;
	binmode $fh;
	my $file_content;
	my $count = read($fh, $file_content, -s "builds/khcoder-$V.exe");
	close $fh;
	
	print "kh: Read $count bytes. Uploading...\n";
	my $asset = $repos->upload_asset(
		$release->{id},
		"khcoder-$V.exe",
		'application/octet-stream',
		$file_content
	);

	# Create a release on Github using github-release
	#    https://github.com/aktau/github-release
	#
	# But I get "error: could not upload, status code (504 Gateway Time-out)"
	# Any Idea?
	#
	#open my $fh, '<', $github_token or die;
	#my $token = <$fh>;
	#close $fh;
	#$ENV{GITHUB_TOKEN} = $token;
	#
	#system("github-release release --user ko-ichi-h --repo khc --tag $V_full --name $V_full --description \"$V\" ");
	#
	#print "Uploading...\n";
	#system("github-release --verbose upload --user ko-ichi-h --repo khc --tag $V_full --name \"khcoder-$V.exe\" --file khcoder-$V.exe ");
	#
	# This way is much faster but I got the 504 error from the above line.



	copy('../pub/web/en_index.html', '../../core_web/en/index.html');
	copy('../pub/web/dl3.html',      '../../core_web/dl3.html');
	copy('../pub/web/index.html',    '../../core_web/index.html');

	chdir('../../core_web');
	system("git commit -a -m \"release $V_full\"");
	system("git push origin master");

	# 移動
	chdir('../core_uni/utils');
}


sub web{
	my $ua = LWP::UserAgent->new(
		agent      => 'Mozilla/5.0 (Windows NT 6.1; rv:19.0) Gecko/20100101 Firefox/19.0',
	);
	
	# 日付
	my $time = localtime;
	my $year = $time->year;
	my $mon  = $time->mon;
	my $day  = $time->mday;
	$mon = '0'.$mon if $mon < 10;
	$day = '0'.$day if $day < 10;
	my $date = "$year $mon/$day";
	
	my $t = '';
	
	# index.html
	my $r0 = $ua->get('http://khcoder.net/index.html') or die;
	$t = '';
	$r0->is_success or die;
	$t = Encode::decode('UTF-8', $r0->content);
	$t =~ s/\x0D\x0A|\x0D|\x0A/\n/g; # 改行コード
	
	$t =~ s/KH Coder 3 ダウンロード<\/a><font size=\-1 color="#3cb371">（.+）<\/font>/KH Coder 3 ダウンロード<\/a><font size=\-1 color="#3cb371">（$V_full - $date）<\/font>/;
	
	open(my $fh, ">:encoding(UTF-8)", "../pub/web/index.html") or die("$!");
	print $fh $t;
	close ($fh);
	
	# en/index.html
	my $r2 = $ua->get('http://khcoder.net/en/index.html') or die;
	my $t = '';
	$r2->is_success or die;
	$t = $r2->content;
	$t =~ s/\x0D\x0A|\x0D|\x0A/\n/g; # 改行コード

	#$t =~ s/Ver\. 2\.[Bb]eta\.[0-9]+[a-z]*</Ver\. $V_full</;  # バージョン番号
	#$t =~ s/20[0-9]{2} [0-9]{2}\/[0-9]{2}/$date/;             # 日付
	$t =~ s/khc\/releases\/tag\/3\.[0-9a-zA-Z\.]+?\//khc\/releases\/tag\/$V_full\//; # ダウンロードフォルダ
	#
	open(my $fh, '>', "../pub/web/en_index.html") or die;
	print $fh $t;
	close ($fh);
	
	# dl3.html
	my $r1 = $ua->get('http://khcoder.net/dl3.html') or die;
	$t = '';
	$r1->is_success or die;
	$t = $r1->content;
	$t =~ s/\x0D\x0A|\x0D|\x0A/\n/g; # 改行コード
	
	$t =~ s/\(20[0-9]{2} [0-9]{2}\/[0-9]{2}\)/($date)/g;                 # 日付
	$t =~ s/khcoder\-3[ab\.]*[0-9]+[a-zA-Z]*([\-\.])/khcoder\-$V$1/g;       # ファイル名
	$t =~ s/download\/3[\.a-zA-Z0-9]+\//download\/$V_full\//g; # フォルダ名1

	open(my $fh, '>', "../pub/web/dl3.html") or die;
	print $fh $t;
	close ($fh);
}

sub pdfs{
	# パスワード
	open (my $fh, '<', 'pass.txt') or die;
	my $pass = readline $fh;
	close ($fh);
	undef $fh;

	# Distillerのパス
	system('where acrodist.exe > temp.txt');
	open (my $fh,'<',"temp.txt") or die;
	my $acro_path = readline $fh;
	close $fh;
	unlink("temp.txt");
	chomp $acro_path;
	unless (-e $acro_path){
		die("Could not find Distiller.");
	}

	# 移動
	chdir('..');
	chdir('..');
	chdir('..');
	chdir('doc');
	chdir('tex__phd');
	
	# Distillerの起動
	my $acro_proc;
	Win32::Process::Create(
		$acro_proc,
		$acro_path,
		"acrodist",
		0,
		NORMAL_PRIORITY_CLASS,
		"."
	) or die("Could not start Distiller");
	
	# LaTeX
	system('platex  khcoder_manual_b5');
	system('platex  khcoder_manual_b5');
	system('jbibtex khcoder_manual_b5');
	system('mendex -s dot.ist khcoder_manual_b5');
	system('platex  khcoder_manual_b5');
	system('platex  khcoder_manual_b5');
	
	system('platex  khcoder_tutorial');
	system('platex  khcoder_tutorial');
	system('jbibtex khcoder_tutorial');
	system('platex  khcoder_tutorial');
	system('platex  khcoder_tutorial');
	
	# pdf
	system('dvipdfmx khcoder_manual_b5');
	system('dvipdfmx khcoder_tutorial');

	$acro_proc->Kill(1);
	move('khcoder_manual_b5.pdf', 'khcoder_manual.pdf');

	# security
	system("pdftk khcoder_manual.pdf output out1.pdf owner_pw $pass allow printing screenreaders");
	move('out1.pdf', 'khcoder_manual.pdf');
	system("pdftk khcoder_tutorial.pdf output out2.pdf owner_pw $pass allow printing screenreaders");
	move('out2.pdf', 'khcoder_tutorial.pdf');

	copy ('khcoder_manual.pdf', '../../perl/core/pub/base/win_pkg/khcoder_manual.pdf') or die;
	copy ('khcoder_manual.pdf', '../../perl/core/pub/base/win_upd/khcoder_manual.pdf') or die;
	copy ('khcoder_manual.pdf', '../../perl/core/pub/base/win_strb/khcoder_manual.pdf') or die;
	copy ('khcoder_manual.pdf', '../../perl/core/utils/khcoder_manual.pdf') or die;

	copy ('khcoder_tutorial.pdf', '../../perl/core/pub/base/win_pkg/khcoder_tutorial.pdf') or die;
	copy ('khcoder_tutorial.pdf', '../../perl/core/pub/base/win_upd/khcoder_tutorial.pdf') or die;
	copy ('khcoder_tutorial.pdf', '../../perl/core/pub/base/win_strb/khcoder_tutorial.pdf') or die;
	copy ('khcoder_tutorial.pdf', '../../perl/core/utils/khcoder_tutorial.pdf') or die;

	# 移動
	chdir('..');
	chdir('..');
	chdir('perl');
	chdir('core');
	chdir('utils');

}


sub win_upd{
	chdir("..");
	
	# 新しいファイルを「pub/base/win_upd」へコピー
	foreach my $i (@cp_f){
		copy($i->[0], 'pub/base/win_upd/'.$i->[1]) or die("Can not copy $i\n");
		print "copy: $i->[1]\n";
	}
	
	# Zipファイルを作成
	unlink("utils\\khcoder-$V-s.zip");
	system("wzzip -rp -ex utils\\khcoder-$V-s.zip pub\\base\\win_upd");
	
	chdir("utils");
}

sub win_strb{
	chdir("..");
	
	# khc.plを作成
	open (my $fh, '<', 'utils/kh_coder/kh_coder.pl') or die;
	my $t = do { local $/; <$fh> };
	close $fh;
	
	$t =~ s/\t\tif.*?PerlApp.*?\n/\t\tif (1) {\n/;
	
	open (my $fh, '>', 'pub/base/win_strb/khc.pl') or die;
	print $fh $t;
	close $fh;
	
	# 新しいファイルを「pub/base/win_strb」へコピー（1）strb特有
	rmtree('pub/base/win_strb/kh_lib');
	dircopy('utils/kh_coder/kh_lib', 'pub/base/win_strb/kh_lib');
	shift @cp_f;
	
	# 新しいファイルを「pub/base/win_strb」へコピー（2）共通
	foreach my $i (@cp_f){
		copy($i->[0], 'pub/base/win_strb/'.$i->[1]) or die("Can not copy $i\n");
		print "kh: copy: $i->[1]\n";
	}
	
	# Zipファイルを作成
	unlink("utils\\khcoder-$V-strb.zip");
	system("wzzip -rp -ex utils\\khcoder-$V-strb.zip pub\\base\\win_strb");
	
	chdir("utils");
}


sub win_pkg{
	# 「kh_coder.exe」を作成
	# chdir("..");

	#system("svn update");
	unlink("..\\kh_coder.exe");
	system("make_exe.bat");
	unless (-e "..\\kh_coder.exe"){
		die("Could not create \"kh_coder.exe\"\n");
	}
	
	require Win32::API;
	my $win = Win32::API->new(
		'user32.dll',
		'FindWindow',
		'NP',
		'N'
	)->Call(
		0,
		"Console of KH Coder"
	);
	Win32::API->new(
		'user32.dll',
		'ShowWindow',
		'NN',
		'N'
	)->Call(
		$win,
		9
	);
	
	# 新しいファイルを「pub/win_pkg」へコピー
	chdir("..");
	foreach my $i (@cp_f){
		print "copy: $i->[0]\n";
		copy("$i->[0]", 'pub/win_pkg/'."$i->[1]") or die("Can not copy $i->[0]\n");
	}

	# Zip自己解凍ファイルを作成
	unlink("utils\\builds\\khcoder-$V.zip");
	unlink("utils\\builds\\khcoder-$V.exe");
	system("wzzip -rp -ex utils\\builds\\khcoder-$V.zip pub\\win_pkg");
	sleep 5;
	system("wzipse32 utils\\builds\\khcoder-$V.zip -y -d C:\\khcoder3 -le -overwrite -c .\\create_shortcut.exe");
	
	for (my $n = 0; $n < 5; ++$n){
		if (-e "utils\\builds\\khcoder-$V.exe" && -e "utils\\builds\\khcoder-$V.zip") {
			last;
		}
		sleep 5;
		system("wzipse32 utils\\builds\\khcoder-$V.zip -y -d C:\\khcoder3 -le -overwrite -c .\\create_shortcut.exe");
	}
	unlink("utils\\builds\\khcoder-$V.zip");

	chdir("utils");
}

sub source_tgz{
	#--------------------------#
	#   最新ソースを取り出し   #

	rmtree('core');
	rmtree('kh_coder');

	chdir('..');
	system('git checkout-index -a -f --prefix=utils/core/');
	chdir('utils');

	#--------------------------#
	#   不要なファイルを削除   #

	my @rm_dir = (
		'core/auto_test',
		'core/test',
		'core/utils',
	);

	my @rm_f = (
		'core/memo/bib.html',
		'core/memo/bib.tsv',
		'core/memo/bib_t2h.pl',
		'core/memo/bib_t2h.bat',
		'core/memo/db_memo.csv',
		'core/memo/bib_ng.txt',
		'core/memo/devnote.txt',
		'core/memo/1.icns',
		'core/memo/performance.csv',
		'core/auto_test.pl',
		'core/kh_coder.perlapp',
		'core/make_exe.bat',
		'core/make_exe_as.bat',
		'core/x_mac64.perlapp',
		'core/x_mac64.scpt',
		'core/x_mac64setup.perlapp',
		'core/x_mac64setup.pl',
		'core/x_mac64setup.scpt',
	);

	foreach my $i (@rm_dir){
		rmtree ($i) or warn("warn: could not delete: $i\n");
	}

	foreach my $i (@rm_f){
		unlink ($i) or warn("warn: could not delete: $i\n");
	}

	#---------------------#
	#   ソースZipを作成   #

	unlink("khcoder-$V.tar.gz");

	rename('core', 'kh_coder')
		or warn("warn: could not rename core to kh_coder\n")
	;

	my @files;
	find(
		sub {
			push @files, $File::Find::name;
		},
		"kh_coder"
	);

	my $tar = Archive::Tar->new;
	$tar->add_files(@files);
	$tar->write("khcoder-$V.tar.gz",9);
}