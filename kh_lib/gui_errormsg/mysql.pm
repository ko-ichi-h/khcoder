package gui_errormsg::mysql;
use strict;
use base qw(gui_errormsg);

sub get_msg{
	my $self = shift;
	my $msg = kh_msg->get('fatal');
	
	if ($self->sql){
		$msg .= "\n\n";
		$msg .= gui_window->gui_jchar($self->sql);
	}
	
	return $msg;
}

sub sql{
	my $self = shift;
	return $self->{sql};
}
1;