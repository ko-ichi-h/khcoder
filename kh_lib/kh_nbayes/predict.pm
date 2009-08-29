package kh_nbayes::predict;

use base qw(kh_nbayes);

use strict;

sub each{
	my $self = shift;
	my $current = shift;
	my $last    = shift;
	
	my ($r, $p) = $self->{cls}->predict(
		attributes => $current
	);
	
	my $cnt     = 0;
	my $max     = 0;
	my $max_lab = 0;
	foreach my $i (keys %{$r}){
		++$cnt if $r->{$i} >= 0.6;
		if ($max < $r->{$i}){
			$max = $r->{$i};
			$max_lab = $i;
		}
	}

	if ($self->{save_log}){
		$self->{result_log}{$last} = $p;
	}

	#if (
	#	   $cnt == 1
	#	&& $max >= 0.8
	#) {
	#	push @{$self->{result}}, [$max_lab];
	#} else {
	#	push @{$self->{result}}, ['.'];
	#}

	push @{$self->{result}}, [$max_lab];

	return $self;
}

sub make_log_file{
	my $self = shift;

	my $fixer = 0;
	foreach my $i (values %{$self->{cls}{model}{smoother}}){
		#print "fx: $i\n";
		$fixer = $i if $fixer > $i;
	}
	my @labels = $self->{cls}->labels;

	my $obj;
	$obj->{labels}     = \@labels;
	$obj->{fixer}      = $fixer;
	$obj->{tani}       = $self->{tani};
	$obj->{file_model} = $self->{path};
	$obj->{outvar}     = $self->{outvar};
	$obj->{log}        = $self->{result_log};

	Storable::nstore($obj, $self->{save_path});

	return 1;

	#------------------#
	#   以下は残骸…   #

	open (LOUT,">$self->{save_path}") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "$self->{save_path}",
		);
	
	
	# $i = 文書 No.
	foreach my $i (sort {$a <=> $b} keys %{$self->{result_log}} ){
		print LOUT "文書 No. $i\n\n";

		# 「各抽出語のスコア」表を作成
		my ($rows, $scores) =
			&make_each_log_table(
				$self->{result_log}{$i},      # ログデータ
				\@labels,                     # カテゴリのカラム順指定
				$fixer,                       # min( smoothers )
			);

		print LOUT "スコア：\n";
		my ($max, $max_ord, $n) = (0, 0, 0);
		foreach my $h (@labels){
			print LOUT "\t$h\t$scores->{$h}\n";
			if ($max < $scores->{$h}){
				$max = $scores->{$h};
				$max_ord = $n;
			}
			++$n;
		}
		$max_ord += 2;

		print LOUT "\n各抽出語のスコア：\n";
		print LOUT "\t抽出語\t頻度";
		foreach my $h (@labels){
			print LOUT "\t$h";
		}
		print LOUT "\n";

		my $tt = '';
		foreach my $h (sort {$b->[$max_ord] <=> $a->[$max_ord]} @{$rows}){
			my $t = "\t";
			foreach my $k (@{$h}){
				$t .= "$k\t";
			}
			chop $t;
			$tt .= "$t\n";
		}
		print LOUT "$tt";
		print LOUT "-------------------------------------------------------------------------------\n\n"
	}
	close (LOUT);
	kh_jchar->to_sjis($self->{save_path});
	return 1;
}


sub make_each_log_table{
	my $d      = shift;
	my $labels = shift;
	my $fixer  = shift;
	
	my @rows;
	my %scores;
	# $h = 抽出語
	foreach my $h (keys %{$d} ){
		my $current = [$h, $d->{$h}{v}];
		my $sum = 0;
		foreach my $j (@{$labels}){
			push @{$current}, sprintf(
				"%.2f",
				( $d->{$h}{l}{$j} - $fixer ) * $d->{$h}{v}
			);
			$scores{$j} += ( $d->{$h}{l}{$j} - $fixer ) * $d->{$h}{v};
			$sum +=        ( $d->{$h}{l}{$j} - $fixer ) * $d->{$h}{v};
		}
		push @{$current}, '  ';
		foreach my $j (@{$labels}){
			push @{$current}, sprintf(
				"%.2f",
				( $d->{$h}{l}{$j} - $fixer ) * $d->{$h}{v} / $sum * 100
			);
		}
		
		push @rows, $current;
	}
	
	return (\@rows, \%scores);
}

























1;