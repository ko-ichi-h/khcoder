package gui_errormsg::print::cmdline;
use strict;
use base qw(gui_errormsg::print);

sub print{
	my $self = shift;
	print $self->{msg};
	print "\n";
}

1;
