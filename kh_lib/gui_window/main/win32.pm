package gui_window::main::win32;
use base qw(gui_window::main);
use strict;
use Win32;

sub make_font{
	my $self = shift;
	$self->mw->fontCreate('TKFN',
		-family => 'MS UI Gothic',
		-size => '10',
	);
	$self->mw->optionAdd('*font',"TKFN");
}


1;