package kh_all_in_one;
use strict;

#-------------------------------#
#   All In One 版の起動・終了   #
#-------------------------------#

# All In One版では、
# (1)「config\coder.ini」に下記の設定を加える
#	all_in_one_pack	1
#	sql_username	khc
#	sql_password	khc
#	sql_host	localhost
#	sql_port	3307
# (2) 同梱するMySQLの設定
#	ユーザー設定: khc[khc], root[khcallinone]
#	「khc.ini」も添付する

sub init{
	# 利用可能なメモリの量を取得
	require Win32::SystemInfo;
	my %mHash = (AvailPhys => 0);
	Win32::SystemInfo::MemoryStatus(\%mHash,'MB');
	$mHash{AvailPhys} = 32 if $mHash{AvailPhys} < 32;
	$mHash{AvailPhys} = int($mHash{AvailPhys});
	$mHash{AvailPhys} = 2048 if $mHash{AvailPhys} > 2048;
	print "Available Physical Memory: $mHash{AvailPhys}MB\n";
	$mHash{AvailPhys} = $mHash{AvailPhys} - 500;
	$mHash{AvailPhys} = 16 if $mHash{AvailPhys} < 16;

	# 64bit / 32bit 
	require Devel::Platform::Info::Win32;
	my $os_info = Devel::Platform::Info::Win32->new->get_info();
	if ( $ENV{PROCESSOR_ARCHITEW6432} =~ /ARM/ ) { # recognize ARM as 32bit
		$os_info->{wow64} = 0;
	}

	# pandocのパスを追加
	my $pandoc = $::config_obj->cwd.'/dep/pandoc-2.7.3-windows-i386';
	$::config_obj->os_path($pandoc);
	$::ENV{PATH} = "$pandoc".";"."$::ENV{PATH}";

	# 茶筌のパス設定
	if (
		not -e $::config_obj->chasen_path
		and -e $::config_obj->cwd.'/dep/chasen/chasen.exe'
	) { 
		$::config_obj->chasen_path(
			$::config_obj->cwd.'/dep/chasen/chasen.exe'
		);
	}

	# Mecabのパス設定
	if (
		not -e $::config_obj->mecab_path
		and -e $::config_obj->cwd.'/dep/mecab/bin/mecab.exe'
	) { 
		$::config_obj->mecab_path(
			$::config_obj->cwd.'/dep/mecab/bin/mecab.exe'
		);
	}
	
	# FreeLingのパス設定
	if (
		not -d $::config_obj->freeling_dir
		and -d $::config_obj->cwd.'/dep/freeling40'
	) { 
		$::config_obj->freeling_dir(
			$::config_obj->cwd.'/dep/freeling40'
		);
	}
	
	# JAVAのパス設定
	unless ( -e $::config_obj->java_path ) {
		if (
			( ($os_info->{wow64} == 1) || ($os_info->{is64bit} == 1) )
			&& -e $::config_obj->cwd.'/dep/AdoptOpenJDK64/bin/java.exe'
		){
			$::config_obj->java_path(
				$::config_obj->cwd.'/dep/AdoptOpenJDK64/bin/java.exe'
			);
		}
		elsif (-e $::config_obj->cwd.'/dep/AdoptOpenJDK/bin/java.exe') {
			$::config_obj->java_path(
				$::config_obj->cwd.'/dep/AdoptOpenJDK/bin/java.exe'
			);
		}
		else {
			require Win32::SearchPath;
			my $j = Win32::SearchPath::SearchPath('java');
			if (-e $j && length($j) ) {
				$::config_obj->java_path($j);
			}
		}
	}
	
	# HanDicのパス設定
	if (
		not -d $::config_obj->han_dic_path
		and -d $::config_obj->cwd.'/dep/handic'
	) { 
		$::config_obj->han_dic_path(
			$::config_obj->cwd.'/dep/handic'
		);
	}
	
	# Stanford segmenterのパス設定
	if (
		not -d $::config_obj->stanf_seg_path
		and -d $::config_obj->cwd.'/dep/stanford-segmenter'
	) { 
		$::config_obj->stanf_seg_path(
			$::config_obj->cwd.'/dep/stanford-segmenter'
		);
	}

	# Stanford POS Taggerのパス設定
	if (
		not -e $::config_obj->stanf_tagger_path_en
		and -e $::config_obj->cwd.'/dep/stanford-postagger/models/wsj-0-18-left3words-distsim.tagger'
	) {
		$::config_obj->stanf_tagger_path_en(
			$::config_obj->cwd.'/dep/stanford-postagger/models/wsj-0-18-left3words-distsim.tagger'
		);
	}

	if (
		not -e $::config_obj->stanf_tagger_path_cn
		and -e $::config_obj->cwd.'/dep/stanford-postagger/models/chinese-distsim.tagger'
	) {
		$::config_obj->stanf_tagger_path_cn(
			$::config_obj->cwd.'/dep/stanford-postagger/models/chinese-distsim.tagger'
		);
	}

	if (
		not -e $::config_obj->stanf_jar_path
		and -e $::config_obj->cwd.'/dep/stanford-postagger/stanford-postagger.jar'
	) {
		$::config_obj->stanf_jar_path(
			$::config_obj->cwd.'/dep/stanford-postagger/stanford-postagger.jar'
		);
	}

	# Rのパス設定
	if (not -e $::config_obj->r_path){
		my $candidate = '';
		if (
			( ($os_info->{wow64} == 1) || ($os_info->{is64bit} == 1) )
			&& -e $::config_obj->cwd.'/dep/R/bin/x64/Rterm.exe'
		){
			$candidate = '/dep/R/bin/x64/Rterm.exe';
		} else {
			$candidate = '/dep/R/bin/i386/Rterm.exe';
		}
		if (-e $::config_obj->cwd.$candidate){
			$::config_obj->r_path( $::config_obj->cwd.$candidate)
		}
	}
	my $dir = $::config_obj->cwd."/config/Rtmp";
	$dir =~ s/\//\\/g;
	$dir = $::config_obj->os_path($dir);
	mkdir($dir) unless -d $dir;
	$ENV{TMPDIR} = $dir;

	if (
		not -e $::config_obj->r_path
		and -e $::config_obj->cwd.'/dep/R/bin/Rterm.exe'
	){
		$::config_obj->r_path($::config_obj->cwd.'/dep/R/bin/Rterm.exe');
	}
	if (
		not -e $::config_obj->r_path
		and -e $::config_obj->cwd.'/dep/R/bin/i386/Rterm.exe'
	){
		$::config_obj->r_path($::config_obj->cwd.'/dep/R/bin/i386/Rterm.exe');
	}

	# environment variables
	$ENV{R_HOME}         = $::config_obj->cwd.'/dep/R';
	$ENV{R_LIBS}         = $::config_obj->cwd.'/dep/R/library';
	# environment variables: dummy
	$ENV{R_USER}         = $::config_obj->cwd.'/config/Rtmp';
	$ENV{R_LIBS_USER}    = $::config_obj->cwd.'/config/Rtmp';
	$ENV{R_PROFILE_USER} = 'DO_NOT_LOAD_FROM_USER_DIR';
	$ENV{R_ENVIRON_USER} = 'DO_NOT_LOAD_FROM_USER_DIR';

	# MySQL設定ファイル修正（khc.ini）
	my $p1 = $::config_obj->cwd.'/dep/mysql/';
	my $p2 = $::config_obj->private_dir.'/mysql_data/';
	my $p3 = $p1; chop $p3;

	my $p4 = $p1.'tmp/';
	unless (-e $p4){
		mkdir($p4) or
			gui_errormsg->open(
				type    => 'file',
				thefile => "$p4"
			)
		;
	}
	my $p5 = $::config_obj->cwd.'/screen/';

	open (MYINI,$::config_obj->cwd.'/dep/mysql/khc.ini') or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "<khc.ini"
		);
	open (MYININ,'>'.$::config_obj->cwd.'/dep/mysql/khc.ini.new') or 
		gui_errormsg->open(
			type    => 'file',
			thefile => ">khc.ini.new"
		);
	while(<MYINI>){
		chomp;
		if ($_ =~ /^basedir = (.+)$/){
			print MYININ "basedir = $p1\n";
		}
		elsif ($_ =~ /^datadir = (.+)$/){
			print MYININ "datadir = $p2\n";
		}
		elsif ($_ =~ /^tmpdir = (.+)$/){
			print MYININ "tmpdir = $p4\n";
		}
		elsif ($_ =~ /^secure\-file\-priv = (.+)$/){
			print MYININ "secure-file-priv = $p5\n";
		}
		
		elsif ($_ =~ /max_heap_table_size/i){
			print MYININ
				"max_heap_table_size = "
				.$mHash{AvailPhys}
				."M\n"
			;
		} else {
			print MYININ "$_\n";
		}
	}
	close (MYINI);
	close (MYININ);
	
	
	unlink($::config_obj->cwd.'\dep\mysql\khc.ini') or
		gui_errormsg->open(
			type    => 'file',
			thefile => ">khc.ini"
		);
	
	# Wainting for the unlink to take effect (max 3 sec: 0.05 * 60)
	use Time::HiRes;
	my $n_w = 0;
	while (-e $::config_obj->cwd.'\dep\mysql\khc.ini') {
		++$n_w;
		print "Wainting for unlink (dep/mysql/khc.ini) $n_w...\n";
		Time::HiRes::sleep (0.05);
		if ($n_w > 60){
			warn("Could not configure MySQL (khc.ini) ...\n");
			last;
		}
	}

	if ($n_w <= 60 ){
		rename(
			$::config_obj->cwd.'\dep\mysql\khc.ini.new',
			$::config_obj->cwd.'\dep\mysql\khc.ini'
		) or gui_errormsg->open(
				type    => 'file',
				thefile => "khc.ini.new -> khc.ini"
		);
	}

	# MySQLの起動
	unless ( mysql_exec->connection_test ) {
		print "Starting MySQL...\n";
		require Win32;
		require Win32::Process;
		my $obj;
		my ($mysql_pass, $cmd_line);
		
		$mysql_pass = $::config_obj->cwd.'\dep\mysql\bin\mysqld.exe';
		$cmd_line = 'bin\mysqld --defaults-file=khc.ini --standalone';
	
		Win32::Process::Create(
			$obj,
			$mysql_pass,
			$cmd_line,
			0,
			undef,#Win32::Process->CREATE_NO_WINDOW,
			$p3,
		) or gui_errormsg->open(
			type => 'mysql',
			sql  => 'Start'
		);
	}
	
	$::config_obj->save;
	return 1;
}

sub mysql_stop{
	mysql_exec->shutdown_db_server;
	#system 'c:\apps\mysql\bin\mysqladmin --port=3307 --user=root --password=khcallinone shutdown';
}

1;