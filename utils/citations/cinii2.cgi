#!/usr/bin/perl

use strict;
use utf8;
use CGI;
use Encode;
use LWP::UserAgent;
use HTTP::Request::Common;

binmode STDOUT, ":utf8";

my $debug = 0;
my $target    = 'http://khcoder.net/bib.tsv';
my $localf    = 'bib_tmp/bib.tsv';
my $localf_dl = 'bib_tmp/bib_dl.tsv';
my $backup    = 'bib_tmp/backup.tsv';
my $pass      = '123457';

my $q = new CGI; 
my $cbib = '';

# 入力欄の文字化け対策
if ($q->param){
	my $qq = Encode::decode('utf8', $q->param('input') );
	$q->param('input', $qq);
}

use Cwd;
my $cwd = cwd;

# 最初の入力欄を作成
print
	$q->header(-charset => 'UTF-8'),
	$q->start_html(
		-title=> 'Bib Formatter',
		-lang => 'ja',
		-encoding => 'UTF-8',
	),
	'<link rel="stylesheet" href="/jquery-linedtextarea.css">',"\n",
	'<script type="text/javascript" src="/jquery.js"></script>',"\n",
	'<script type="text/javascript" src="/jquery-linedtextarea.js"></script>',"\n",
	
	'
	<SCRIPT LANGUAGE="JavaScript">
	<!--
		$(function() {
		 $(".lined").linedtextarea(
		 );
		});
	// --!>
	</SCRIPT>
	',
	
	$q->h2('Bib Formatter'),
	$q->p(
		"CiNii・Jstage・機関リポジトリの論文URLを入力してください。<a href=\"$localf\">文献リスト</a>への追加をお手伝いします。"
	),
	
	$q->start_form(),
	$q->textarea(
		-name=>'input',
		-default=>'',
		-class => 'lined',
		-rows=>7,
		-columns=>120
	),
	'<br>',

	$q->submit(
		-name=>'Excecute',
		-value=>'search'
	),
	$q->end_form,
	$q->hr,
	
	$q->a({href => 'cinii3.cgi'}, "自由書式で追加"),
	' | ',
	$q->a({href => 'edit_bib.cgi'}, "すでに入力した文献の修正・削除"),
	$q->p(' '),
;

# URLの入力があった場合の検索
if ( $q->param('Excecute') eq 'search' ){

	# 文献情報の収集
	my @new_data = ();
	
	&renew_bib;
	&load_old;
	
	my $qq = $q->param('input');
	$qq =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	foreach my $i (split /\n/, $qq){
		print "url: $i<br>\n" if $debug;
		chomp $i;
		chomp $i;
		next unless $i =~ /^http/;
		my ($t, $uri) = &get_info($i);
		$i = $uri if $uri;
		push @new_data, [$t, $i];
	}

	# 表示
	my $n = 1;
	print $q->start_form();
	foreach my $i (@new_data){
		next unless $i->[0];
		my $year;
		if ($i->[0] =~ /.+? ([0-9]{4}) /){
			$year = $1;
		}
		my $names;
		if ($i->[0] =~ /(.+?) [0-9]{4} /){
			$names = $1;
			$names =~ s/・//g;
		}
		my $chk = &check_dup($i->[0]);
		$i->[0] =~ s/\x0D|\x0A//g;
		print
			$q->h3("#".$n),
			$q->textarea(
				-name    =>'bib'.$n,
				-default => $i->[0],
				-rows    => 3,
				-columns => 120
			),
			
			"<br>\nYEAR: ",
			$q->textfield(
				-name    =>'year'.$n,
				-default => $year,
				-size =>10
			),
			
			"  YOMI1: ",
			$q->textfield(
				-name    => 'yomiA'.$n,
				-id      => 'yomiA'.$n,
				-default => $names,
				-size =>80
			),
			
			
			"<br>\n<a href=\" $i->[1]\" target=\"_blank\">URL</a>: ",
			$q->textfield(
				-name    =>'url'.$n,
				-default => $i->[1],
				-size =>80
			),
			
			"  YOMI2: ",
			$q->textfield(
				-name    => 'yomiB'.$n,
				-id      => 'yomiB'.$n,
				-default => '',
				-size =>3
			),
			$chk,
		;
		&print_script($n);
		++$n;
	}
	print
		$q->submit(
			-name=>'Excecute',
			-value=>'add'
		),
		$q->end_form()
	if $n > 1;
}

