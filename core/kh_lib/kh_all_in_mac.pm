package kh_all_in_mac;
use strict;

#-------------------------------#
#   All In One 版の起動・終了   #
#-------------------------------#

sub init{
	print "Executing Mac OS X 64-bit Package\n";

	# Chasen's path
	unless ($::ENV{PATH} =~ /deps\/chasen:/){
		system "export PATH=".$::config_obj->cwd."/deps/chasen:\$PATH";
		$::ENV{PATH} = $::config_obj->cwd."/deps/chasen/bin:".$::ENV{PATH};
		
		system 'export DYLD_FALLBACK_LIBRARY_PATH='.$::config_obj->cwd.'/deps/chasen/lib:$DYLD_FALLBACK_LIBRARY_PATH';
		$::ENV{DYLD_FALLBACK_LIBRARY_PATH} = $::config_obj->cwd.'/deps/chasen/lib:'.$::ENV{DYLD_FALLBACK_LIBRARY_PATH};
	}

	# R's path
	unless ($::ENV{PATH} =~ /deps\/R\-3\.1\.0\/Resources\/bin:/){
		system "export PATH=".$::config_obj->cwd."/deps/R-3.1.0/Resources/bin:\$PATH";
		$::ENV{PATH} = $::config_obj->cwd."/deps/R-3.1.0/Resources/bin:".$::ENV{PATH};
	}
	$ENV{R_LIBS_USER} = 'DO_NOT_LOAD_FROM_USER_DIR';

	# Start MySQL
	unless (-e '/tmp/mysql.sock.khc3'){
		system "deps/MySQL-5.6.17/bin/mysqld --defaults-file=deps/MySQL-5.6.17/khc.cnf &"
	}

	# Start UIM
	my $gr1 = `ps aux | grep uim-helper`;
	unless ($gr1 =~ /uim\-helper\-server/){
		system '/Library/Frameworks/UIM.framework/Versions/Current/bin/uim-xim --engine=anthy &';
		system 'xterm -e echo ok';
	}


	return 1;
}

sub mysql_stop{
	mysql_exec->shutdown_db_server;
}

1;


__END__
