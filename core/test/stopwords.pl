use strict;

use Lingua::StopWords qw( getStopWords );
my $stopwords = getStopWords('fr');
my @stops = (keys %{$stopwords});

use Lingua::Stem::Snowball;
my $stemmer = Lingua::Stem::Snowball->new(lang => 'fr');
my @stm = $stemmer->stem(\@stops);

use Text::Unidecode;
foreach my $i (@stm){
	print unidecode($i),"\n";
}

