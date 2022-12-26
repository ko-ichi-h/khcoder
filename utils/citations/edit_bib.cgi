#!/usr/bin/perl

use strict;
use utf8;
use CGI;
use Encode;

my $localf = 'bib_tmp/bib.tsv';

my $q = new CGI; 
$q->charset("utf-8");
#$q->autoEscape(0);

# 入力欄の文字化け対策
#if ($q->param){
#	my $qq = Encode::decode('utf8', $q->param('input') );
#	$q->param('input', $qq);
#}

# データ読み込み
open (my $fh, '<:utf8:crlf', $localf);
my $bib;
my $n = 0;
while (<$fh>) {
	$_ =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	chomp $_;
	my @c = split /\t/, $_;
	push @{$bib}, \@c;
	++$n;
}
close ($fh);


if    ( $q->param('button') eq 'edit' ){
	&edit;
}
elsif ( $q->param('button') eq 'delete this entry' ){
	&delete1;
}
elsif ( $q->param('button') eq 'delete' ){
	&delete2;
}
elsif ( $q->param('button') eq 'save' ){
	&save;
}
elsif ( $q->param('button') eq 'search' ){
	&search;
} else {
	&top_page;
}

sub delete1{
	my $id = $q->param('line');
	
	print
		$q->header(-type=>'text/html', -charset=>'utf-8'),
		$q->start_html(
			-title=> 'Bib Editor: delete',
			-lang => 'ja-JP',
			-encoding => 'UTF-8',
		),
		'<script type="text/javascript" src="/jquery.js"></script>',"\n",
		$q->h2('Bib Editor: delete'),
		
		$q->p("本当にこの文献を削除してよろしいですか？\n"),
		
		$q->blockquote($bib->[$id][2]),
		
		
		$q->start_form(),
		
		$q->hidden(
			'line' => $id,
		),
		$q->submit(
			-name=>'button',
			-value=>'cancel'
		),
		' ',
		$q->submit(
			-name=>'button',
			-value=>'delete'
		),
		$q->end_form,
		
		$q->end_html,
	;
	return 1;

}

sub search{
	my $t = Encode::decode('utf8', $q->param('search_string') );
	
	$t = " \t \t " unless length($t);
	
	my @r = ();
	my $n = 0;
	foreach my $i (@{$bib}){
		my $tt = $i->[2].$i->[4].$i->[5];
		#if ( index( $i->[2].$i->[4].$i->[5], $t ) >= 0 ){
		if ( $tt =~ /$t/ ){
			push @r, $n;
		}
		++$n;
	}
	
	my $p = 0;
	my $list_content2 = '';
	foreach my $i (reverse @r){
		$list_content2 .= $q->li(
			$q->start_form(),
			$bib->[$i][2],
			#$id,
			' ',
			#$q->a(
			#	{ href => "?mode=edit&line=$id" },
			#	'[edit]'
			#),
			
			"<input type=\"hidden\" name=\"line\" value=\"$i\">",
			$q->submit(
				-name=>'button',
				-value=>'edit'
			),
			$q->end_form,
		)."\n";
		++$p;
		if ($p > 49){
			last;
		}
	}
	
	print
		$q->header(-type=>'text/html', -charset=>'utf-8'),
		$q->start_html(
			-title=> 'Bib Editor: search',
			-lang => 'ja-JP',
			-encoding => 'UTF-8',
		),
		'<script type="text/javascript" src="/jquery.js"></script>',"\n",
		$q->h2('Bib Editor: search: '.$t),
		
		$q->a({href => "edit_bib.cgi"}, "back"),
		
		' （ヒットしたうち最近の50件を表示します）',
		
		$q->hr,
		
		$q->ul(
			$list_content2
		),
		
		$q->hr,
		$q->a({href => "edit_bib.cgi"}, "back"),
		$q->end_html,
	;
	
	return 1;
}

sub delete2{
	my $id = $q->param('line');

	my $out = '';
	my $n = 0;
	foreach my $i (@{$bib}){
		if ($n == $id) {
			#$out .= "$c1\t$c2\t$c3\t$c4\t$c5\t$c6\n";
		} else {
			$out .= "$i->[0]\t$i->[1]\t$i->[2]\t$i->[3]\t$i->[4]\t$i->[5]\n";
		}
		++$n;
	}
	
	my $fn = 0;
	while ( -e $localf."_bak$fn"){
		++$fn;
	}
	
	open (my $fho, '>:utf8:crlf', $localf.".$fn");
	print $fho $out;
	close ($fho);

	rename($localf, $localf."_bak$fn") or die;
	rename($localf.".$fn", $localf) or die;

	print
		$q->header(-type=>'text/html', -charset=>'utf-8'),
		$q->start_html(
			-title=> 'Bib Editor: delete',
			-lang => 'ja-JP',
			-encoding => 'UTF-8',
		),
		'<script type="text/javascript" src="/jquery.js"></script>',"\n",
		$q->h2('Bib Editor: delete'),
		
		$q->p("削除しました！\n"),
		
		$q->blockquote($bib->[$id][2]),
		
		$q->hr,
		$q->a({href => "edit_bib.cgi"}, "back"),
		$q->end_html,
	;
	return 1;
}


