package kh_nbayes::predict;

use base qw(kh_nbayes);

use strict;
use List::Util qw(max sum);

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

	#print "$max".'-'."$cnt\n";

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
	$obj->{prior_probs}= $self->{cls}{model}{prior_probs};

	Storable::nstore($obj, $self->{save_path});

	return 1;
}


sub make_each_log_table{
	my $d      = shift;
	my $labels = shift;
	my $fixer  = shift;
	my $prior  = shift;
	
	my @rows;
	my %scores;
	my $cases = @{$labels};
	
	# 欠損対策
	unless ( defined($d) ){
		return undef;
	}
	
	my $name = kh_msg->get('kh_nbayes::Util->prior');
	
	unless ( $d->{$name}{v} ){
		$d->{$name}{v} = 1;
		foreach my $i (@{$labels}){
			$d->{$name}{l}{$i} = $prior->{$i};
		}
	}
	
	# $h = 抽出語
	foreach my $h (keys %{$d} ){
		my $current = [$h, $d->{$h}{v}];
		my $sum = 0;
		foreach my $j (@{$labels}){                         # スコア
			push @{$current}, sprintf(
				"%.2f",
				( $d->{$h}{l}{$j} - $fixer ) * $d->{$h}{v}
			);
			$scores{$j} += ( $d->{$h}{l}{$j} - $fixer ) * $d->{$h}{v};
			$sum +=        ( $d->{$h}{l}{$j} - $fixer ) * $d->{$h}{v};
		}
		
		my $s = 0;                                          # 分散
		foreach my $j (@{$labels}){
			$s += 
				(
					  ( $d->{$h}{l}{$j} - $fixer ) * $d->{$h}{v}
					- ( $sum / $cases )
				) ** 2
			;
		}
		push @{$current}, sprintf("%.2f", $s / $cases);

		foreach my $j (@{$labels}){                         # パーセント
			push @{$current}, sprintf(
				"%.2f",
				( $d->{$h}{l}{$j} - $fixer ) * $d->{$h}{v} / $sum * 100
			);
		}
		push @rows, $current;
	}

	@rows = sort {sum( @{$b}[1..$cases] ) <=> sum( @{$a}[1..$cases] )} @rows;
	return (\@rows, \%scores);
}

1;