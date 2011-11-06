package kh_morpho::perl::stemming::en;
use strict;
use base qw( kh_morpho::perl::stemming );

sub init{
	my $self = shift;
	
	require ptb_tokenizer_en;
	
	$self->{splitter} = Lingua::Sentence->new('en');
	$self->{stemmer}  = Lingua::Stem::Snowball->new(
		lang     => 'en',
		encoding => 'UTF-8'
	);
	
	return $self;
}

sub tokenize{
	my $self = shift;
	my $t    = shift;
	
	my @words_hyoso = split / /, ptb_tokenizer_en::Run($t);
	
	return(\@words_hyoso, undef);
}


1;
