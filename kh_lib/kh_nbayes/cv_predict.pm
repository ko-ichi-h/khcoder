package kh_nbayes::cv_predict;
use base qw(kh_nbayes);

use strict;

sub each{
	my $self = shift;
	my $current = shift;
	my $last    = shift;
	
	unless ( $self->{cross_vl_c} == $self->{member_group}{$last} ){
		return 0;
	}
	
	my ($r, $r2) = $self->{cls}->predict(
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

	# ログ保存
	if ($self->{cross_savel}){
		$self->{result_log}{$last} = $r2;
	}

	$self->{test_result_raw}{$last} = $max_lab;

	if ( $max_lab eq $self->{outvar_cnt}{$last} ){
		push @{$self->{test_result}}, 1;
		++$self->{test_count_hit};
	} else {
		push @{$self->{test_result}}, 0;
	}
	
	++$self->{test_count};
	return $self;
}


sub make_log_file{
	my $self = shift;

	# 最小値を$fixerとする
	my %labels;
	my $fixer = 0;
	foreach my $i (values %{$self->{result_log}}){  # $i = ログ
		foreach my $h (values %{$i}){               # $h = 抽出語別
			foreach my $j (keys %{$h->{l}}){        # $j = ラベル
				$labels{$j} = 1 unless $labels{$j} == 1;
				$fixer = $h->{l}{$j} if $fixer > $h->{l}{$j};
			}
		}
	}
	my @labels = sort (keys %labels);

	my $name = kh_msg->get('cross_validation'); # （交差妥当化）

	my $obj;
	$obj->{labels}     = \@labels;
	$obj->{fixer}      = $fixer;
	$obj->{tani}       = $self->{tani};
	$obj->{file_model} = $name;
	$obj->{outvar}     = $name;
	$obj->{log}        = $self->{result_log};
	$obj->{prior_probs}= undef;

	Storable::nstore($obj, $self->{cross_path});

	return 1;
}

# テスト別に事前確率を保存
sub push_prior_probs{
	my $self = shift;
	
	my $name = kh_msg->get('kh_nbayes::Util->prior');
	
	foreach my $i (keys %{$self->{result_log}}){
		unless ( $self->{result_log}{$i}{$name}{v} ){
			$self->{result_log}{$i}{$name}{v} = 1;
			$self->{result_log}{$i}{$name}{l} = 
				$self->{cls}{model}{prior_probs};
		}
	}
	return $self;
}

1;