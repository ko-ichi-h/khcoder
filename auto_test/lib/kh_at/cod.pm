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
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ),'reserve_rn' )
	)->euc;
	$win->{tani_obj}->{raw_opt} = 'dan';
	$win->{tani_obj}->mb_refresh;
	$win->_calc;
	$self->{result} .= "■単純集計：段落単位\n";
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ),'reserve_rn' )
	)->euc;
	$win->{tani_obj}->{raw_opt} = 'h2';
	$win->{tani_obj}->mb_refresh;
	$win->_calc;
	$self->{result} .= "■単純集計：h2単位\n";
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ),'reserve_rn' )
	)->euc;

	# 章・節・段落ごとの集計
	sub comment_out{
	my $win1 = gui_window::cod_tab->open;
	$win1->{tani_obj}->{raw_opt} = gui_window->gui_jchar('段落','euc');
	$win1->{tani_obj}->check;
	$win1->{tani_obj}->{raw_opt2} = gui_window->gui_jchar('H1','euc');
	$win1->{tani_obj}->{opt2}->update;
	$win1->_calc;
	$self->{result} .= "■章・節・段落ごと：段落―H1単位\n";
	#require Encode;
	my $t = '';
	foreach my $i (@{$win1->{result}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			#print "$h, ";
			#print "is_utf8: ",Encode::is_utf8($h),"\n";
			++$n;
		}
		$t .= "\n";
		print "\n";
	}
	
	
	$t = Jcode->new($t,'sjis')->euc;
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
	$t = Jcode->new($t,'sjis')->euc;
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
	$t = Jcode->new($t, 'sjis')->euc;
	$self->{result} .= $t;
	}
	
	# クロス集計
	my $win2 = gui_window::cod_outtab->open;
	my $t;
	$self->{result} .= "■クロス集計：段落―「見出し1」\n";
	$win2->{tani_obj}->{raw_opt} = 'dan';
	$win2->{tani_obj}->mb_refresh;
	$win2->{var_obj}->{opt_body}->{selection} = 'h1';
	$win2->{var_obj}->{opt_body}->mb_refresh;
	$win2->_calc;
	$t = '';
	foreach my $i (@{$win2->{result}->{display}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	$t = Jcode->new( $t, 'sjis' )->euc;
	$self->{result} .= $t;
	
	$self->{result} .= "■クロス集計：段落―「h1（dan）」\n";
	$win2->{tani_obj}->{raw_opt} = 'dan';
	$win2->{tani_obj}->mb_refresh;
	$win2->{var_obj}->{opt_body}->{selection} = 1; # 変数のID
	$win2->{var_obj}->{opt_body}->mb_refresh;
	$win2->_calc;
	$t = '';
	foreach my $i (@{$win2->{result}->{display}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	$t = Jcode->new($t,'sjis')->euc;
	$self->{result} .= $t;
	
	$self->{result} .= "■クロス集計：段落―「大見出し（h1）」\n";
	$win2->{tani_obj}->{raw_opt} = 'dan';
	$win2->{tani_obj}->mb_refresh;
	$win2->{var_obj}->{opt_body}->{selection} = 4; # 変数のID
	$win2->{var_obj}->{opt_body}->mb_refresh;
	$win2->_calc;
	$t = '';
	foreach my $i (@{$win2->{result}->{display}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	$t = Jcode->new($t,'sjis')->euc;
	$self->{result} .= $t;
	
	$self->{result} .= "■クロス集計：h2―「大見出し」\n";
	$win2->{tani_obj}->{raw_opt} = 'h2';
	$win2->{tani_obj}->mb_refresh;
	$win2->{var_obj}->{opt_body}->{selection} = 4; # 変数のID
	$win2->{var_obj}->{opt_body}->mb_refresh;
	$win2->_calc;
	$t = '';
	foreach my $i (@{$win2->{result}->{display}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	$t = Jcode->new($t,'sjis')->euc;
	$self->{result} .= $t;

	$self->{result} .= "■クロス集計：h2―「見出し1」\n";
	$win2->{tani_obj}->{raw_opt} = 'h2';
	$win2->{tani_obj}->mb_refresh;
	$win2->{var_obj}->{opt_body}->{selection} = 'h1';
	$win2->{var_obj}->{opt_body}->mb_refresh;
	$win2->_calc;
	$t = '';
	foreach my $i (@{$win2->{result}->{display}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	$t = Jcode->new($t,'sjis')->euc;
	$self->{result} .= $t;

	
	# コード間関連
	my $win3 = gui_window::cod_jaccard->open;

	$self->{result} .= "■コード間関連：h2\n";
	$win3->{tani_obj}->{raw_opt} = 'h2';
	$win3->{tani_obj}->mb_refresh;
	$win3->_calc;
	$t = '';
	foreach my $i (@{$win3->{result}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	$t = Jcode->new($t,'sjis')->euc;
	$self->{result} .= $t;

	$self->{result} .= "■コード間関連：dan\n";
	$win3->{tani_obj}->{raw_opt} = 'dan';
	$win3->{tani_obj}->mb_refresh;
	$win3->_calc;
	$t = '';
	foreach my $i (@{$win3->{result}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $h;
			++$n;
		}
		$t .= "\n";
	}
	$t = Jcode->new($t,'sjis')->euc;
	$self->{result} .= $t;
	
	# コーディング結果書き出し（SPSS）
	my $cod_f_r;
	$cod_f_r = kh_cod::func->read_file($self->file_cod) or die;
	$cod_f_r->cod_out_csv('h2',$self->file_out_tmp_base.'.csv');

	open (RFILE,$self->file_out_tmp_base.'.csv') or die;
	while (<RFILE>){
		$self->{result} .= Jcode->new($_,'sjis')->euc;
	}
	close (RFILE);

	unlink($self->file_out_tmp_base.'.csv');

	# コーディング結果書き出し（WordMiner）
	$cod_f_r = '';
	$cod_f_r = kh_cod::func->read_file($self->file_cod) or die;
	$cod_f_r->cod_out_var('h2',$self->file_out_tmp_base.'.csv');

	open (RFILE,$self->file_out_tmp_base.'.csv') or die;
	while (<RFILE>){
		$self->{result} .= Jcode->new($_,'sjis')->euc;
	}
	close (RFILE);

	unlink($self->file_out_tmp_base.'.csv');

	return $self;
}



sub test_name{
	return 'coding rules...';
}

1;