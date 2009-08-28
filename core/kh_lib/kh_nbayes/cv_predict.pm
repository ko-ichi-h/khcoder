package kh_nbayes::cv_predict;
use base qw(kh_nbayes);

use strict;

sub each{
	my $self = shift;
	my $current = shift;
	my $last    = shift;
	
	unless ( $self->{cross_vl_c} == $self->{member_group}{$last} ){
		return 0;
	}
	
	my ($r, $r2) = $self->{cls}->predict(
		attributes => $current
	);
	
	my $cnt     = 0;
	my $max     = 0;
	my $max_lab = 0;
	foreach my $i (keys %{$r}){
		++$cnt if $r->{$i} >= 0.6;
		if ($max < $r->{$i}){
			$max = $r->{$i};
			$max_lab = $i;
		}
	}
	
	#if (
	#	   $cnt == 1
	#	&& $max >= 0.8
	#) {
	#	push @{$self->{test_result_raw}}, $max_lab;
	#	if ( $max_lab eq $self->{outvar_cnt}{$last} ){
	#		push @{$self->{test_result}}, 1;
	#		++$self->{test_count_hit};
	#	} else {
	#		push @{$self->{test_result}}, 0;
	#	}
	#} else {
	#	push @{$self->{test_result_raw}}, '.';
	#	push @{$self->{test_result}}, 0;
	#}
	
	push @{$self->{test_result_raw}}, $max_lab;
	if ( $max_lab eq $self->{outvar_cnt}{$last} ){
		push @{$self->{test_result}}, 1;
		++$self->{test_count_hit};
	} else {
		push @{$self->{test_result}}, 0;
	}
	
	++$self->{test_count};
	return $self;
}


1;