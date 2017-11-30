# 「cinii_result.txt」に保存された文献について、既にリストに存在するかどうか
# をチェックするための補助スクリプト。結果を「cinii_result2.txt」に保存

use strict;

use utf8;
use Encode::Locale;
eval { binmode STDOUT, ":encoding(console_out)"; }; warn $@ if $@;

my $current_file1 = '..\memo\bib.tsv';
my $current_file2 = '..\memo\bib_ng.txt';

my $new_file = 'cinii_result.txt';

# 現在のリストを読み込み
my @current;
open my $fh, '<:utf8', $current_file1 or die;
while (<$fh>){
	chomp;
	my @line = split /\t/, $_;
	push @current, [ $line[2], $line[4] ];
}
close $fh;

open my $fh, '<:utf8', $current_file2 or die;
while (<$fh>){
	chomp;
	my @line = split /\t/, $_;
	push @current, [ $line[0], $line[1] ];
}
close $fh;

# 新しいリストを読み込み
my @new;
open my $fh, '<:utf8', $new_file or die;
while (<$fh>){
	chomp;
	my @line = split /\t/, $_;
	push @new, [ $line[0], $line[1] ];
}

my @results;

# 新しいアイテムのチェック
my $nskip;
foreach my $i (@new){
	# CiNiiのURLが一致したらパス
	if ( &check_url($i->[1]) ){
		++$nskip;
		next;
	}
	
	# 既存のもので似ているものを探す
	my $m = &count_matches($i->[0]);
	
	push @results, [ $m->[1], $i->[0], $m->[0], $i->[1], $m->[2] ];
}

# 結果を書き出し
open my $fh, '>:utf8', 'cinii_result2.txt' or die;
foreach my $i (@results){
	print $fh "$i->[0]\t$i->[1]\t$i->[2]\t$i->[3]\t$i->[4]\n";
}

print "skiped: $nskip";


sub count_matches{
	my $query = shift;
	
	# 2グラムのリストアップ
	my @bigram;
	for (my $s = 0; $s <= length($query) -1; ++$s){
		push @bigram, substr($query, $s, 2);
	}
	my $total = @bigram;
	
	# 既存のリスト全アイテムについて、2グラムがどの程度一致するかカウント
	my @r;
	foreach my $i (@current){
		my $count;
		my $hit;
		foreach my $h (@bigram){
			if ( index($i->[0], $h) > -1 ){
				++$count;
				$hit .= "$h ";
			}
		}
		push @r, [$i->[0], $count, $hit];
	}
	
	# 一致数の順でソートして、最上位のみを結果として返す
	@r = sort {$b->[1] <=> $a->[1]} @r;
	
	my $p = int( $r[0]->[1] / $total * 100 + 0.5 );
	
	#unless ( substr($query, 0, 3) eq substr($r[0]->[0], 0, 3) ){
	#	$r[0]->[0] = 'deleted';
	#}
	
	return [$r[0]->[0], $p, $r[0]->[2]];
}


sub check_url{
	my $url = shift;
	my $chk = 0;
	foreach my $i (@current){
		if ($url eq $i->[1]){
			$chk = 1;
			last;
		}
	}
	return $chk;
}
