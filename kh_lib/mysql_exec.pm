package mysql_exec;
use DBI;
use strict;
use Time::Local;
use kh_project;

# 備考: MySQLとのやりとりはすべて、このクラスを通して行う

# 使い方:
# 	mysql_exec->[do/select]("sql","[1/0]")
# 		sql: SQL文
#		[1/0]: Critical(1) or not(0)

my ($username, $password, $host, $port);
if ($::config_obj){
	$username = $::config_obj->sql_username;
	$password = $::config_obj->sql_password;
	$host     = $::config_obj->sql_host;
	$port     = $::config_obj->sql_port;
}

my $mysql_version = -1;
my $win_9x = 0;

my $dbh_common;

#------------#
#   DB操作   #
#------------#

sub connect_common{
	my $dsn = 
		"DBI:mysql:database=mysql;$host;port=$port;mysql_local_infile=1";
	$dbh_common = DBI->connect($dsn,$username,$password)
		or gui_errormsg->open(type => 'mysql', sql => 'Connect');
	#print "Created a shared connection to MySQL.\n";
}

# 既存DBにConnect
sub connect_db{
	my $dbname     = $_[1];
	my $no_verbose = $_[2];
	my $dsn = 
		"DBI:mysql:database=$dbname;$host;port=$port;mysql_local_infile=1";
	my $dbh = DBI->connect($dsn,$username,$password,{mysql_enable_utf8 => 1})
		or gui_errormsg->open(type => 'mysql', sql => 'Connect');

	# MySQLのバージョンチェック
	my $t = $dbh->prepare("show variables like \"version\"");
	$t->execute;
	my $r = $t->fetch;
	$r = $r->[1] if $r;
	if ($r =~ /^(.+)\-[a-z]+$/){
		$r = $1;
	}
	if ($r =~ /^([0-9]+\.[0-9]+)\.[0-9]+/){
		$r = $1;
	}
	$mysql_version = $r;
	print "Connected to MySQL $r, $dbname.\n" unless $no_verbose;

	# OSのバージョンチェック
	if ($::config_obj->os eq 'win32'){
		$win_9x = 1 unless Win32::IsWinNT();
	}

	# 文字コードの設定
	#if ( substr($r,0,3) > 4 ){
	#	$dbh->do("SET NAMES ujis");
	#	print "Performed \"SET NAMES ujis\"\n" unless $no_verbose;
	#}
	$dbh->do("SET NAMES utf8mb4");

	return $dbh;
}

# DBへの接続テスト
sub connection_test{
	# コンソールへのエラー出力抑制
	my $temp_file = 'config/temp.txt';
	my $n = 0;
	while (-e $temp_file){
		$temp_file .= "config/temp$n.txt";
		++$n;
	}
	open (STDERR,">$temp_file");
	
	# テスト実行
	print "Checking MySQL connection...\n";
	my $if_error = 0;
	my $dsn = 
		"DBI:mysql:database=mysql;$host;port=$port;mysql_local_infile=1";
	my $dbh = DBI->connect($dsn,$username,$password)
		or $if_error = 1;
	unless ($if_error){
		my @r = $dbh->func('_ListDBs') or $if_error = 1;
		if (@r){
			$dbh->disconnect;
		} else {
			$if_error = 1;
		}
	}

	# エラー出力抑制の解除
	close (STDERR);
	open(STDERR,'>&STDOUT') or die;
	unlink($temp_file);
	
	if ($if_error){
		return 0;
	} else {
		return 1;
	}
}

