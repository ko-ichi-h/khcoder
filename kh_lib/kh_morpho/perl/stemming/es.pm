package kh_morpho::perl::stemming::es;
use strict;
use base qw( kh_morpho::perl::stemming );

sub init{
	my $self = shift;
	
	$self->{icode} = kh_jchar->check_code($self->target,1);
	
	$self->{splitter} = Lingua::Sentence->new('es');
	$self->{stemmer}  = Lingua::Stem::Snowball->new(
		lang     => 'es',
		encoding => 'UTF-8'
	);
	
	return $self;
}

sub tokenize{
	my $self = shift;
	my $t    = shift;

	# 文末処理
	$t =~ s/(.+)(["|''|']{0,1}[\.|\!+|\?+|\!+\?|\?+\!+]["|''|']{0,1})\s*$/$1 $2/go;

	# コンマ
	$t =~ s/(\S),(\s|\Z)/$1 ,$2/go;

	# ダブルクォートやカッコ類
	$t =~ s/(''|``|"|\(|\)|\[|\]|\{|\})(\S)/$1 $2/go;
	$t =~ s/(\S)(''|``|"|\(|\)|\[|\]|\{|\})/$1 $2/go;

	# シングルクォート
	$t =~ s/(\S)'(\s|\Z)/$1 '$2/go;
	$t =~ s/(\s|^)'(\S)/$1' $2/go;

	my @words_hyoso = split / /, $t;

	return(\@words_hyoso, undef);
}


1;
