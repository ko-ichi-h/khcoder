package kh_nbayes::cv_train;
use base qw(kh_nbayes);

use strict;

sub each{
	my $self = shift;
	my $current = shift;
	my $last    = shift;
	if (
		    $self->{member_group}{$last}
		and $self->{cross_vl_c} != $self->{member_group}{$last}
	){
		$self->{cls}->add_instance(
			attributes => $current,
			label      => $self->{outvar_cnt}{$last},
		);
	}
	return $self;
}

1;