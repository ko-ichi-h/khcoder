package kh_morpho::win32::stemming::en;
use strict;
use base qw( kh_morpho::win32::stemming );



sub init{
	my $self = shift;
	
	# Perlapp用にLingua::En::Taggerのデータを解凍
	require Lingua::EN::Tagger;
	unless (-e $Lingua::EN::Tagger::word_path){
		my $cwd = $::config_obj->cwd;
		$cwd = Jcode->new($cwd,'sjis')->euc;
		$cwd =~ tr/\\/\//;
		$cwd = Jcode->new($cwd,'euc')->sjis.'/';
		
		$Lingua::EN::Tagger::word_path
			= $cwd
			.PerlApp::extract_bound_file('Lingua/EN/Tagger/pos_words.hash');
		$Lingua::EN::Tagger::word_path =~ tr/config\\/config\//;
		$Lingua::EN::Tagger::tag_path
			= $cwd
			.PerlApp::extract_bound_file('Lingua/EN/Tagger/pos_tags.hash');
		$Lingua::EN::Tagger::tag_path =~ tr/config\\/config\//;
		$Lingua::EN::Tagger::lexpath
			= substr(
				$Lingua::EN::Tagger::word_path,
				0,
				length($Lingua::EN::Tagger::word_path) - 15
			);
		$Lingua::EN::Tagger::lexpath =~ tr/config\\/config\//;
		
		PerlApp::extract_bound_file('Lingua/EN/Tagger/tags.yml');
		PerlApp::extract_bound_file('Lingua/EN/Tagger/unknown.yml');
		PerlApp::extract_bound_file('Lingua/EN/Tagger/words.yml');
	}
	$self->{tagger} = new Lingua::EN::Tagger;
	
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
	
	$t =~ s/[Cc]annot/can not/go;
	my $t = $self->{tagger}->add_tags($t);
	
	my @words_raw = split / /, $t;

	my @words_hyoso;
	my @words_pos;

	foreach my $i (@words_raw){
		if ($i =~ /^<(.+)>(.+)<\/\1>$/o){
			push @words_pos,   $1;
			push @words_hyoso, $2;
		} else {
			warn("error in tagger? $i\n");
		}
	}
	
	return(\@words_hyoso, \@words_pos);
}


1;