# 新規DBの作成
sub create_new_db{
	my $class = shift;
	my $file = shift;
	
	# Get DB List
	my $drh = DBI->install_driver("mysql") or
		gui_errormsg->open(type => 'mysql',sql=>'install_driver');
	my @dbs = $drh->func($host,$port,$username,$password,'_ListDBs') or 
		gui_errormsg->open(type => 'mysql', sql => 'List DBs');
	my %dbs;
	foreach my $i (@dbs){
		$dbs{$i} = 1;
	}
	
	# Prepare master DB (this happens only once)
	unless ($dbs{khc_master}){
		# create DB
		my $dsn = 
			"DBI:mysql:database=mysql;$host;port=$port;mysql_local_infile=1";
		my $dbh = DBI->connect($dsn,$username,$password)
			or gui_errormsg->open(type => 'mysql', sql => 'Connect');
		$dbh->do("
			create database khc_master default character set utf8mb4
		");
		$dbh->disconnect;
		
		# create table
		$dsn = 
			"DBI:mysql:database=khc_master;$host;port=$port;mysql_local_infile=1";
		$dbh = DBI->connect($dsn,$username,$password)
			or gui_errormsg->open(type => 'mysql', sql => 'Connect');
		$dbh->do("
			create table db_name(
				id     int auto_increment primary key not null,
				target varchar(10000)
			)
		");
		
		# insert dummy data
		my $max = 0;
		foreach my $i (@dbs){
			if ( $i =~ /khc([0-9]+)/ ) {
				if ($1 > $max) {
					$max = $1;
				}
			}
		}
		for (my $i = 0; $i <= $max; ++$i){
			$dbh->do("
				insert into db_name (target) VALUES (\"dummy$i\")
			");
		}
		$dbh->disconnect;
	}
	
	# Get new DB number
	my $dsn = 
		"DBI:mysql:database=khc_master;$host;port=$port;mysql_local_infile=1";
	my $dbh = DBI->connect($dsn,$username,$password)
		or gui_errormsg->open(type => 'mysql', sql => 'Connect');
	$dbh->do('SET NAMES utf8mb4');
	$file = $::config_obj->uni_path($file);
	$file = $dbh->quote($file);
	$dbh->do("
		insert into db_name (target) VALUES ($file)
	");
	my $h = $dbh->prepare("select LAST_INSERT_ID()");
	$h->execute;
	my $n = $h->fetch or die("Failed to obtain new DB name!");
	$h->finish;
	$n = $n->[0];

	# Create new DB
	my $new_db_name = "khc$n";
	$dbh->do("
		create database $new_db_name default character set utf8mb4
	") or die("Failed to create new DB!");

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
		or gui_errormsg->open(
			type => 'msg',
			msg => 'Could not delete the database from MySQL'
		);

	$dbh->disconnect;
}

# DB Serverのシャットダウン

sub shutdown_db_server{

	if ($::config_obj->os eq 'win32' && $^V ne 'v5.14.2'){
		print "Shutting down MySQL using mysqladmin.exe...\n";
		
		require Win32::Process;
		my $obj;
		my ($mysql_pass, $cmd_line);
		
		$mysql_pass = $::config_obj->cwd.'\dep\mysql\bin\mysqladmin.exe';
		$cmd_line = "dep\\mysql\\bin\\mysqladmin --user=$username --password=$password --port=$port shutdown";

		Win32::Process::Create(
			$obj,
			$mysql_pass,
			$cmd_line,
			0,
			Win32::Process->CREATE_NO_WINDOW,
			$::config_obj->cwd,
		);
	} else {
		my $dbh;
		if ($dbh_common) {
			$dbh = $dbh_common;
		} else {
			my $dsn = 
				"DBI:mysql:database=mysql;$host;port=$port;mysql_local_infile=1";
			$dbh = DBI->connect($dsn,$username,$password);
		}
		$dbh->func("shutdown",$host,$username,$password,'admin') if $dbh;
	}
	# このルーチンは終了処理で呼ばれる（はず）なので、例外ハンドリングを
	# 省いて終了させる。
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
	
	my $t = $::project_obj->dbh->prepare("SELECT * FROM $table LIMIT 1")
		or return 0;
	$t->{PrintError} = 0; # テーブルが存在しなかった場合のエラー出力を抑制
	$t->execute or return 0;
	$t->finish;
	
	return 1;
}

#sub table_exists{
#	my $class = shift;
#	my $table = shift;
#	my $r = 0;
#	foreach my $i ( &table_list ){
#		if ($i eq $table){
#			$r = 1;
#			last;
#		}
#	}
#	return $r;
#}

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

sub flush{
	my $class = shift;
	
	my $dbh;
	if ($::project_obj) {
		$dbh = $::project_obj->dbh;
	} else {
		&connect_common unless $dbh_common;
		$dbh = $dbh_common;
	}
	
	$dbh->do("FLUSH TABLES") or die("FLUSH TABLES");
	$dbh->do("FLUSH LOGS")   or die("FLUSH LOGS");
	print "MySQL: FLUSH\n";
	
	return 1;
}

sub do{
	my $class = shift;
	my $self;
	$self->{sql} = shift;
	$self->{critical} = shift;
	bless $self, $class;

	$self->{sql} =~ s/TYPE\s*=\s*HEAP/ENGINE = HEAP/ig
		if $mysql_version >= 5.5;
	$self->{sql} =~ s/LOAD DATA LOCAL INFILE/LOAD DATA INFILE/
		if $win_9x; # for Win9x
	
	$self->log;

	my $dbh;
	if ($::project_obj) {
		$dbh = $::project_obj->dbh;
	} else {
		&connect_common unless $dbh_common;
		$dbh = $dbh_common;
	}

	$dbh->do($self->sql)
		or $self->print_error;
	return $self;
}

sub select{
	my $class = shift;
	my $self;
	$self->{sql} = shift;
	$self->{critical} = shift;
	bless $self, $class;
	
	($self->{caller_pac}, $self->{caller_file}, $self->{caller_line}) = caller;
	
	$self->{sql} =~ s/TYPE\s*=\s*HEAP/ENGINE = HEAP/ig
		if $mysql_version >= 5.5;
	$self->{sql} =~ s/LOAD DATA LOCAL INFILE/LOAD DATA INFILE/
		if $win_9x; # for Win9x

	$self->log;

	my $dbh;
	if ($::project_obj) {
		$dbh = $::project_obj->dbh;
	} else {
		&connect_common unless $dbh_common;
		$dbh = $dbh_common;
	}

	my $t = $dbh->prepare($self->sql) or $self->print_error;
	$t->execute or $self->print_error;
	$self->{hundle} = $t;
	return $self;
}

sub selected_rows{
	my $self = shift;
	return $self->{hundle}->rows;
}

sub print_error{
	my $self = shift;
	
	if ($::project_obj) {
		$self->{err} =
			"SQL Input:\n".$self->sql."\nError:\n"
			.$::project_obj->dbh->{'mysql_error'}."\n\n"
			."SQL Caller: $self->{caller_file} line $self->{caller_line}"
		;
	}
	elsif ( $dbh_common ){
		$self->{err} =
			"SQL Input:\n".$self->sql."\nError:\n"
			.$dbh_common->{'mysql_error'}."\n\n"
			."SQL Caller: $self->{caller_file} line $self->{caller_line}"
		;
	}
	
	unless ($self->critical){
		warn($self->{err});
		return 0;
	}
	gui_errormsg->open(type => 'mysql',sql => $self->err);
}

sub quote{
	my $class = shift;
	my $input = shift;

	return $::project_obj->dbh->quote($input);
}

sub version_number{
	my $t = $::project_obj->dbh->prepare("show variables like \"version\"");
	$t->execute;
	my $r = $t->fetch;
	$r = $r->[1] if $r;
	if ($r =~ /^([0-9]+\.[0-9]+)\./){
		$r = $1;
	}
	return $r;
}

#-------------------------------#
#   ログファイルにSQL文を記録   #
sub log{
	return 1 unless $::config_obj->sqllog;
	
	use POSIX 'strftime';
	my $self = shift;
	my $logfile = $::config_obj->sqllog_file;
	open (LOG,">>:utf8", $logfile) or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "$logfile"
		);
	my $d = strftime('%Y %m/%d %H:%M:%S',localtime);
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
