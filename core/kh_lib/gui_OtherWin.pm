package gui_OtherWin;
use strict;

use gui_OtherWin::win32;
use gui_OtherWin::linux;


sub open{
	my $class = shift;
	my $self;
	$self->{target} = shift;
	bless $self, "$class"."::".$::config_obj->os;
	$self->_open;
}

sub target{
	my $self = shift;
	return $self->{target};
}

1;
