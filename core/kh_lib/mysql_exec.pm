package mysql_exec;
use DBI;
use strict;

use kh_project;

# Usage:
# 	mysql_exec->[do/select]("sql","[1/0]")
# 		sql: SQL文
#		[1/0]: Critical(1) or not(0)

sub do{
	my $class = shift;
	my $self;
	$self->{sql} = shift;
	$self->{critical} = shift;
	bless $self, $class;
	
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
	
	my $t = $::project_obj->dbh->prepare($self->sql);
	$t->execute or $self->print_error;
	$self->{hundle} = $t;
	return $self;
}

sub print_error{
	my $self = shift;
	$self->{err} = "SQL入力:\n".$self->sql."\nエラー出力:\n"."$DBD::mysql::errstr";
	unless ($self->critical){
		return 0;
	}
	gui_errormsg->open(type => 'mysql',sql => $self->err);
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
