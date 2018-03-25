# CiNii全文検索を行って、結果を「cinii_result.txt」に保存する

use strict;

use utf8;
use Encode::Locale;
eval { binmode STDOUT, ":encoding(console_out)"; }; warn $@ if $@;

my @results;

use LWP::UserAgent;
use HTTP::Request::Common;
use XML::RSS;

my $ua = LWP::UserAgent->new(
	#agent      => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:39.0) Gecko/20100101 Firefox/39.0',
);

my $n = 0;
while (1){
	my $start = $n * 200;
	
	my $r = $ua->get("http://ci.nii.ac.jp/opensearch/search?q=%22KH+Coder%22+%7C+KHCODER+%7C+%22KH%E3%82%B3%E3%83%BC%E3%83%80%E3%83%BC%22+%7C+%22%E6%A8%8B%E5%8F%A3%E8%80%95%E4%B8%80%22&start=$start&count=200&format=rss&sortorder=1");
	#my $r = $ua->get("http://ci.nii.ac.jp/opensearch/fulltext?q=%22KH+Corder%22+%7C+KHCORDER&start=$start&count=200&format=rss&sortorder=1");
	$r = Encode::decode('UTF-8', $r->content);
	
	#print "$r\n\n";
	
	my $rss = XML::RSS->new;
	$rss->parse($r);
	&my_parse($rss);
	
	++$n;
	print "$n, ";
	
	my $items = @{$rss->{'items'}};
	last if $items < 20;
}

open my $fh, '>:utf8', "cinii_result.txt" or die;
foreach my $i (@results){
	print $fh "$i\n";
}
close $fh;



sub my_parse{
	my $rss = shift;
	foreach my $item (@{$rss->{'items'}}) {
		# author
		my $a;
		if (ref $item->{dc}{creator}){
			foreach my $i (@{$item->{dc}{creator}}){
				$a .= '・' if length($a);
				$a .= $i;
			}
		} else {
			$a = $item->{dc}{creator};
		}
		$a =~ s/ //g;

		# year
		my $y = $item->{dc}{date};
		$y = substr($y, 0, 4);
		
		my $t = $item->{'title'};
		if ($t =~ /(.+) : (.+)/) {
			$t = $1.' ―'.$2.'―';
		}
		$t =~ tr/「」()/『』（）/;
		$t =~ s/(.+\S)―(.+)/$1 ―$2/;

		my $j = $item->{'http://prismstandard.org/namespaces/basic/2.0/'}{publicationName};
		
		my $v = $item->{'http://prismstandard.org/namespaces/basic/2.0/'}{volume};
		my $n = $item->{'http://prismstandard.org/namespaces/basic/2.0/'}{number};
		my $vn;
		if (length($v) && length($n) ){
			$vn = "$v($n)";
		}
		elsif (length($v)){
			$vn = "$v";
		}
		elsif (length($n)){
			$vn = "$n";
		}

		my $ps = $item->{'http://prismstandard.org/namespaces/basic/2.0/'}{startingPage};
		my $pe = $item->{'http://prismstandard.org/namespaces/basic/2.0/'}{endingPage};

		my $pages;
		if (length($ps) && length($pe)){
			$pages = "$ps-$pe";
		}
		elsif (length($ps)){
			$pages = $ps;
		}
		elsif (
			length(
			  $item->{'http://prismstandard.org/namespaces/basic/2.0/'}{pageRange}
			)
		){
			$pages = $item->{'http://prismstandard.org/namespaces/basic/2.0/'}{pageRange};
		}

		my $url = $item->{link};

		push @results, "$a $y 「$t」 『$j』 $vn: $pages\t$url";
	}
}