package kh_all_in_one;
use strict;

#-------------------------------#
#   All In One 版の起動・終了   #
#-------------------------------#

# All In One版では
# (1)「config\coder.ini」に下記の設定を加える
#	all_in_one_pack	1
#	sql_username	khc
#	sql_password	khc
#	sql_host	localhost
#	sql_port	3307
# (2) 同梱するMySQLの設定
#	ユーザー設定: khc[khc], root[khcallinone]
#	「khc.ini」も添付する


# 「khc.ini」は必要な部分だけを修正するように…
# Win9xに対応？

sub init{
	# 茶筌のパス設定
	$::config_obj->chasen_path($::config_obj->cwd.'\dep\chasen\chasen.exe')
		unless -e $::config_obj->chasen_path;
	
	# MySQL設定ファイル作成（khc.ini）
	my $p1 = $::config_obj->cwd.'\dep\mysql\\';
	my $p2 = $::config_obj->cwd.'\dep\mysql\data\\';
	my $p3 = $p1; chop $p3;
	my $mysql_pass = $::config_obj->cwd.'\dep\mysql\bin\mysqld-nt.exe';
	$p1 =~ s/\\/\//g;
	$p2 =~ s/\\/\//g;
	my $inid;
	$inid .= "[client]\n";
	$inid .= "port=3307\n";
	$inid .= "[mysqld]\n";
	$inid .= "port=3307\n";
	$inid .= "skip-locking\n";
	$inid .= "set-variable	= key_buffer=16M\n";
	$inid .= "set-variable	= max_allowed_packet=1M\n";
	$inid .= "set-variable	= table_cache=64\n";
	$inid .= "set-variable	= sort_buffer=512K\n";
	$inid .= "set-variable	= net_buffer_length=8K\n";
	$inid .= "set-variable	= myisam_sort_buffer_size=8M\n";
	$inid .= "server-id	= 1\n";
	$inid .= "basedir = $p1\n";
	$inid .= "datadir = $p2\n";
	$inid .= "default-character-set=ujis\n";
	$inid .= "[mysqldump]\n";
	$inid .= "quick\n";
	$inid .= "set-variable	= max_allowed_packet=16M\n";
	$inid .= "[mysql]\n";
	$inid .= "no-auto-rehash\n";
	$inid .= "[isamchk]\n";
	$inid .= "set-variable	= key_buffer=20M\n";
	$inid .= "set-variable	= sort_buffer=20M\n";
	$inid .= "set-variable	= read_buffer=2M\n";
	$inid .= "set-variable	= write_buffer=2M\n";
	$inid .= "[myisamchk]\n";
	$inid .= "set-variable	= key_buffer=20M\n";
	$inid .= "set-variable	= sort_buffer=20M\n";
	$inid .= "set-variable	= read_buffer=2M\n";
	$inid .= "set-variable	= write_buffer=2M\n";
	$inid .= "[mysqlhotcopy]\n";
	$inid .= "interactive-timeout\n";
	open (MYINI,'>'.$::config_obj->cwd.'\dep\mysql\khc.ini') or 
		gui_errormsg->open(
			type    => 'file',
			thefile => ">khc.ini"
		);
	print MYINI "$inid";
	close (MYINI);

	# MySQLの起動
	print "starting mysql...\n";
	use Win32;
	use Win32::Process;
	my $obj;
	print "$mysql_pass\n";
	print "$p3\n";
	Win32::Process::Create(
		$obj,
		$mysql_pass,
		'bin\mysqld-nt --defaults-file=khc.ini',
		0,
		'CREATE_NO_WINDOW',
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