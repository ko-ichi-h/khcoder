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
	print "Available Physical Memory: $mHash{AvailPhys}MB\n";

	# 茶筌のパス設定
	$::config_obj->chasen_path($::config_obj->cwd.'\dep\chasen\chasen.exe')
		unless -e $::config_obj->chasen_path;
	
	# Rのパス設定
	$::config_obj->r_path($::config_obj->cwd.'\dep\R\bin\Rterm.exe')
		unless -e $::config_obj->r_path;
	
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
	return 1;
}

sub mysql_stop{
	mysql_exec->shutdown_db_server;
	#system 'c:\apps\mysql\bin\mysqladmin --port=3307 --user=root --password=khcallinone shutdown';
}

1;