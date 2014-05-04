package kh_all_in_mac;
use strict;

#-------------------------------#
#   All In One 版の起動・終了   #
#-------------------------------#

# All In One版では、
# (1)「config\coder.ini」に下記の設定を加える
#	all_in_one_pack	1
#	sql_username	root
#	sql_password	khc
#	sql_host	127.0.0.1
#	sql_port	3308
# (2) 同梱するMySQLの設定
#	ユーザー設定: root / khc
#	「khc.cnf」も添付する

sub init{
	print "Executing Mac OS X 64-bit Package\n";

	# Chasen's path
	unless ($::ENV{PATH} =~ /deps\/chasen:/){
		system "export PATH=".$::config_obj->cwd."/deps/chasen:\$PATH";
		$::ENV{PATH} = $::config_obj->cwd."/deps/chasen:".$::ENV{PATH};
	}

	# R's path
	unless ($::ENV{PATH} =~ /deps\/R\-3\.1\.0\/Resources\/bin:/){
		system "export PATH=".$::config_obj->cwd."/deps/R-3.1.0/Resources/bin:\$PATH";
		$::ENV{PATH} = $::config_obj->cwd."/deps/R-3.1.0/Resources/bin:".$::ENV{PATH};
	}

	# Start MySQL
	unless (-e '/tmp/mysql.sock.khc'){
		system "deps/MySQL-5.6.17/bin/mysqld --defaults-file=deps/MySQL-5.6.17/khc.cnf &"
	}

	return 1;
}

sub mysql_stop{
	mysql_exec->shutdown_db_server;
	#system 'c:\apps\mysql\bin\mysqladmin --port=3307 --user=root --password=khcallinone shutdown';
}

1;