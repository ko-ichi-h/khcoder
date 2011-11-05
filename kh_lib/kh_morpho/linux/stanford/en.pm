package kh_morpho::linux::stanford::en;
use base qw(kh_morpho::linux::stanford);
use strict;

sub init{
	my $self = shift;
	
	$self->{splitter} = Lingua::Sentence->new('en');

	return $self;
}



1;