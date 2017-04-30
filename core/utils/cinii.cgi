#!/usr/local/bin/perl

use CGI;
use strict;
use utf8;
use Encode;

binmode STDOUT, ":utf8";

my $debug = 0;

my $q = new CGI; 

print
	$q->header(-charset => 'UTF-8'),
	$q->start_html('CiNii / Jstage Formatter'),
	$q->h1('CiNii / Jstage Formatter'),
	$q->h2('Description:'),
	$q->p(
		'CiNii・Jstage・機関リポジトリの論文URLを入力して実行すると、文献リスト掲載用のフォーマットに変換します。'
		.'<br>※現在は日本語文献にのみ対応。日本語文献でも未対応のパターンや、未対応のリポジトリがあるかもしれません。'
	),

	$q->h2('Input:'),
	$q->start_form(),
	$q->textarea(
		-name=>'input',
		-default=>'',
		-rows=>10,
		-columns=>80
	),
	'<br>',

	$q->submit(
		-name=>'実行！',
		-value=>'実行！'
	),
	$q->end_form,
	'<div align="right"><a href="./">戻る</a></div>',
	<p>,
	$q->hr,
;

if ($q->param){
	print
		$q->h2('Output:')
	;
	
	my $output = '';
	
	use LWP::UserAgent;
	use HTTP::Request::Common;
	my $ua = LWP::UserAgent->new(
		agent      => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:39.0) Gecko/20100101 Firefox/39.0',
	);
	
	my $qq = $q->param('input');
	$qq =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	foreach my $i (split /\n/, $qq){
		chomp $i;
		chomp $i;
		$output .= "\nurl: $i\n" if $debug;;

		next unless $i =~ /^http/;

		if ( $i =~ /naid\/(\d+)/ ) {                        # CiNiiの場合
			#$output .= "cinii\n";
			my $r = $ua->get("http://ci.nii.ac.jp/naid/$1.bib");
			$output .= &format( Encode::decode('UTF-8', $r->content) );
		}
		elsif ( $i =~ /ncid\/BB(\d+)/ ) {                   # CiNii Booksの場合
			$output .= "cinii books\n" if $debug;;
			my $r = $ua->get("http://ci.nii.ac.jp/ncid/BB$1.bib");
			$output .= Encode::decode('UTF-8', $r->content)."\n" if $debug;
			$output .= &format( Encode::decode('UTF-8', $r->content) );
		}
		elsif ($i =~ /jstage/ ) {                           # JSTAGEの場合
			$output .= "jstage\n"  if $debug;
			my $r = $ua->get($i);
			my $t = Encode::decode('UTF-8', $r->content);
			
			my $url = '';
			if ( $t =~ /<a href="(.+?)">BibTeX<\/a>/ ){
				$url = $1;
			} else {
				next;
			}
			
			$url =~ s/&amp;/&/g;
			$url =~ s/kijiLangKrke=en/kijiLangKrke=ja/;
			$url = 'http://www.jstage.jst.go.jp'.$url;
			
			my $r1 = $ua->get($url);
			$output .= &format( Encode::decode('UTF-8', $r1->content) );
		} else {                                            # その他リポジトリ
			my $r = $ua->get($i);
			my $t = Encode::decode('UTF-8', $r->content);
			
			if ($t =~ /href="(.+?bibtex.+?)"/i){            # bibtex
				$output .= "other: bibtex\n"  if $debug;
				my $url = $1;
				$output .= "biburl: $url\n"  if $debug;
				$url =~ s/&amp;/&/g;
				
				my $r1 = $ua->get($url);
				$output .= &format( Encode::decode('UTF-8', $r1->content) );
			}
			elsif ( $t =~ /dspace/i ){                      # dspace
				$output .= "other: dspace\n"  if $debug;
				my $biburl = $i;
				if ($biburl =~ /(.+)\?.+/){
					$biburl = $1;
					$i = $1;
				}
				$biburl = $biburl.'?mode=full';
				$output .= "biburl: $biburl\n" if $debug;
				my $r1 = $ua->get($biburl);
				$output .= &format_dspace(
					Encode::decode('UTF-8', $r1->content)
				);
				
				#$output .= "\n\n\n".Encode::decode('UTF-8', $r1->content)
				#	if $debug;
			}
		}
		
		$output .= "$i\n\n";
	}

	# 出力
	print $q->textarea(
		-name    =>'output',
		-default =>$output,
		-rows    =>10,
		-columns =>80
	),
}

