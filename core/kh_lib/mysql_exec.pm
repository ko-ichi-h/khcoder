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

my $username = '';
my $password = '';
my $host     = 'localhost';
my $port     = '';

#my $username = 'test';
#my $password = 'hoge';
#my $host     = '192.168.0.2';
#my $port     = '3306';

#------------#
#   DB操作   #
#------------#

# 既存DBにConnect
sub connect_db{
	my $dbname = $_[1];
	my $dsn = 
		"DBI:mysql:database=$dbname;$host;port=$port;mysql_local_infile=1";
	my $dbh = DBI->connect($dsn,$username,$password)
		or gui_errormsg->open(type => 'mysql', sql => 'connect');
	return $dbh;
}

# 新規DBの作成
sub create_new_db{
	# DB名決定
	my $drh = DBI->install_driver("mysql") or
		gui_errormsg->open(type => 'mysql',sql=>'install_driver');

	my %dbs;
	foreach my $i ($drh->func($host,$port,$username,$password,'_ListDBs')){
		$dbs{$i} = 1;
	}
	my $n = 0;
	while ( $dbs{"khc$n"} ){
		++$n;
	}
	my $new_db_name = "khc$n";

	# DB作成
	$drh->func('createdb', $new_db_name,$host,$username,$password,'admin')
		or gui_errormsg->open(type => 'mysql', sql => 'createdb');
	
	return $new_db_name;
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
	foreach my $i ( $::project_obj->dbh->tables() ){
		if ($i eq $table){
			$r = 1;
			last;
		}
	}
	return $r;
}

sub clear_tmp_tables{
	my $class = shift;
	foreach my $i ( $::project_obj->dbh->tables() ){
		if ( index($i,'ct_') == 0){
			$::project_obj->dbh->do("drop table $i");
		}
	}
}

sub table_list{
	my $class = shift;
	my @r = $::project_obj->dbh->tables();
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