# 文献情報の追加
if ( $q->param('Excecute') eq 'add' ){
	my $n = 1;
	
	open my $fh, '>>:utf8', $localf or die;
	open my $fhb,'>>:utf8', $backup or die;

	while ( $q->param("bib$n") ){
		my $line = '';
		$line .= &del_tab( Encode::decode('utf8', $q->param("yomiB$n")));
		$line .= "\t";
		$line .= &del_tab( Encode::decode('utf8', $q->param("year$n")));
		$line .= "\t";
		$line .= &del_tab( Encode::decode('utf8', $q->param("bib$n")));
		$line .= "\t";
		$line .= "\t";
		$line .= &del_tab( Encode::decode('utf8', $q->param("url$n")));
		$line .= "\t";
		$line .= &del_tab( Encode::decode('utf8', $q->param("yomiA$n")));
		
		$line =~ s/\x0D|\x0A//g;
		print $fh "$line\x0D\x0A";
		print $fhb "$line\t[cinii2]\x0D\x0A";
		
		print $q->textarea(
			-name    =>'hoge'.$n,
			-default => $line,
			-rows    => 5,
			-columns => 120
		);
		++$n;
	}
	
	close $fh;
	close $fhb;
	
	print $q->p("Added!");
}

sub del_tab{
	my $t = shift;
	$t =~ s/\t/ /g;
	return $t;
}

#print
#	'<p>',
#	$q->start_form(),
#	$q->password_field(
#		-name => 'passwd',
#	),
#	$q->submit(
#		-name=>'Excecute',
#		-value=>'upload'
#	),
#	$q->end_form,
#	'<p>',
#;

# アップロード
if ( $q->param('Excecute') eq 'upload' ){
	if ( $q->param('passwd') eq $pass ){
		
		#use Net::SFTP::Foreign;
		
		
		print "Uploaded!";
	} else {
		print "NG!";
	}

}


sub check_dup{
	my $new = shift;
	
	my @keys = ();
	my $counts = 0;
	
	$new =~ s/, doi:.+$//;
	for (my $start = 0; $start + 3 <= length($new); ++$start){
		push @keys, substr($new,$start,3);
		++$counts;
	}
	
	my @hits;
	foreach my $i (@{$cbib}){
		my $score = 0;
		my $hg;
		foreach my $k (@keys){
			if ( $i->{ngram}{$k} ){
				++$score;
				push @{$hg}, $k;
			}
		}
		$score = $score / $counts * 100 * 10 + 0.5;
		$score = int($score) / 10;
		if ($score > 0){
			push @hits, [$score, $i->{raw}, $hg];
		}
	}
	
	return undef unless @hits;
	
	# return top 3;
	my $n = 0;
	my $d = '<UL>';
	foreach my $i (sort { $b->[0] <=> $a->[0] } @hits){
		# 強調位置
		my @strong = ();
		foreach my $h (@{$i->[2]}){
			my $pos = 0;
			while ( index($i->[1], $h, $pos) > -1 ){
				$pos = index($i->[1], $h, $pos);
				$strong[$pos] = 1;
				$strong[$pos + 1] = 1;
				$strong[$pos + 2] = 1;
				++$pos;
			}
		}
		
		# 強調実行
		my $t = '';
		my $flg = 0;
		for (my $p = 0; $p < length($i->[1]); ++$p ){
			if ($strong[$p]){
				if ($flg){
					$t .= substr($i->[1], $p, 1);
				} else {
					$t .= '<font color="green">';
					$t .= substr($i->[1], $p, 1);
				}
				$flg = 1;
			} else {
				if ($flg){
					$t .= '</font>';
					$t .= substr($i->[1], $p, 1);
				} else {
					$t .= substr($i->[1], $p, 1);
				}
				$flg = 0;
			}
		}
		if ($flg){
			$t .= '</font>';
		}
		
		$d .= "<LI>";
		$d .= '<b>['.$i->[0].']</b> '.$t;
		++$n;
		last if $n >= 3;
	}
	$d .= '</UL>';
	return $d;
}

