use strict;
use Lingua::StopWords qw( getStopWords );
use Lingua::Stem::En;
use Lingua::EN::Tagger;

my $stopwords = getStopWords('en');
my $tagger = new Lingua::EN::Tagger;
my %r = ();

foreach my $i (keys %{$stopwords}){
	my $tagged = $tagger->add_tags($i);

	my @words_raw = split / /, $tagged;
	my @words_hyoso;
	my @words_pos;
	my $words_stem;
	foreach my $h (@words_raw){
		if ($h =~ /^<(.+)>(.+)<\/\1>$/o){
			push @words_pos,   $1;
			push @words_hyoso, $2;
		} else {
			warn("error in tagger? $h\n");
		}

		$words_stem = Lingua::Stem::En::stem(
			{
				-words => \@words_hyoso,
				-locale => 'en',
			}
		);
	}


	#print "$i\t\t:\t";
	foreach my $f (@{$words_stem}){
		#print "$f, ";
		++$r{$f};
	}
	#print "\n";

}


my @r = sort (keys %r);
foreach my $i (@r){
	print "$i\n";
}
