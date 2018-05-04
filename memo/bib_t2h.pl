my $file_html = 'bib.html';
my $file_tsv  = 'bib.tsv';

# HTMLファイルの前後を読み取り
my $t_1 = '';
my $t_2 = '';
open (READF,$file_html) or die;
my $flag = 0;
while (<READF>){
	if ($flag == 0){
		$t_1 .= $_;
		if ( index($_, '<!-- begin old style -->') > -1 ){
			$flag = 1;
		}
	}
	if ($flag == 1){
		if ( index($_, '<!-- end old style -->') > -1 ){
			$flag = 2;
		}
	}
	if ($flag == 2){
		$t_2 .= $_;
	}
}
close (READF);

# 文献リストを作成
my $t = '';
open (READT,$file_tsv) or die;
while (<READT>){
	chomp;
	next unless length($_);
	my @current = split /\t/, $_;
	$t .= "<div class=\"bib\">$current[2]$current[3]</div>\n";
}
close (READT);

# 書き出し
open (OUTH,">temp.html") or die;
print OUTH $t_1, $t, $t_2;
close (OUTH);

unlink($file_html) or die;
rename("temp.html", $file_html) or die;

print "done.";