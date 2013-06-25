use strict;

# core/pub/base 以下に：
#	/web
#	/win_pkg  →現行のWindows版パッケージを解凍しておく
#	/win_upd  →現行のWindows版バイナリを解凍しておく
#	/win_strb →現行のWindows・Strawberry版を解凍しておく

# 配布パッケージに新しいファイルを加える場合は @cp_f を編集（後ろに追加）
# 新たなPerlモジュールを使い始める場合にはStrawberry Perlの編集が必要

$Archive::Tar::DO_NOT_USE_PREFIX = 1;

# 初期設定
my $V = '2b30b';
my $V_main = "2.Beta.30";
my $V_full = "2.Beta.30b";

my $pdf = 1;

# 環境設定
my $home_dir = '';
my $key_file = '';

if ( -e "f:/home/koichi/study/.ssh/id_dsa" ) { # 家PC
	$key_file = 'f:/home/koichi/study/.ssh/id_dsa';
	$home_dir = 'f:/home/koichi/study/';
	system("set HOME=$home_dir");
}

# 更新するファイルの指定
my @cp_f = (
	['kh_coder.exe' , 'kh_coder.exe'  ],
	['config/msg.en', 'config/msg.en' ],
	['config/msg.jp', 'config/msg.jp' ],
);

use File::Find 'find';
find(
	sub {
		push @cp_f, [$File::Find::name, 'plugin_en/'.$_]
			unless $File::Find::name eq 'utils/kh_coder/plugin_en'
		;
	},
	'utils/kh_coder/plugin_en'
);

find(
	sub {
		push @cp_f, [$File::Find::name, 'plugin_jp/'.$_]
			unless $File::Find::name eq 'utils/kh_coder/plugin_jp'
		;
	},
	'utils/kh_coder/plugin_jp'
);

# 実行

use Archive::Tar;
use File::Copy;
use File::Copy::Recursive 'dircopy';
use Win32::Process;
use Time::Piece;
use Net::SFTP::Foreign;
use LWP::UserAgent;
use File::Path 'rmtree';

#&web;
#&pdfs if $pdf;
#&source_tgz;
#&win_pkg;
#&win_upd;
#&win_strb;
&upload;

sub upload{
	print "Uploading...\n";

	my $sftp = Net::SFTP::Foreign->new(
		host => 'web.sourceforge.net',
		user => 'ko-ichi,khc',
		key_path => $key_file,
	);
	
	# Files
	if ($pdf){
		$sftp->setcwd("/home/pfs/project/khc/Manual");
		print "put: khcoder_manual.pdf\n";
		$sftp->put ("khcoder_manual.pdf", "khcoder_manual.pdf") or die;
		
		$sftp->setcwd("/home/pfs/project/khc/Tutorial/for KH Coder 2.x");
		print "put: khcoder_tutorial.pdf\n";
		$sftp->put ("khcoder_tutorial.pdf", "khcoder_tutorial.pdf") or die;
	}
	
	$sftp->setcwd("/home/pfs/project/khc/KH Coder");
	$sftp->mkdir($V_main);
	$sftp->setcwd($V_main);
	foreach my $i (
		"khcoder-$V-strb.zip",
		"khcoder-$V.tar.gz",
		"khcoder-$V-s.zip",
		"khcoder-$V-f.exe",
	){
		print "put: $i\n";
		$sftp->put ($i, $i) or die;
	}
	
	# Web pages
	$sftp->setcwd("/home/project-web/khc/htdocs");
	
	foreach my $i (
		"index.html",
		"dl.html",
	){
		$sftp->put ("../pub/base/web/$i", $i) or die;
	}
	
	$sftp->setcwd("en");
	$sftp->put ("../pub/base/web/en_index.html", "index.html") or die;
	
	$sftp->disconnect;
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
	
	# index.html
	my $r0 = $ua->get('http://khc.sourceforge.net/index.html') or die;
	my $t = '';
	$t = $r0->content;
	
	$t =~ s/Ver\. 2\.[Bb]eta\.[0-9]+[a-z]*</Ver\. $V_full</;  # バージョン番号
	$t =~ s/20[0-9]{2} [0-9]{2}\/[0-9]{2}/$date/;             # 日付
	
	open(my $fh, '>', "../pub/base/web/index.html") or die;
	print $fh $t;
	close ($fh);
	
	# en/index.html
	my $r2 = $ua->get('http://khc.sourceforge.net/en/index.html') or die;
	my $t = '';
	$t = $r2->content;
	
	$t =~ s/Ver\. 2\.[Bb]eta\.[0-9]+[a-z]*</Ver\. $V_full</;  # バージョン番号
	$t =~ s/20[0-9]{2} [0-9]{2}\/[0-9]{2}/$date/;             # 日付
	
	open(my $fh, '>', "../pub/base/web/en_index.html") or die;
	print $fh $t;
	close ($fh);
	
	# dl.html
	my $r1 = $ua->get('http://khc.sourceforge.net/dl.html') or die;
	$t = '';
	$t = $r1->content;

	$t =~ s/20[0-9]{2} [0-9]{2}\/[0-9]{2}/$date/g;                 # 日付
	$t =~ s/khcoder\-2b[0-9]+[a-z]*([\-\.])/khcoder\-$V$1/g;       # ファイル名
	$t =~ s/KH%20Coder\/2\.Beta\.[0-9]+\//KH%20Coder\/$V_main\//g; # フォルダ名

	open(my $fh, '>', "../pub/base/web/dl.html") or die;
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
	system("pdftk khcoder_manual.pdf output out1.pdf owner_pw hoge allow printing screenreaders");
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
		print "copy: $i->[1]\n";
	}
	
	# Zipファイルを作成
	unlink("utils\\khcoder-$V-strb.zip");
	system("wzzip -rp -ex utils\\khcoder-$V-strb.zip pub\\base\\win_strb");
	
	chdir("utils");
}