sub save{
	my $id = $q->param('line');

	my $c1 = Encode::decode('utf8', $q->param('c1') );
	my $c2 = Encode::decode('utf8', $q->param('c2') );
	my $c3 = Encode::decode('utf8', $q->param('c3') );
	my $c4 = Encode::decode('utf8', $q->param('c4') );
	my $c5 = Encode::decode('utf8', $q->param('c5') );
	my $c6 = Encode::decode('utf8', $q->param('c6') );

	my $flag = 0;
	if ( length($c3) ){

		my $out = '';
		my $n = 0;
		foreach my $i (@{$bib}){
			if ($n == $id) {
				$out .= "$c1\t$c2\t$c3\t$c4\t$c5\t$c6\n";
			} else {
				$out .= "$i->[0]\t$i->[1]\t$i->[2]\t$i->[3]\t$i->[4]\t$i->[5]\n";
			}
			++$n;
		}
		
		my $fn = 0;
		while ( -e $localf."_bak$fn"){
			++$fn;
		}
		
		open (my $fho, '>:utf8:crlf', $localf.".$fn");
		print $fho $out;
		close ($fho);

		rename($localf, $localf."_bak$fn") or die;
		rename($localf.".$fn", $localf) or die;
	
		$flag = 1;
	}

	my $msg;
	if ($flag){
		$msg = "Saved!";
	} else {
		$msg = "保存に失敗しました。やり直してください。";
	}

	print
		$q->header(-type=>'text/html', -charset=>'utf-8'),
		$q->start_html(
			-title=> 'Bib Editor: save',
			-lang => 'ja-JP',
			-encoding => 'UTF-8',
		),
		'<script type="text/javascript" src="/jquery.js"></script>',"\n",
		$q->h2('Bib Editor: save'),
		
		$q->p("$id: $msg\n"),
		
		$q->hr,
		$q->a({href => "edit_bib.cgi"}, "back"),
		$q->end_html,
	;
	return 1;
}


sub edit{
	my $id = $q->param('line');

	print
		#"Content-Type:text/html\n\n",
		$q->header(-type=>'text/html', -charset=>'utf-8'),
		$q->start_html(
			-title=> 'Bib Editor: edit',
			-lang => 'ja-JP',
			-encoding => 'UTF-8',
		),
		'<script type="text/javascript" src="/jquery.js"></script>',"\n",
		$q->h2('Bib Editor: edit'),
		
		$q->start_form(),
		
		$q->hidden(
			'line' => $id,
		),
		
		$q->p(
			'yomi1: ',
			$q->textfield(
				-name    => 'c1',
				-id      => 'c1',
				-default => $bib->[$id][0],
				-size => 80
			),
		),
		"\n",

		$q->p(
			'year: ',
			$q->textfield(
				-name    => 'c2',
				-id      => 'c2',
				-default => $bib->[$id][1],
				-size => 80
			),
		),
		"\n",

		$q->p(
			'bib: ',
			$q->textfield(
				-name    => 'c3',
				-id      => 'c3',
				-default => $bib->[$id][2],
				-size => 100
			),
		),
		"\n",

		$q->p(
			'link: ',
			$q->textfield(
				-name    => 'c5',
				-id      => 'c5',
				-default => $bib->[$id][4],
				-size => 100
			),
		),
		"\n",

		$q->p(
			'yomi2: ',
			$q->textfield(
				-name    => 'c6',
				-id      => 'c6',
				-default => $bib->[$id][5],
				-size => 100
			),
		),
		"\n",

		$q->p(
			'memo: ',
			$q->textfield(
				-name    => 'c4',
				-id      => 'c4',
				-default => $bib->[$id][3],
				-size => 100
			),
		),
		"\n",

		$q->submit(
			-name=>'button',
			-value=>'cancel'
		),
		' ',
		$q->submit(
			-name=>'button',
			-value=>'save'
		),
		' &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; ',
		$q->submit(
			-name=>'button',
			-value=>'delete this entry'
		),
		$q->end_form,
		$q->end_html,
	;
	return 1;
}

sub top_page{
	print
		#"Content-Type:text/html\n\n",
		#"<html>\n",
		#"<title>Bib Editor</title>\n",
		#"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n",
		#"<body>\n",
		
		$q->header(-type=>'text/html', -charset=>'utf-8'),
		$q->start_html(
			-title=> 'Bib Editor: top',
			-lang => 'ja-JP',
			-encoding => 'UTF-8',
		),
		'<script type="text/javascript" src="/jquery.js"></script>',"\n",
		
		
		
		$q->h2('Bib Editor: top'),
		
		$q->start_form(),
		$q->textfield(
			-name    => 'search_string',
			-id      => 'search_string',
			-default => '',
			-size => 80
		),
		' ',
		$q->submit(
			-name=>'button',
			-value=>'search'
		),
		$q->end_form,
		
		$q->hr,
		$q->p(
			"<a href=\"$localf\">文献リスト</a>に最近入力された10件（ $n 件中）："
		),
	;

	my $list_content = '';
	my $len = @{$bib} - 1;

	for (my $n = 0; $n < 10; ++$n){
		my $id = $len - $n;
		$list_content .= $q->li(
			$q->start_form(),
			$bib->[$id][2],
			#$id,
			' ',
			#$q->a(
			#	{ href => "?mode=edit&line=$id" },
			#	'[edit]'
			#),
			
			"<input type=\"hidden\" name=\"line\" value=\"$id\">",
			$q->submit(
				-name=>'button',
				-value=>'edit'
			),
			$q->end_form,
		)."\n";
	}

	print
		$q->ul(
			$list_content
		),
		$q->hr,
		$q->a({href => 'cinii2.cgi'}, "CiNii・Jstage・機関リポジトリから追加"),
		' | ',
		$q->a({href => 'cinii3.cgi'}, "自由書式で追加"),
		
		
		$q->end_html,
	;
	return 1;
}