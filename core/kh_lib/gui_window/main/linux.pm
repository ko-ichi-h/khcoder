package gui_window::main::linux;
use base qw(gui_window::main);
use strict;

sub make_font{
	my $self = shift;

	if ($Tk::VERSION >= 804){
		$self->mw->fontCreate('TKFN',
			-family => 'goth_p',
			-size   => 10
		);
		$self->mw->optionAdd('*font', 'goth_p 10')
	} else {
		$self->mw->fontCreate('TKFN',
			-compound => [
				['ricoh-gothic','-12'],
				'-ricoh-gothic--medium-r-normal--12-*-*-*-c-*-jisx0208.1983-0'
			]
		);
	}
}

1;

