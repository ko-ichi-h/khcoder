package gui_hlist::linux;
use base qw(gui_hlist);
use strict;

sub _copy{
	gui_errormsg->open(
		msg => 'Sorry, currently cannot copy on Unix systems.',
		type => 'msg',
	);
}

sub _copy_all{
	gui_errormsg->open(
		msg => 'Sorry, currently cannot copy on Unix systems.',
		type => 'msg',
	);
}

1;