package kh_at::cod;
use base qw(kh_at);
use strict;

sub _exec_test{
	my $self = shift;

	# テストに使用するコーディングルール・ファイルを指定
	$::project_obj->last_codf( $self->file_cod );

	# 単純集計
	my $win = gui_window::cod_count->open;
	$win->{tani_obj}->{raw_opt} = 'bun';
	$win->{tani_obj}->mb_refresh;
	$win->_calc;
	$self->{result} .= "■単純集計：文単位\n";
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;
	$win->{tani_obj}->{raw_opt} = 'dan';
	$win->{tani_obj}->mb_refresh;
	$win->_calc;
	$self->{result} .= "■単純集計：段落単位\n";
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;
	$win->{tani_obj}->{raw_opt} = 'h2';
	$win->{tani_obj}->mb_refresh;
	$win->_calc;
	$self->{result} .= "■単純集計：h2単位\n";
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	# 章・節・段落ごとの集計
	my $win1 = gui_window::cod_tab->open;
	$win1->{tani_obj}->{raw_opt} = gui_window->gui_jchar('段落','euc');
	$win1->{tani_obj}->check;
	$win1->{tani_obj}->{raw_opt2} = gui_window->gui_jchar('H1','euc');
	$win1->{tani_obj}->{opt2}->update;
	$win1->_calc;
	$self->{result} .= "■章・節・段落ごと：段落―H1単位\n";
	my $t = '';
	foreach my $i (@{$win1->{result}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	$t = Jcode->new($t)->euc;
	$self->{result} .= $t;
	
	$win1->{tani_obj}->{raw_opt} = gui_window->gui_jchar('H2','euc');
	$win1->{tani_obj}->check;
	$win1->{tani_obj}->{raw_opt2} = gui_window->gui_jchar('H1','euc');
	$win1->{tani_obj}->{opt2}->update;
	$win1->_calc;
	$self->{result} .= "■章・節・段落ごと：H2―H1単位\n";
	$t = '';
	foreach my $i (@{$win1->{result}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	$t = Jcode->new($t)->euc;
	$self->{result} .= $t;
	
	$win1->{tani_obj}->{raw_opt} = gui_window->gui_jchar('文','euc');
	$win1->{tani_obj}->check;
	$win1->{tani_obj}->{raw_opt2} = gui_window->gui_jchar('H2','euc');
	$win1->{tani_obj}->{opt2}->update;
	$win1->_calc;
	$self->{result} .= "■章・節・段落ごと：文―H2単位\n";
	$t = '';
	foreach my $i (@{$win1->{result}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	$t = Jcode->new($t)->euc;
	$self->{result} .= $t;
	
	
	return $self;
}



sub test_name{
	return 'coding rules...';
}

1;