package kh_nbayes::Util;

use List::Util qw(max sum);

sub knb2csv{
	my $class = shift;
	my $self = {@_};
	bless $self, $class;
	
	# 学習結果の読み込み
	$self->{cls} = Algorithm::NaiveBayes->restore_state($self->{path});
	my $fixer = 0;
	foreach my $i (values %{$self->{cls}{model}{smoother}}){
		$fixer = $i if $fixer > $i;
	}
	
	# データ整形
	my @labels = $self->{cls}->labels;
	my @rows;
	my %printed = ();
	foreach my $i (@labels){ # $i = ラベル
		foreach my $h (keys %{$self->{cls}{model}{probs}{$i}}){ # $h = 語
			unless ( $printed{$h} ){
				my $current = [ kh_csv->value_conv($h) ];
				foreach my $k (@labels){ # $k = ラベル
					push @{$current},
						(
							   $self->{cls}{model}{probs}{$k}{$h}
							|| $self->{cls}{model}{smoother}{$k} 
						)
						- $fixer
					;
				}
				push @rows, $current;
				$printed{$h} = 1;
			}
		}
	}
	
	# 書き出し
	open (COUT,">$self->{csv}") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "$self->{csv}",
		);

	my $header = '';
	$header .= ',スコア,';
	for (my $n = 1; $n <= $#labels; ++$n){
		$header .= ',';
	}
	$header .= ",行の%\n";

	$header .= "抽出語,";
	foreach my $i (@labels){
		$header .= kh_csv->value_conv($i).',';
	}
	$header .= ',';
	foreach my $i (@labels){
		$header .= kh_csv->value_conv($i).',';
	}
	chop $header;
	print COUT "$header\n";

	my $c = @labels;
	foreach my $i (
		sort { sum( @{$b}[1..$c] ) <=> sum( @{$a}[1..$c] ) } 
		@rows
	){
		my $t = '';
		# スコア
		foreach my $h ( @{$i} ){
			$t .= "$h,";
		}
		
		# 行の%
		$t .= ',';
		my $sum = sum( @{$i}[1..$c] );
		foreach my $h ( @{$i}[1..$c] ){
			$t .= $h / $sum * 100;
			$t .= ',';
		}
		
		chop $t;
		print COUT "$t\n";
	}
	close (COUT);
	kh_jchar->to_sjis($self->{csv}) if $::config_obj->os eq 'win32';
	
	return 1;
}

1;