sub format_dspace{
	my $t = shift;
	$t =~ tr/()/（）/;
	$t =~ s/&#x20;/ /g;
	$t =~ s/&amp;/&/g;

	my $year     ;
	my $author   ;
	my $title    ;
	my $journal  ;
	my $vol      ;
	my $num      ;
	my $pages    ;
	my $doi      ;
	my $publisher;
	my $series   ;
	
	my $spage;
	my $epage;
	
	foreach my $i (split /\n/, $t){
		
		if ( $i =~ />title<.+?Value">(.+?)<\/td/ ){                   # title
			$title = $1;
		}
		elsif ( $i =~ />dc.title<.+?Value">(.+?)<\/td/ ){
			$title = $1;
		}
		elsif ( $i =~ /jtitle<.+?Value">(.+?)<\/td/ ){                # journal
			$journal = $1;
		}
		elsif ( $i =~ />creator<.+?Value">(.+?)<\/td/ ){              # author
			$author .= '・' if length($author);
			$author .= $1;
		}
		elsif ( $i =~ />dc.contributor.author<.+?Value">(.+?)<\/td/ ){
			$author .= '・' if length($author);
			$author .= $1;
		}
		elsif ( $i =~ />contributor.author<.+?Value">(.+?)<\/td/ ){
			$author .= '・' if length($author);
			$author .= $1;
		}
		elsif ( $i =~ /date.issued<.+?Value">(.+?)<\/td/ ){           # date
			$year = $1;
		}
		elsif ( $i =~ /dateofissued<.+?Value">(.+?)<\/td/ ){
			$year = $1;
		}
		elsif ( $i =~ /volume<.+?Value">(.+?)<\/td/ ){                # vol
			$vol = $1;
		}
		elsif ( $i =~ /issue<.+?Value">(.+?)<\/td/ ){                 # num
			$num = $1;
		}
		elsif ( $i =~ /spage<.+?Value">(.+?)<\/td/ ){                 # spage
			$spage = $1;
		}
		elsif ( $i =~ /epage<.+?Value">(.+?)<\/td/ ){                 # epage
			$epage .= $1;
		}
	}
	
	# format
	$author =~ s/<.+?>//g;
	$author =~ s/,//g;
	$author =~ s/ //g;
	if ($title =~ /(.+) : (.+)/) {
		$title = $1.' ―'.$2.'―';
	}
	if ($title =~ /(.+)、(.+)/) {
		$title = $1.' ―'.$2.'―';
	}
	if ($title =~ /<b>(.+)<\/b>$/) {
		$title = $1;
	}
	if ($title =~ /(.+)\s$/) {
		$title = $1;
	}
	
	if ( $title =~ /(.+)\－(.+)\－$/ ){
		$title = $1.'―'.$2.'―';
	}
	if ( $title =~ /(.+)\-(.+)\-$/ ){
		$title = $1.'―'.$2.'―';
	}
	$title =~ s/(\S)―(.+)/$1 ―$2/;
	$title =~ tr/「」/『』/;

	if (length($epage) && length($spage) ){
		$pages = "$spage-$epage";
	}
	elsif (length($spage)){
		$pages = $spage;
	}
	$year = substr($year, 0, 4);

	my $out;
	$out = "$author $year 「$title」 『$journal』 ";
	if ( length($vol) ) {
		$out .= $vol;
	}
	if ( length($num) ) {
		if ( length($vol) ){
			$out .= "($num)";
		} else {
			$out .= "$num";
		}
	}
	if ($pages) {
		$out .= ": $pages";
	}
	$out .= "\n";
	$out .= "\n\n\n$t" if $debug;
	return $out;
}


