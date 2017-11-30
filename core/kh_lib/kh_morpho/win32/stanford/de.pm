package kh_morpho::win32::stanford::de;
use base qw(kh_morpho::win32::stanford);
use strict;

sub init{
	my $self = shift;
	
	$self->{splitter} = Lingua::Sentence->new('de');

	return $self;
}



1;