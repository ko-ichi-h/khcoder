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

	# 形態素解析
	
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
	
	kh_morpho->run;

	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_euc($::project_obj->file_MorphoOut);
			my $ta2 = new Benchmark;
	}

	# フィルタリング用に単名詞のリストを作成
	my %is_alone = ();
	open (CHASEN,$::project_obj->file_MorphoOut) or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $::project_obj->file_MorphoOut
			);
	while (<CHASEN>){
		$is_alone{(split /\t/, $_)[0]} = 1;
	}
	close (CHASEN);

	# TermExtractの実行
	use TermExtract::Chasen;
	my $te_obj = new TermExtract::Chasen;
	my @noun_list = $te_obj->get_imp_word($::project_obj->file_MorphoOut);

	# 出力
	my $target_csv = $::project_obj->file_HukugoListTE;
	open (OUT,">$target_csv") or
		gui_errormsg->open(
			type => 'file',
			thefile => $target_csv
		);;
	print OUT "キーワード,重要度\n";

	foreach (@noun_list) {
		next if $is_alone{$_->[0]};  # 単名詞
		next if $_->[0] =~ /^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+分)*(\d+秒)*$/; # 日付・時刻
		my $tmp = Jcode->new($_->[0], 'euc')->tr('０-９','0-9'); # 数値のみ
		next if $tmp =~ /^\d+$/;

		print OUT
			kh_csv->value_conv($_->[0]),
			",$_->[1]\n"
		;
	}
	close (OUT);
	kh_jchar->to_sjis("$target_csv") if $::config_obj->os eq 'win32';
	print "ok!!\n";
	gui_OtherWin->open($target_csv);
}

#--------------#
#   アクセサ   #

sub win_name{
	return 'w_use_te_g';
}
1;