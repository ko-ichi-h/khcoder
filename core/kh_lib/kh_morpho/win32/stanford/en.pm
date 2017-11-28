package kh_morpho::win32::stanford::en;
use base qw(kh_morpho::win32::stanford);
use strict;

sub init{
	my $self = shift;
	
	$self->{splitter} = Lingua::Sentence->new('en');

	return $self;
}



1;