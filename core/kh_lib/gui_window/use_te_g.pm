package gui_window::use_te_g;
use base qw(gui_window);
use strict;
use Tk;

#------------------#
#   Windowを開く   #

sub _new{
	my $self = shift;
	$self->{win_obj}->title(
		$self->gui_jchar('TermExtractによる複合語の検出','euc')
	);
	
	$self->{win_obj}->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => 'TKFN',
		-width => 8,
		-command => sub{
			$self->{win_obj}->after(10,sub{$self->close;})
		}
	)->pack(-anchor=>'e',-side => 'right',-padx => 2, -pady => 2);

	my $ok_btn = $self->{win_obj}->Button(
		-text  => 'OK',
		-font  => 'TKFN',
		-width => 8,
		-command => sub{ $self->{win_obj}->after
			(
				10,
				sub {
					$self->run;
				}
			);
		}
	)->pack(-anchor => 'e',-side => 'right',  -pady => 2);
	
	
	return $self;
}

#----------#
#   実行   #

sub run{
	my $self = shift;
	my $debug = 1;
	
	# 形態素解析が終わっていなければ実行
	unless (
		   (-e $::project_obj->file_MorphoOut_o)
		&& ( (stat($::project_obj->file_MorphoOut_o))[9] > (stat($::project_obj->file_target))[9] )
	){
		print "Running ChaSen!\n";
		print "outp: ",(stat($::project_obj->file_MorphoOut_o))[9],"\n";
		print "data: ",(stat($::project_obj->file_target))[9],"\n";
		
		# 形態素解析用のファイルを作成
		my $source = $::project_obj->file_target;
		my $dist   = $::project_obj->file_m_target;
		unlink($dist);
		my $icode = kh_jchar->check_code($source);
		open (MARKED,">$dist") or 
			gui_errormsg->open(
				type => 'file',
				thefile => $dist
			);
		open (SOURCE,"$source") or
			gui_errormsg->open(
				type => 'file',
				thefile => $source
			);
		while (<SOURCE>){
			chomp;
			my $text = Jcode->new($_,$icode)->h2z->euc;
			$text =~ s/ /　/go;
			print MARKED "$text\n";
		}
		close (SOURCE);
		close (MARKED);
		kh_jchar->to_sjis($dist) if $::config_obj->os eq 'win32';
		
		# 形態素解析の実行と後処理
		kh_morpho->run;
		kh_jchar->to_euc($::project_obj->file_MorphoOut)
			if $::config_obj->os eq 'win32';
		unlink($::project_obj->file_MorphoOut_o);
		rename($::project_obj->file_MorphoOut,$::project_obj->file_MorphoOut_o) or die;
	}
	
	# フィルタリング用に単名詞のリストを作成
	my %is_alone = ();
	open (CHASEN,$::project_obj->file_MorphoOut_o) or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $::project_obj->file_MorphoOut_o
			);
	while (<CHASEN>){
		$is_alone{(split /\t/, $_)[0]} = 1;
	}
	close (CHASEN);
	print "done: scan for filtering\n" if $debug;
	
	
	use TermExtract::Chasen;
	
	# 選択されていない重要度指標を一通り計算
	my (%i_tf,%i_frq,%i_total,%i_uniq,%i_ppl);
	if (1){
		# Term Frequency
		my $te_obj = new TermExtract::Chasen;
		$te_obj->no_LR;
		$te_obj->use_TF;
		my @noun_list = $te_obj->get_imp_word($::project_obj->file_MorphoOut_o);
		foreach my $i (@noun_list){
			next if $i->[0] =~ /^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+分)*(\d+秒)*$/; # 日付・時刻
			next if $i->[0] =~ /^\d+$/;  # 数値のみ
			next if $is_alone{$i->[0]};  # 単名詞
			$i_tf{$i->[0]} = $i->[1];
		}
		undef $te_obj;
		undef @noun_list;
		print "done: TF\n" if $debug;

		# Frequency
		$te_obj = new TermExtract::Chasen;
		$te_obj->no_LR;
		$te_obj->use_frq;
		@noun_list = $te_obj->get_imp_word($::project_obj->file_MorphoOut_o);
		foreach my $i (@noun_list){
			next unless $i_tf{$i->[0]};
			$i_frq{$i->[0]} = $i->[1];
		}
		undef $te_obj;
		undef @noun_list;
		print "done: F\n" if $debug;

		# 延べ数の取得
		$te_obj = new TermExtract::Chasen;
		$te_obj->use_total;
		$te_obj->no_frq;
		@noun_list = $te_obj->get_imp_word($::project_obj->file_MorphoOut_o);
		foreach my $i (@noun_list){
			next unless $i_tf{$i->[0]};
			$i_total{$i->[0]} = $i->[1];
		}
		undef $te_obj;
		undef @noun_list;
		print "done: Total\n" if $debug;

		# 異なり数の取得
		$te_obj = new TermExtract::Chasen;
		$te_obj->use_uniq;
		$te_obj->no_frq;
		@noun_list = $te_obj->get_imp_word($::project_obj->file_MorphoOut_o);
		foreach my $i (@noun_list){
			next unless $i_tf{$i->[0]};
			$i_uniq{$i->[0]} = $i->[1];
		}
		undef $te_obj;
		undef @noun_list;
		print "done: Uniq\n" if $debug;

		# パープレキシティの取得
		$te_obj = new TermExtract::Chasen;
		$te_obj->use_Perplexity;
		$te_obj->no_frq;
		@noun_list = $te_obj->get_imp_word($::project_obj->file_MorphoOut_o);
		foreach my $i (@noun_list){
			next unless $i_tf{$i->[0]};
			$i_ppl{$i->[0]} = $i->[1];
		}
		undef $te_obj;
		undef @noun_list;
		print "done: PPL\n" if $debug;
	}

	# 選択された指標を計算
	my $te_obj = new TermExtract::Chasen;
	my @noun_list = $te_obj->get_imp_word($::project_obj->file_MorphoOut_o);
	print "done: Select\n" if $debug;
	
	# 出力
	open (OUT,">hoge.csv") or die;
	print OUT 'キーワード,重要度,Term Frequency,Frequency,延べ数,異なり数,Perplexity',"\n";
	foreach (@noun_list) {
		next if $_->[0] =~ /^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+分)*(\d+秒)*$/; # 日付・時刻
		next if $_->[0] =~ /^\d+$/;  # 数値のみ
		next if $is_alone{$_->[0]};  # 単名詞

		# 結果表示（$output_modeに応じて、出力様式を変更
		print OUT
			"$_->[0]",",",
			"$_->[1],",
			"$i_tf{$_->[0]},",
			"$i_frq{$_->[0]},",
			"$i_total{$_->[0]},",
			"$i_uniq{$_->[0]},",
			"$i_ppl{$_->[0]}\n"
		;
	}
	close (OUT);
	kh_jchar->to_sjis("hoge.csv") if $::config_obj->os eq 'win32';
	
	print "ok!!\n";
}

#--------------#
#   アクセサ   #

sub win_name{
	return 'w_use_te_g';
}
1;