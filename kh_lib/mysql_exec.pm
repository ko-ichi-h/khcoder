package mysql_exec;
use DBI;
use strict;
use Time::Local;
use Time::CTime;    # Time-modulesに同梱
use kh_project;

# 備考: MySQLとのやりとりはすべて、このクラスを通して行う

# 使い方:
# 	mysql_exec->[do/select]("sql","[1/0]")
# 		sql: SQL文
#		[1/0]: Critical(1) or not(0)

my $username = $::config_obj->sql_username;
my $password = $::config_obj->sql_password;
my $host     = $::config_obj->sql_host;
my $port     = $::config_obj->sql_port;

#------------#
#   DB操作   #
#------------#

# 既存DBにConnect
sub connect_db{
	my $dbname = $_[1];
	my $dsn = 
		"DBI:mysql:database=$dbname;$host;port=$port;mysql_local_infile=1";
	my $dbh = DBI->connect($dsn,$username,$password)
		or gui_errormsg->open(type => 'mysql', sql => 'Connect');
	return $dbh;
}

# DBへの接続テスト
sub connection_test{
	my $dsn = 
		"DBI:mysql:database=test;$host;port=$port;mysql_local_infile=1";
	my $dbh = DBI->connect($dsn,$username,$password)
		or return 0;
	my @r = $dbh->func('_ListDBs')
		or return 0;
	unless (@r){
		return 0;
	}
	$dbh->disconnect;
	return 1;
}

# 新規DBの作成
sub create_new_db{
	# DB名決定
	my $drh = DBI->install_driver("mysql") or
		gui_errormsg->open(type => 'mysql',sql=>'install_driver');
	my @dbs = $drh->func($host,$port,$username,$password,'_ListDBs') or 
		gui_errormsg->open(type => 'mysql', sql => 'List DBs');
	my %dbs;
	foreach my $i (@dbs){
		$dbs{$i} = 1;
		# print "$i\n";
	}
	my $n = 0;
	while ( $dbs{"khc$n"} ){
		++$n;
	}
	my $new_db_name = "khc$n";

	# DB作成
	my $dsn = 
		"DBI:mysql:database=mysql;$host;port=$port;mysql_local_infile=1";
	my $dbh = DBI->connect($dsn,$username,$password)
		or gui_errormsg->open(type => 'mysql', sql => 'Connect');

	$dbh->func("createdb", $new_db_name,$host,$username,$password,'admin')
		or gui_errormsg->open(type => 'mysql', sql => 'Create DB');
	$dbh->disconnect;
	
	return $new_db_name;
}

# DBのDrop
sub drop_db{
	my $drop = $_[1];

	my $dsn = 
		"DBI:mysql:database=mysql;$host;port=$port;mysql_local_infile=1";
	my $dbh = DBI->connect($dsn,$username,$password)
		or gui_errormsg->open(type => 'mysql', sql => 'Connect');

	$dbh->func("dropdb", $drop,$host,$username,$password,'admin')
		or gui_errormsg->open(type => 'mysql', sql => 'Drop DB');

	$dbh->disconnect;
}

# DB Serverのシャットダウン

sub shutdown_db_server{
	my $dsn = 
		"DBI:mysql:database=mysql;$host;port=$port;mysql_local_infile=1";
	my $dbh = DBI->connect($dsn,$username,$password);
		#or gui_errormsg->open(type => 'mysql', sql => 'Connect');

	$dbh->func("shutdown",$host,$username,$password,'admin') if $dbh;
		#or gui_errormsg->open(type => 'mysql', sql => 'Drop DB');
		# このルーチンは終了処理で呼ばれる（はず）なので、例外ハンドリングを
		# 省いて終了させる…。
}

#------------------#
#   テーブル操作   #
#------------------#

sub drop_table{
	my $class = shift;
	my $table = shift;
	
	$::project_obj->dbh->do("DROP TABLE IF EXISTS $table");
}

sub table_exists{
	my $class = shift;
	my $table = shift;
	my $r = 0;
	foreach my $i ( &table_list ){
		if ($i eq $table){
			$r = 1;
			last;
		}
	}
	return $r;
}

sub clear_tmp_tables{
	my $class = shift;
	foreach my $i ( &table_list ){
		if ( index($i,'ct_') == 0){
			$::project_obj->dbh->do("drop table $i");
		}
	}
}

sub table_list{
	my $class = shift;
	my @r = map { $_ =~ s/.*\.//; $_ } $::project_obj->dbh->tables();
	foreach my $i (@r){
		$i = $1 if $i =~ /`(.*)`/;
	}
	return @r;
}

#----------------#
#   DoとSelect   #
#----------------#

sub do{
	my $class = shift;
	my $self;
	$self->{sql} = shift;
	$self->{critical} = shift;
	bless $self, $class;

	$self->log;

	$::project_obj->dbh->do($self->sql)
		or $self->print_error;
	return $self;
}

sub select{
	my $class = shift;
	my $self;
	$self->{sql} = shift;
	$self->{critical} = shift;
	bless $self, $class;
	
	$self->log;
	
	my $t = $::project_obj->dbh->prepare($self->sql) or $self->print_error;
	$t->execute or $self->print_error;
	$self->{hundle} = $t;
	return $self;
}

sub print_error{
	my $self = shift;
	$self->{err} =
		"SQL入力:\n".$self->sql."\nエラー出力:\n".
		$::project_obj->dbh->{'mysql_error'};
	unless ($self->critical){
		return 0;
	}
	gui_errormsg->open(type => 'mysql',sql => $self->err);
}

#-------------------------------#
#   ログファイルにSQL文を記録   #
sub log{
	return 1 unless $::config_obj->sqllog;
	
	my $self = shift;
	my $logfile = $::config_obj->sqllog_file;
	open (LOG,">>$logfile") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "$logfile"
		);
	my $d = strftime("%Y %m/%d %T",localtime);
	print LOG "$d\n";
	print LOG $self->sql."\n\n";
	close LOG;
	return 1;
}
#--------------#
#   アクセサ   #
#--------------#
sub sql{
	my $self = shift;
	return $self->{sql};
}
sub critical{
	my $self = shift;
	return $self->{critical};
}
sub err{
	my $self = shift;
	return $self->{err};
}
sub hundle{
	my $self = shift;
	return $self->{hundle};
}
1;