sub load_old{
	$cbib = undef;
	open my $fh, '<:utf8', $localf or die("file open: $localf");
	my $n = 0;
	while (<$fh>){
		chomp; chomp;
		my $b;
		my @c = split /\t/, $_;
		next unless($c[2]);
		$c[2] =~ s/, doi:.+$//;
		
		$b->{raw} = $c[2];
		for (my $start = 0; $start + 3 <= length($c[2]); ++$start){
			my $key = substr($c[2],$start,3);
			++$b->{ngram}{$key};
		}
		push @{$cbib}, $b;
		++$n;
	}
	close $fh;
	print "Records: $n.\n  ";
}

sub renew_bib{
	my $ua = LWP::UserAgent->new(
		agent      => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:39.0) Gecko/20100101 Firefox/39.0',
	);
	my $r = $ua->head($target);
	my $d = $r->header('last-modified');

	use HTTP::Date;
	$d = str2time($d);
	
	if (-e $localf){
		my @stat = stat $localf;
		print $q->p( "Remote: $d, Local: $stat[9]" ) if $debug;
		if ($stat[9] < $d){
			open my $fhb, '>>', $backup or die;
			print $fhb "\t\tDownload! Remote: $d, Local: $stat[9]\x0D\x0A";
			close $fhb;
			#&download_bib;
		}
	} else {
		&download_bib;
	}
}

sub download_bib{
	my $ua = LWP::UserAgent->new(
		agent      => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:39.0) Gecko/20100101 Firefox/39.0',
	);
	my $r = $ua->get($target);
	
	unless ($r->code == 200){
		print "エラー： $target のダウンロードに失敗しました！";
		exit;
	}

	my $d = $r->content;
	$d =~ s/\x0D/\x0A/g;
	$d =~ s/\x0A+/\x0A/g;
	$d =~ s/\x0A/\x0D\x0A/g;
	
	open my $fh, '>', $localf_dl or die();
	binmode $fh;
	print $fh $d;
	close($fh);
	
	my $new_size = -s $localf_dl;
	my $old_size = 0;
	if (-e $localf){
		$old_size = -s $localf;
	}
	
	if ($new_size >= $old_size){
		if (-e $localf ){
			unlink $localf or die;
		}
		rename $localf_dl, $localf or die;
		
		open my $fhb, '>>', $backup or die;
		print $fhb "\t\tSize: $old_size -> $new_size\x0D\x0A";
		close $fhb;
		print "Downloaded: $target. Size: $old_size -> $new_size\nCWD: $cwd. ";
	} else {
		print "ローカルファイルの方が大きいのでダウンロードを中止しました";
	}
}

sub print_script{
	my $n = shift;
	
	my $t = '
	<SCRIPT LANGUAGE="JavaScript">
	<!--
	// 「読み」欄の設定
	var yomi = \'\';
	$(function() {
		$("#yomiA'.$n.'").keyup(function(e) {
			var current = $("#yomiA'.$n.'").val();
			current = current.slice(0,1);
			if ( yomi != current ){
				yomi = current;
				setTimeout( function() {
					delayed_change'.$n.'( current );
				}, 500 );
			}
		});
	});
	
	function delayed_change'.$n.'( key ) {
		var yomi_now = $("#yomiB'.$n.'").val();
		var chk = key + "," + yomi + "," + yomi_now;
		//alert(chk);
		if (
			   ( yomi == key )
			&! ( yomi == yomi_now )
		){
			//alert(key);
			var nkey = "A-Z";
			
			if ( key.match( "[あ-お]" ) ){
				nkey = "あ";
			}
			else if ( key.match( "[か-こが-ご]" ) ){
				nkey = "か";
			}
			else if ( key.match( "[さ-そざ-ぞ]" ) ){
				nkey = "さ";
			}
			else if ( key.match( "[た-とだ-ど]" ) ){
				nkey = "た";
			}
			else if ( key.match( "[な-の]" ) ){
				nkey = "な";
			}
			else if ( key.match( "[は-ほば-ぼ]" ) ){
				nkey = "は";
			}
			else if ( key.match( "[ま-も]" ) ){
				nkey = "ま";
			}
			else if ( key.match( "[やゆよ]" ) ){
				nkey = "や";
			}
			else if ( key.match( "[ら-ろ]" ) ){
				nkey = "ら";
			}
			else if ( key.match( "わ" ) ){
				nkey = "わ";
			}
			$("#yomiB'.$n.'").val( nkey );
		}
	}
	
	yomi = $("#yomiA'.$n.'").val();
	yomi = yomi.slice(0,1);
	delayed_change'.$n.'( yomi );
	
	// --!>
	</SCRIPT>
	';
	print $t;
}


