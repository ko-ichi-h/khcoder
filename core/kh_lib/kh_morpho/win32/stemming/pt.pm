package kh_morpho::win32::stemming::pt;
use strict;
use base qw( kh_morpho::win32::stemming );

sub init{
	my $self = shift;
	
	$self->{icode} = kh_jchar->check_code($self->target,1);
	
	$self->{splitter} = Lingua::Sentence->new('pt');
	$self->{stemmer}  = Lingua::Stem::Snowball->new(
		lang     => 'pt',
		encoding => 'UTF-8'
	);
	
	return $self;
}

sub stemming{
	my $self = shift;
	my $words_hyoso = shift;
		
	my $words_stem = [$self->{stemmer}->stem($words_hyoso)];
	
	# Stemming結果の前後に記号がついている場合は落とす
	foreach my $i (@{$words_stem}){
		if ($i =~ /^(\w+)\W+$/o){
			$i = $1;
		}
		elsif ($i =~ /^\W+(\w+)$/o){
			$i = $1;
		}
		#elsif ($i =~ /\w\W/o || $i =~ /\W\w/o){
		#	print "$i,";
		#}
	}
	return $words_stem;
}

sub tokenize{
	my $self = shift;
	my $t    = shift;

	# 文末処理
	$t =~ s/(.+)(["|''|']{0,1}[\.|\!+|\?+|\!+\?|\?+\!+]["|''|']{0,1})\s*$/\1 \2/go;

	# コンマ
	$t =~ s/(\S),([\s|\Z])/\1 ,\2/go;

	# ダブルクォートやカッコ類
	$t =~ s/(''|``|"|\(|\)|\[|\]|\{|\})(\S)/\1 \2/go;
	$t =~ s/(\S)(''|``|"|\(|\)|\[|\]|\{|\})/\1 \2/go;

	# シングルクォート
	$t =~ s/(\S)'([\s|\Z])/\1 '\2/go;
	$t =~ s/(\s|^)'(\S)/\1' \2/go;

	my @words_hyoso = split / /, $t;

	return(\@words_hyoso, undef);
}


1;
