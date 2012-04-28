package gui_window::doc_search::linux;
use base qw(gui_window::doc_search);

use strict;
use gui_errormsg;

sub _copy{
	my $self = shift;
	my $win = $self->win_obj;

	gui_errormsg->open(
		msg => 'Sorry, currently cannot copy on Unix systems.',
		type => 'msg',
		window => \$win,
	);
	return 0;
}

1;