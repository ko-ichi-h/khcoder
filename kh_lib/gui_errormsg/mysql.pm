package gui_errormsg::mysql;
use strict;
use base qw(gui_errormsg);

sub get_msg{
	my $self = shift;
	my $msg = "MySQLデータベースの処理に失敗しました。\n";
	$msg .= "KH Coderを終了します。\n";
	
	if ($self->sql){
		$msg .= "\n";
		$msg .= $self->sql;
	}
	Jcode::convert(\$msg,'sjis');
	
	return $msg;
}

sub sql{
	my $self = shift;
	return $self->{sql};
}
1;