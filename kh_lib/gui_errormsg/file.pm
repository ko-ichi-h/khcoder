package gui_errormsg::file;
use strict;
use base qw(gui_errormsg);

sub get_msg{
	my $self = shift;
	my $msg = "ファイルを開けませんでした。\n";
	$msg .= "KH Coderを終了します。\n";
	$msg .= "＊ ";
	Jcode::convert(\$msg,'sjis');
	$msg .= $self->{thefile};
	
	return $msg;
}

1;