# 文献情報の収集ルーチン
sub get_info{
	my $i = shift;
	my $output = '';
	my $uri_tmp;

	print "url2: $i<br>\n" if $debug;;


	my $ua = LWP::UserAgent->new(
		agent      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:66.0) Gecko/20100101 Firefox/66.0',
	);

	if ( $i =~ /naid\/(\d+)/ ) {                        # CiNiiの場合
		#$output .= "cinii\n";
		my $r = $ua->get("http://ci.nii.ac.jp/naid/$1.bib");
		($output, $uri_tmp) =  &format( Encode::decode('UTF-8', $r->content) );
	}
	elsif ( $i =~ /crid\/(\d+)/ ) {                      # CiNii Researchの場合
		#$output .= "cinii\n";
		my $r = $ua->get("http://cir.nii.ac.jp/crid/$1.bib");
		($output, $uri_tmp) =  &format( Encode::decode('UTF-8', $r->content) );
	}
	elsif ( $i =~ /ncid\/BB(\d+)/ ) {                   # CiNii Booksの場合
		#$output .= "cinii books\n" if $debug;;
		my $r = $ua->get("http://ci.nii.ac.jp/ncid/BB$1.bib");
		#$output .= Encode::decode('UTF-8', $r->content)."\n" if $debug;
		($output, $uri_tmp) =  &format( Encode::decode('UTF-8', $r->content) );
	}
	elsif ( $i =~ /ncid\/BC(\d+X?)/ ) {                 # CiNii Booksの場合(2)
		$output .= "cinii books\n" if $debug;;
		my $r = $ua->get("http://ci.nii.ac.jp/ncid/BC$1.bib");
		$output .= Encode::decode('UTF-8', $r->content)."\n" if $debug;
		($output, $uri_tmp) =  &format( Encode::decode('UTF-8', $r->content) );
	}
	elsif ($i =~ /jstage/ ) {                           # JSTAGEの場合
		$i =~ s/\/_pdf\/-char\/ja/\/_article\/-char\/ja/;
		$uri_tmp = $i;
	
		my $r = $ua->get($i);
		my $t = Encode::decode('UTF-8', $r->content);
		
		print '1st get: ',
			$q->textarea(
				-name    =>'output0',
				-default =>$t,
				-rows    =>10,
				-columns =>80
			), '<br>' if $debug;
		;
		
		my $url = '';
		if ( $t =~ /<a href="(.+?)">BibTeX<\/a>/ ){
			$url = $1;
		}
		elsif ( $t =~ /<a href="(.+?)">BIB TEX/ ){
			$url = $1;
		} else {
			next;
		}
		
		$url =~ s/&amp;/&/g;
		$url =~ s/kijiLangKrke=en/kijiLangKrke=ja/;
		$url = 'http://www.jstage.jst.go.jp'.$url unless $url =~ /^http/;
		
		print "url3: $url<br>\n" if $debug;
		
		my $r1 = $ua->get($url);
		($output, $uri_tmp) =  &format( Encode::decode('UTF-8', $r1->content) );
	}
	elsif ($i =~ /ipsj\.ixsq\.nii\.ac\.jp/ ) {          # 情報処理学会・電子図書館
		my $r = $ua->get($i);
		my $t = Encode::decode('UTF-8', $r->content);
		print "<p>情報処理学会・電子図書館</p>\n"  if $debug;
		
		if ($t =~ /href="(.+?oaipmh.+?)"/i){
			my $url = $1;
			$url =~ s/&amp;/&/g;
			my $r1 = $ua->get($url);
			($output, $uri_tmp) = &format_oaipmh( Encode::decode('UTF-8', $r1->content) );
		}
	} else {                                            # その他リポジトリ
		my $r = $ua->get($i);
		my $t = Encode::decode('UTF-8', $r->content);
		if ($t =~ /href="(.+?bibtex.+?)"/i){            # bibtex
			print "<p>other: bibtex</p>\n"  if $debug;
			my $url = $1;
			$url =~ s/&amp;/&/g;
			
			my $r1 = $ua->get($url);
			($output, $uri_tmp) = &format( Encode::decode('UTF-8', $r1->content) );
		}
		elsif ( $t =~ /dspace/i || $t =~ /アイテムの詳細レコードを表示する/i ){
			                                             # dspace
			$output .= "other: dspace\n"  if $debug;
			my $biburl = $i;
			if ($biburl =~ /(.+)\?.+/){
				$biburl = $1;
				$i = $1;
			}
			$biburl = $biburl.'?mode=full';
			$output .= "biburl: $biburl\n" if $debug;
			my $r1 = $ua->get($biburl);
			($output, $uri_tmp) =  &format_dspace(
				Encode::decode('UTF-8', $r1->content)
			);
			
			$output .= "\n\n\n".Encode::decode('UTF-8', $r1->content)
				if $debug;
		}
		else {
			print "input: $t\n<p>\n" if $debug;
		}
		
		if ($t =~ />Permalink : (http.+?)</){
			$uri_tmp = $1;
		}
	}
	print "output: $output\n" if $debug;
	return ($output, $uri_tmp);
}

