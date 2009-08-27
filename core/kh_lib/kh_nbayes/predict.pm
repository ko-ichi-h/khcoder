package kh_nbayes::predict;

use base qw(kh_nbayes);

use strict;


sub each{
	my $self = shift;
	my $current = shift;
	my $last    = shift;
	
	my $r = $self->{cls}->predict(
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
	#	push @{$self->{result}}, [$max_lab];
	#} else {
	#	push @{$self->{result}}, ['.'];
	#}

	push @{$self->{result}}, [$max_lab];

	return $self;
}



























1;