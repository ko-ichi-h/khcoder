package gui_airborne::linux;
use base qw(gui_airborne);
use strict;

sub _make{
	my $self = shift;
	$self->{frame} = $self->tower;
}

sub make_control{}
1;