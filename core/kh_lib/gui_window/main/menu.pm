package gui_window::main::menu;
use strict;

#------------------#
#   メニュー作成   #
#------------------#

sub make{
	my $class = shift;
	my $gui   = shift;
	my $self;
	
	my $mw = ${$gui}->mw;
	my $toplevel = $mw->toplevel;
	my $menubar = $toplevel->Menu(-type => 'menubar');
	$toplevel->configure(-menu => $menubar);


	#------------------#
	#   プロジェクト   #
	
	my $msg = Jcode->new('プロジェクト(P)','euc')->sjis;
	my $f = $menubar->cascade(
		-label => "$msg",
		-font => "TKFN",
		-underline => $::config_obj->underline_conv(13),
		-tearoff=>'no'
	);

		$msg = Jcode->new('新規','euc')->sjis;
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command =>
				sub{ $mw->after(10,sub{gui_window::project_new->open;});},
			-accelerator => 'Ctrl+N'
		);
		$msg = Jcode->new('開く','euc')->sjis;
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command =>
				sub{ $mw->after(10,sub{gui_window::project_open->open;});},
			-accelerator => 'Ctrl+O'
		);
		$self->{m_b0_close} = $f->command(
			-label => Jcode->new('閉じる')->sjis,
			-font => "TKFN",
			-state => 'disable',
			-command =>
				sub{ $mw->after(10,sub{
					$::main_gui->close_all;
					undef $::project_obj;
					$::main_gui->menu->refresh;
					$::main_gui->inner->refresh;
				});},
		);
		
		
		$f->separator();
		$msg = Jcode->new('設定','euc')->sjis;
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command => 
				sub{ $mw->after(10,sub{gui_window::sysconfig->open;});},
		);
		$f->separator();
		$msg = Jcode->new('終了','euc')->sjis;
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command => sub{ $mw->after(10,sub{exit;});},
			-accelerator => 'Ctrl+Q'
		);

	#------------#
	#   前処理   #
	
	$f = $menubar->cascade(
		-label => Jcode->new('前処理(B)')->sjis,
		-font => "TKFN",
		-underline => $::config_obj->underline_conv(7),
		-tearoff=>'no'
	);

		$self->{m_b2_morpho} = $f->command(
				-label => Jcode->new('前処理の実行')->sjis,
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					
					my $w = gui_wait->start;
					kh_morpho->run;
					mysql_ready->first;
					$::project_obj->status_morpho(1);
					$w->end;
					$::main_gui->menu->refresh;
					$::main_gui->inner->refresh;
				})},
				-state => 'disable'
			);
		$f->separator();
		$self->{m_b1_mark} = $f->command(
				-label => Jcode->new('語の取捨選択')->sjis,
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::dictionary->open;
				})},
				-state => 'disable'
			);

		$self->{m_b3_check} = $f->command(
				-label => Jcode->new('形態素解析結果の確認')->sjis,
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::morpho_check->open;
				})},
				-state => 'disable'
			);

	#------------#
	#   ツール   #

	$f = $menubar->cascade(
		-label => Jcode->new('ツール(T)')->sjis,
		-font => "TKFN",
		-underline => $::config_obj->underline_conv(7),
		-tearoff=>'no'
	);

	my $f3 = $f->cascade(
			-label => Jcode->new('抽出語')->sjis,
			 -font => "TKFN",
			 -tearoff=>'no'
		);

		$self->{t_word_search} = $f3->command(
				-label => Jcode->new('検索')->sjis,
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::word_search->open;
				})},
				-state => 'disable'
			);

		$self->{t_word_conc} = $f3->command(
				-label => Jcode->new('コンコーダンス [KWIC]')->sjis,
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::word_conc->open;
				})},
				-state => 'disable'
			);
		$f3->separator();

		$self->{t_word_list} = $f3->command(
				-label => Jcode->new('品詞別 出現回数順 リスト')->sjis,
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					my $target = $::project_obj->file_WordList;
					mysql_words->csv_list($target);
					gui_OtherWin->open($target);
				})},
				-state => 'disable'
			);

		$f3->separator();
		
		$self->{t_word_freq} = $f3->command(
				-label => Jcode->new('出現回数 分布 (SPSS)')->sjis,
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					my $target = $::project_obj->file_WordFreq;
					mysql_words->spss_freq($target);
					gui_OtherWin->open($target);
				})},
				-state => 'disable'
			);
		


		#$self->{t_word_print} = $f3->command(
		#		-label => Jcode->new('リストの印刷（LaTeX）')->sjis,
		#		-font => "TKFN",
		#		-command => sub {$mw->after(10,sub{
		#			mysql_words->make_list();
		#		})},
		#		-state => 'disable'
		#	);


	my $f2 = $f->cascade(
			-label => Jcode->new('SQLコマンド入力')->sjis,
			 -font => "TKFN",
			 -tearoff=>'no'
		);
	
		$self->{t_sql_select} = $f2->command(
				-label => Jcode->new('SELECT')->sjis,
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::sql_select->open;
				})},
				-state => 'disable'
			);

		$self->{t_sql_do} = $f2->command(
				-label => Jcode->new('その他')->sjis,
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::sql_do->open;
				})},
				-state => 'disable'
			);



	#------------#
	#   ヘルプ   #
	
	$msg = Jcode->new('ヘルプ(H)','euc')->sjis;
	$f = $menubar->cascade(
		-label => "$msg",
		-font => "TKFN",
		-underline => $::config_obj->underline_conv(7),
		-tearoff=>'no'
	);
	
		$msg = Jcode->new('使用説明書（PDF形式）','euc')->sjis;
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command => sub{ $mw->after
				(
					10,
					sub { gui_OtherWin->open('kh_coder_manual.pdf'); }
				);
			},
		);
		
		$msg = Jcode->new('最新情報','euc')->sjis;
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command =>sub{ $mw->after
				(
					10,
					sub {
					 gui_OtherWin->open('http://koichi.nihon.to/psnl/khcoder');
					}
				);
			},
		);
		
		$msg = Jcode->new('KH Coder II について','euc')->sjis;
		$f->command(
			-label => $msg,
			-command => sub{ $mw->after(10, sub{gui_window::about->open;});},
			-font => "TKFN"
		);

	#--------------------#
	#   キー・バインド   #
	
	$mw->bind(
		'<Control-Key-o>',
		sub{ $mw->after(10,sub{gui_window::project_open->open;});}
	);
	$mw->bind(
		'<Control-Key-n>',
		sub{ $mw->after(10,sub{gui_window::project_new->open;});}
	);

	bless $self, $class;
	return $self;
}

#------------------------#
#   メニューの状態変更   #
#------------------------#
sub refresh{
	my $self = shift;
	$self->disable_all;
	
	
	# プロジェクトが選択されればActive
	my @menu0 = (
		'm_b1_mark',
		'm_b2_morpho',
		't_sql_select',
		't_sql_do',
		'm_b0_close',
	);

	# 形態素解析が行われていればActive
	my @menu1 = (
		't_word_search',
		# 't_word_print',
		't_word_list',
		't_word_freq',
		't_word_conc',
		'm_b3_check',
	);

	# 状態変更
	if ($::project_obj){
		$self->normalize(\@menu0);
		if ($::project_obj->status_morpho){
			$self->normalize(\@menu1);
		}
	}

}

sub normalize{
	my $self = shift;
	foreach my $i (@{$_[0]}){
		$self->{$i}->configure(-state,'normal');
	}
}


# 全てDisable
sub disable_all{
	my $self = shift;
	foreach my $i (keys %{$self}){
		if (substr($i,0,2) eq 'm_' || substr($i,0,2) eq 't_'){
			$self->{$i}->configure(-state, 'disable');
		}
	}
}

1;