sub format{
	my $t = shift;
	$t =~ tr/()/（）/;
	$t =~ s/&#x20;/ /g;
	$t =~ s/&amp;/&/g;
	

	my $year     ;
	my $author   ;
	my $title    ;
	my $journal  ;
	my $vol      ;
	my $num      ;
	my $pages    ;
	my $doi      ;
	my $publisher;
	my $series   ;
	
	
	if ($t =~ /year\s*=\s*"(\d+)"[,\n]/ || $t =~ /year=\{(\d+)\},/) {
		$year = $1;
	}
	if ($t =~ /author\s*=\s*"(.+?)"[,\n]/ || $t =~ /author=\{(.+?)\},/) {
		$author = $1;
		$author =~ s/<.+?>//g;
		$author =~ s/ and /・/g;
		$author =~ s/,//g;
		$author =~ s/ //g;
	}
	if ($t =~ /title\s*=\s*"(.+?)"[,\n]/ || $t =~ /title=\{(.+?)\},/) {
		$title = $1;
		if ($title =~ /(.+) : (.+)/) {
			$title = $1.' ―'.$2.'―';
		}
		if ($title =~ /(.+)、(.+)/) {
			$title = $1.' ―'.$2.'―';
		}
		if ($title =~ /<b>(.+)<\/b>$/) {
			$title = $1;
		}
		if ($title =~ /(.+)\s$/) {
			$title = $1;
		}
		
		if ( $title =~ /(.+)\－(.+)\－$/ ){
			$title = $1.'―'.$2.'―';
		}
		if ( $title =~ /(.+)\-(.+)\-$/ ){
			$title = $1.'―'.$2.'―';
		}
		$title =~ s/(\S)―(.+)/$1 ―$2/;
	}
	if ($t =~ /journal\s*=\s*"(.+?)"[,\n]/ || $t =~ /journal=\{(.+?)\},/) {
		$journal = $1;
		if ($journal =~ /(.+) = [a-zA-Z ]+/) {
			$journal = $1;
		}
		
	}
	if ($t =~ /volume\s*=\s*"(.+?)"[,\n]/ || $t =~ /volume=\{(.+?)\},/) {
		$vol = $1;
	}
	if ($t =~ /number\s*=\s*"(.+?)"[,\n]/ || $t =~ /number=\{(.+?)\},/) {
		$num = $1;
		if ($num eq ' ') {
			$num = '';
		}
		
	}
	if ($t =~ /pages\s*=\s*"(.+?)"[,\n]/ || $t =~ /pages=\{(.+?)\},/) {
		$pages = $1;
		$pages =~ s/\-\-/-/;
	}
	if ($t =~ /doi\s*=\s*"(.+?)"/ || $t =~ /doi=\{(.+?)\}/) {
		$doi = $1;
	}
	if ($t =~ /publisher\s*=\s*"(.+?)"/ || $t =~ /publisher=\{(.+?)\}/) {
		$publisher = $1;
	}
	if ($t =~ /series\s*=\s*"(.+?)"/ || $t =~ /series=\{(.+?)\}/) {
		$series = $1;
	}
	
	
	my $mode = 'journal';
	if ( $title and not $journal ){
		$mode = 'book';
	}
	
	
	my $out = '';
	$out .= "$mode\n" if $debug;
	
	if ($mode eq 'journal'){
		$title =~ tr/「」/『』/;
		
		$out .=
			"$author $year 「$title"
			."」 『$journal"
			."』 "
		;
		
		if ( $num and not $vol ) {
			$vol = $num;
			$num = '';
		}
		
		if ($vol) {
			$out .= $vol;
		}
		if ($num ) {
			$out .= "($num)";
		}
		if ($pages) {
			$out .= ": $pages";
		}
		if ($doi) {
			$out .= ", doi: $doi";
		}
	} else {
		$title .= '（'.$series.'）';
		$out .=
			"$author $year 『$title"
			."』 $publisher"
		;
	}

	$out .= "\n";
	return $out;
}