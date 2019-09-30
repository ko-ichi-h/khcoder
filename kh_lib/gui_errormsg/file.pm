package gui_errormsg::file;
use strict;
use base qw(gui_errormsg);

sub get_msg{
	my $self = shift;
	my $msg;
	
	eval { $msg = kh_msg->get('could_not_open_the_file'); }; # ファイルを開けませんでした。\nKH Coderを終了します。\n*
	$msg = "Could not open the file. KH Coder will quit now.\n" unless $msg;
	print "catched: $@\n";
	
	$@ = '';
	eval { $msg .= gui_window->gui_jchar( $self->{thefile} ); };
	print "catched: $@\n";
	if ($@) {
		$msg .= $self->{thefile};
	}
	
	
	return $msg;
}

1;