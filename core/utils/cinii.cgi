#!/usr/local/bin/perl

use CGI;
use Jcode;
use strict;

my $q = new CGI; 

print
	$q->header(-charset => 'euc-jp'),
	$q->start_html('CiNii / Jstage Formatter'),
	$q->h1('CiNii / Jstage Formatter'),
	$q->h2('Description:'),
	$q->p('CiNiiまたはJstageの論文URLを入力して実行すると、文献リスト掲載用のフォーマットに変換します。'),

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
	
	foreach my $i (split /\n/, $q->param('input')){
		# CiNiiの場合
		if ( $i =~ /naid\/(\d+)$/ ) {
			my $r = $ua->get("http://ci.nii.ac.jp/naid/$1.bib");
			my $t = Jcode->new($r->content, 'utf8')->euc;
			$output .= &format($t);
		}
		
		# JSTAGEの場合
		if ($i =~ /jstage/ ) {
			my $r = $ua->get($i);
			my $t = Jcode->new($r->content, 'utf8')->euc;
			
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
			my $t1 = Jcode->new($r1->content, 'utf8')->euc;
			$output .= &format($t1);
		}
	}

	# 出力
	print $q->textarea(
		-name    =>'output',
		-default =>$output,
		-rows    =>10,
		-columns =>80
	),
}

sub format{
	my $t = shift;
	my $output = '';

	my $year   ;
	my $author ;
	my $title  ;
	my $journal;
	my $vol    ;
	my $num    ;
	my $pages  ;
	my $doi    ;
	
	if ($t =~ /year="(\d+)",/ || $t =~ /year=\{(\d+)\},/) {
		$year = $1;
	}
	if ($t =~ /author="(.+?)",/ || $t =~ /author=\{(.+?)\},/) {
		$author = $1;
		$author =~ s/ and /・/g;
		$author =~ s/, //g;
		$author =~ s/ //g;
	}
	if ($t =~ /title="(.+?)",/ || $t =~ /title=\{(.+?)\},/) {
		$title = $1;
	}
	if ($t =~ /journal="(.+?)",/ || $t =~ /journal=\{(.+?)\},/) {
		$journal = $1;
	}
	if ($t =~ /volume="(.+?)",/ || $t =~ /volume=\{(.+?)\},/) {
		$vol = $1;
	}
	if ($t =~ /number="(.+?)",/ || $t =~ /number=\{(.+?)\},/) {
		$num = $1;
	}
	if ($t =~ /pages="(.+?)",/ || $t =~ /pages=\{(.+?)\},/) {
		$pages = $1;
	}
	if ($t =~ /doi="(.+?)"/ || $t =~ /doi=\{(.+?)\}/) {
		$doi = $1;
	}
	
	$output .=
		"$author $year 「$title"
		."」 『$journal"
		."』 "
	;
	
	if ( $num and not $vol ) {
		$vol = $num;
		$num = "undef";
	}
	
	if ($vol) {
		$output .= $vol;
	}
	if ($num ) {
		$output .= "($num)";
	}
	if ($pages) {
		$output .= ": $pages";
	}
	if ($doi) {
		$output .= ", doi: $doi";
	}

	$output .= "\n";
	return $output;
}