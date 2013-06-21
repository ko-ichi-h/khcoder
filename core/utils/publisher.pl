use strict;
use Archive::Tar;
use File::Find 'find';
use File::Path 'rmtree';

$Archive::Tar::DO_NOT_USE_PREFIX = 1;

my $V = '2b30b';

#&source_tgz;
&win_pkg;


sub win_pkg{

	# 「kh_coder.exe」を作成
	chdir("..");
	#system("cvs update");
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
	
	
	
	chdir("utils");

}

sub source_tgz{
	#---------------------------------#
	#   CVSから最新ソースを取り出し   #

	my $home_dir = '';
	my $key_file = '';

	# 家PC
	if ( -e "f:/home/koichi/study/.ssh/id_dsa" ) {
		$key_file = 'f:/home/koichi/study/.ssh/id_dsa';
		$home_dir = 'f:/home/koichi';
	}

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

	use File::Path 'rmtree';
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