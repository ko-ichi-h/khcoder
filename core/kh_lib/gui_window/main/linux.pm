package gui_window::main::linux;
use base qw(gui_window::main);
use strict;

sub make_font{
	my $self = shift;
	$self->mw->fontCreate('TKFN',
		-compound => [
			['ricoh-gothic','-12'],
			'-ricoh-gothic--medium-r-normal--12-*-*-*-c-*-jisx0208.1983-0'
		]
	);
}

1;

