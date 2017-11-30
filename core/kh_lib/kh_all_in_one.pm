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
	$mHash{AvailPhys} = 2046 if $mHash{AvailPhys} > 2046;
	print "Available Physical Memory: $mHash{AvailPhys}MB\n";

	# 茶筌のパス設定
	if (
		not -e $::config_obj->chasen_path
		and -e $::config_obj->cwd.'\dep\chasen\chasen.exe'
	) { 
		$::config_obj->chasen_path(
			$::config_obj->cwd.'\dep\chasen\chasen.exe'
		);
	}

	# Stanford POS Taggerのパス設定
	if (
		not -e $::config_obj->stanf_tagger_path
		and -e $::config_obj->cwd.'\dep\stanford-postagger\models\left3words-wsj-0-18.tagger'
	) {
		$::config_obj->stanf_tagger_path(
			$::config_obj->cwd.'\dep\stanford-postagger\models\left3words-wsj-0-18.tagger'
		);
	}
	if (
		not -e $::config_obj->stanf_jar_path
		and -e $::config_obj->cwd.'\dep\stanford-postagger\stanford-postagger.jar'
	) {
		$::config_obj->stanf_jar_path(
			$::config_obj->cwd.'\dep\stanford-postagger\stanford-postagger.jar'
		);
	}

	# Rのパス設定
	if (not -e $::config_obj->r_path){
		require Devel::Platform::Info::Win32;
		my $os_info = Devel::Platform::Info::Win32->new->get_info();
		#use Data::Dumper;
		#print Dumper $os_info;
		
		my $candidate = '';
		if ( ($os_info->{wow64} == 1) || ($os_info->{is64bit} == 1)){
			$candidate = '\dep\R\bin\x64\Rterm.exe';
		} else {
			$candidate = '\dep\R\bin\i386\Rterm.exe';
		}
		if (-e $::config_obj->cwd.$candidate){
			$::config_obj->r_path( $::config_obj->cwd.$candidate)
		}
	}

	if (
		not -e $::config_obj->r_path
		and -e $::config_obj->cwd.'\dep\R\bin\Rterm.exe'
	){
		$::config_obj->r_path($::config_obj->cwd.'\dep\R\bin\Rterm.exe');
	}
	if (
		not -e $::config_obj->r_path
		and -e $::config_obj->cwd.'\dep\R\bin\i386\Rterm.exe'
	){
		$::config_obj->r_path($::config_obj->cwd.'\dep\R\bin\i386\Rterm.exe');
	}
	$ENV{R_LIBS_USER} = 'DO_NOT_LOAD_FROM_USER_DIR';
	
	# MySQL設定ファイル修正（khc.ini）
	my $p1 = $::config_obj->cwd.'\dep\mysql\\';
	my $p2 = $::config_obj->cwd.'\dep\mysql\data\\';
	my $p3 = $p1; chop $p3;
	$p1 = Jcode->new($p1,'sjis')->euc;
	$p2 = Jcode->new($p2,'sjis')->euc;
	$p1 =~ s/\\/\//g;
	$p2 =~ s/\\/\//g;
	$p1 = Jcode->new($p1,'euc')->sjis;
	$p2 = Jcode->new($p2,'euc')->sjis;

	my $p4 = $p1.'tmp/';
	unless (-e $p4){
		mkdir($p4) or
			gui_errormsg->open(
				type    => 'file',
				thefile => "$p4"
			)
		;
	}

	open (MYINI,$::config_obj->cwd.'\dep\mysql\khc.ini') or 
		gui_errormsg->open(
			type    => 'file',
			thefile => ">khc.ini"
		);
	open (MYININ,'>'.$::config_obj->cwd.'\dep\mysql\khc.ini.new') or 
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
		elsif ($_ =~ /set\-variable(\s*)=(\s*)max_heap_table_size/i){
			print MYININ
				"set-variable	= max_heap_table_size="
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
	rename(
		$::config_obj->cwd.'\dep\mysql\khc.ini.new',
		$::config_obj->cwd.'\dep\mysql\khc.ini'
	) or gui_errormsg->open(
			type    => 'file',
			thefile => ">khc.ini.new"
	);

	# MySQLの起動
	return 1 if mysql_exec->connection_test;
	print "Starting MySQL...\n";
	require Win32;
	require Win32::Process;
	my $obj;
	my ($mysql_pass, $cmd_line);
	
	if ( Win32::IsWinNT() ){
		$mysql_pass = $::config_obj->cwd.'\dep\mysql\bin\mysqld-nt.exe';
		$cmd_line = 'bin\mysqld-nt --defaults-file=khc.ini';
	} else {
		$mysql_pass = $::config_obj->cwd.'\dep\mysql\bin\mysqld-opt.exe';
		$cmd_line = 'bin\mysqld-opt --defaults-file=khc.ini';
	}
	Win32::Process::Create(
		$obj,
		$mysql_pass,
		$cmd_line,
		0,
		Win32::Process->CREATE_NO_WINDOW,
		$p3,
	) or gui_errormsg->open(
		type => 'mysql',
		sql  => 'Start'
	);
	
	$::config_obj->save;
	return 1;
}

sub mysql_stop{
	mysql_exec->shutdown_db_server;
	#system 'c:\apps\mysql\bin\mysqladmin --port=3307 --user=root --password=khcallinone shutdown';
}

1;