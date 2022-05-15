#!/usr/bin/perl

use strict;
use utf8;
use CGI;
use Encode;
use LWP::UserAgent;
use HTTP::Request::Common;

binmode STDOUT, ":utf8";

my $debug     = 0;
my $target    = 'http://khcoder.net/bib.tsv';
my $localf    = 'bib_tmp/bib.tsv';
my $localf_dl = 'bib_tmp/bib_dl.tsv';
my $backup    = 'bib_tmp/backup.tsv';
my $pass      = '123457';

my $q = new CGI; 
my $cbib = '';

use Cwd;
my $cwd = cwd;

# 入力欄の文字化け対策
if ($q->param){
	my $qq = Encode::decode('utf8', $q->param('input') );
	$q->param('input', $qq);
}

# 最初の入力欄を作成
print
	$q->header(-charset => 'UTF-8'),
	$q->start_html(
		-title=> 'Bib Formatter',
		-lang => 'ja',
		-encoding => 'UTF-8',
	),
	'<script type="text/javascript" src="/jquery.js"></script>',"\n",
	$q->h2('Bib Formatter'),
	$q->p(
		"書誌情報を入力してください。<a href=\"$localf\">文献リスト</a>への追加をお手伝いします。"
	),
	
	$q->start_form(),
	$q->textarea(
		-name=>'input',
		-default=>'',
		-rows=>7,
		-columns=>120
	),
	'<br>',

	$q->submit(
		-name=>'Excecute',
		-value=>'ready'
	),
	$q->end_form,
	$q->hr,
;

# 書誌情報の入力があった場合の検索
if ( $q->param('Excecute') eq 'ready' ){ # 

	# 情報の準備
	&renew_bib;
	&load_old;
	my $t = $q->param('input');
	
	my $year;
	if ($t =~ /.+? ([0-9]{4}) /){
		$year = $1;
	}
	my $names;
	if ($t =~ /(.+?) [0-9]{4} /){
		$names = $1;
		$names =~ s/・//g;
	}
	my $chk = &check_dup($t);
	
	# 表示
	my $n = 1;
	print $q->start_form();

		print
			$q->textarea(
				-name    =>'bib'.$n,
				-default => $t,
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
			
			
			"<br>\nURL: ",
			$q->textfield(
				-name    =>'url'.$n,
				-default => '',
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

	print
		$q->submit(
			-name=>'Excecute',
			-value=>'add'
		),
		$q->end_form()
}

# 文献情報の追加
if ( $q->param('Excecute') eq 'add' ){
	my $n = 1;
	
	open my $fh, '>>', $localf or die;
	binmode($fh);
	
	open my $fhb,'>>', $backup or die;
	binmode($fhb);
	
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
		$line = Encode::encode('utf8', $line);
		
		$line =~ s/\x0D|\x0A//g;
		print $fh "$line\x0D\x0A";
		print $fhb "$line\t[cinii3.cgi]\x0D\x0A";
		
		print $q->textarea(
			-name    =>'hoge'.$n,
			-default => Encode::decode('utf8', $line),
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
		$score = $score / $counts * 100 * 10 + 0.5 if $counts;
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
			&download_bib;
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