sub format_oaipmh{
	my $t = shift;
	$t =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	$t =~ tr/()/（）/;
	$t =~ s/&#x20;/ /g;
	$t =~ s/&amp;/&/g;
	$t =~ s/(<\/.+?>)/$1\n/g;
	
	
	print "<p>$t</p>" if $debug;
	
	my $year     ;
	my $author   ;
	my $title    ;
	my $journal  = '情報処理学会研究報告';
	my $vol      ;
	my $num      ;
	my $pages    ;
	my $doi      ;
	my $publisher;
	my $series   ;
	
	my $spage;
	my $epage;
	
	my $uri;
	
	foreach my $i (split /\n/, $t){
		if ( $i =~ /<title.*?>(.+?)<\/title>/ ){                # title
			$title = $1;
		}
		if ( $i =~ /<date>(.+)<\/date>/ ){                 # year
			$year = $1;
		}
		if ( $i =~ /<creator.*?>(.+?)<\/creator>/ ){        # author
			$author .= '・' if length($author);
			$author .= $1;
		}
		if ( $i =~ /<volume>(.+)<\/volume>/ ){                     # volume
			$vol = $1;
		}
		if ( $i =~ /<issue>(.+)<\/issue>/ ){                     # number
			$num = $1;
		}
		if ( $i =~ /<spage>(.+)<\/spage>/ ){                       # spage
			$spage = $1;
		}
		if ( $i =~ /<epage>(.+)<\/epage>/ ){                       # epage
			$epage = $1;
		}
		print "<p><xmp>$i</xmp></p>" if $debug;
		if ( $i =~ /<uri>(.+?)<\/uri>/i ){                       # uri
			print "<p>hit!</p>\n" if $debug;
			$uri = $1;
		}
	}

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

	print "<p>uri1: $uri</p>" if $debug;

	return ($out, $uri);
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
	#$out .= "\n\n\n$t" if $debug;
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
	#$out .= "$mode\n" if $debug;
	
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
	} else {
		$title .= '（'.$series.'）' if $series;
		$out .=
			"$author $year 『$title"
			."』 $publisher"
		;
	}

	if ($doi) {
		$doi = 'https://doi.org/'.$doi;
	}

	#$out .= "\n";
	return ($out, $doi);
}