sub win_pkg{
	# 「kh_coder.exe」を作成
	chdir("..");

	system("cvs update");
	unlink("kh_coder.exe");
	system("make_exe.bat");
	unless (-e "kh_coder.exe"){
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
	
	# 新しいファイルを「pub/base/win_pkg」へコピー
	foreach my $i (@cp_f){
		copy($i->[0], 'pub/base/win_pkg/'.$i->[1]) or die("Can not copy $i\n");
		print "copy: $i->[1]\n";
	}

	# Zip自己解凍ファイルを作成
	unlink("utils\\khcoder-$V-f.zip");
	unlink("utils\\khcoder-$V-f.exe");
	system("wzzip -rp -ex utils\\khcoder-$V-f.zip pub\\base\\win_pkg");
	system("wzipse32 utils\\khcoder-$V-f.zip -y -d C:\\khcoder -le -overwrite");unlink("utils\\khcoder-$V-f.zip");

	chdir("utils");
}

sub source_tgz{
	#---------------------------------#
	#   CVSから最新ソースを取り出し   #


	my $cvs_cmd = 'cvs -d ":ext;command=\'';

	if (-d $home_dir){
		$cvs_cmd .= "set HOME=f:/home/koichi& ";
	}

	$cvs_cmd .= "ssh -l ko-ichi ";

	if (-d $home_dir){
		$cvs_cmd .= "-i $key_file ";
	}

	$cvs_cmd .= "khc.cvs.sourceforge.net':ko-ichi\@khc.cvs.sourceforge.net:/cvsroot/khc\" ";
	$cvs_cmd .= "export -r HEAD -- core";

	print "cmd: $cvs_cmd\n";

	rmtree('core');
	rmtree('kh_coder');
	system($cvs_cmd);

	#--------------------------#
	#   不要なファイルを削除   #

	my @rm_dir = (
		'core/.settings',
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
		'core/memo/devnote.txt',
		'core/memo/performance.csv',
		'core/plugin_jp/jssdb_bench1.pm',
		'core/plugin_jp/jssdb_prepare.pm',
		'core/plugin_jp/jssdb_search.pm',
		'core/auto_test.pl',
		'core/kh_coder.perlapp',
		'core/make_exe.bat',
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