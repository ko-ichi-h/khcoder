package gui_errormsg::file;
use strict;
use base qw(gui_errormsg);

sub get_msg{
	my $self = shift;
	my $msg = kh_msg->get('could_not_open_the_file'); # ファイルを開けませんでした。\nKH Coderを終了します。\n*
	$msg .= gui_window->gui_jchar( $self->{thefile} );
	
	return $msg;
}

1;