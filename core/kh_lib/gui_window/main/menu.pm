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
	#my $toplevel = $mw->toplevel;
	my $menubar = $mw->Menu(-type => 'menubar');
	$mw->configure(-menu => $menubar);

	#------------------#
	#   プロジェクト   #

	#my $msg = gui_window->gui_jchar('プロジェクト(P)','euc');
	my $msg = Jcode->new('プロジェクト(P)','euc')->sjis;
	my $f = $menubar->cascade(
		-label => "$msg",
		-font => "TKFN",
		#-underline => $::config_obj->underline_conv(13),
		-tearoff=>'no'
	);

		$msg = gui_window->gui_jchar('新規','euc');
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command =>
				sub{ $mw->after(10,sub{gui_window::project_new->open;});},
			-accelerator => 'Ctrl+N'
		);
		$msg = gui_window->gui_jchar('開く','euc');
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command =>
				sub{ $mw->after(10,sub{gui_window::project_open->open;});},
			-accelerator => 'Ctrl+O'
		);
		$self->{m_b0_close} = $f->command(
			-label => gui_window->gui_jchar('閉じる'),
			-font => "TKFN",
			-state => 'disable',
			-command =>
				sub{ $mw->after(10,sub{
					$::main_gui->close_all;
					undef $::project_obj;
					$::main_gui->menu->refresh;
					$::main_gui->inner->refresh;
				});},
			-accelerator => 'Ctrl+W'
		);
		
		
		$f->separator();
		$msg = gui_window->gui_jchar('設定','euc');
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command => 
				sub{ $mw->after(10,sub{gui_window::sysconfig->open;});},
		);
		$f->separator();
		$msg = gui_window->gui_jchar('終了','euc');
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command => sub{ $mw->after(10,sub{exit;});},
			-accelerator => 'ECS'
		);

	#------------#
	#   前処理   #
	
	$f = $menubar->cascade(
		-label => gui_window->gui_jchar('前処理(B)'),
		-font => "TKFN",
		-underline => $::config_obj->underline_conv(7),
		-tearoff=>'no'
	);

		$self->{m_b2_morpho} = $f->command(
				-label => gui_window->gui_jchar('前処理の実行'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					my $ans = $mw->messageBox(
						-message => gui_window->gui_jchar
							(
							   "時間のかかる処理を実行しようとしています。\n".
							   "続行してよろしいですか？"
							),
						-icon    => 'question',
						-type    => 'OKCancel',
						-title   => 'KH Coder'
					);
					unless ($ans =~ /ok/i){ return 0; }
					
					my $w = gui_wait->start;
					
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
				-label => gui_window->gui_jchar('語の取捨選択'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::dictionary->open;
				})},
				-state => 'disable'
			);

		$self->{m_b1_hukugo} = $f->command(
				-label => gui_window->gui_jchar('複合名詞のリスト（一部）'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					my $target = $::project_obj->file_HukugoList;
					unless (-e $target){
						my $ans = $mw->messageBox(
							-message => gui_window->gui_jchar
								(
								   "時間のかかる処理を実行しようとしています。"
								   ."（前処理よりは短時間で終了します）\n".
								   "続行してよろしいですか？"
								),
							-icon    => 'question',
							-type    => 'OKCancel',
							-title   => 'KH Coder'
						);
						unless ($ans =~ /ok/i){ return 0; }
						use mysql_hukugo;
						mysql_hukugo->run_from_morpho($target);
					}
					gui_OtherWin->open($target);
				})},
				-state => 'disable'
			);

		$f->separator();

		$self->{m_b3_check} = $f->command(
				-label => gui_window->gui_jchar('語の抽出結果を確認'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::morpho_check->open;
				})},
				-state => 'disable'
			);

	#------------#
	#   ツール   #

	$f = $menubar->cascade(
		-label => gui_window->gui_jchar('ツール(T)'),
		-font => "TKFN",
		-underline => $::config_obj->underline_conv(7),
		-tearoff=>'no'
	);

	my $f3 = $f->cascade(
			-label => gui_window->gui_jchar('抽出語'),
			 -font => "TKFN",
			 -tearoff=>'no'
		);

		$self->{t_word_search} = $f3->command(
				-label => gui_window->gui_jchar('抽出語検索'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::word_search->open;
				})},
				-state => 'disable'
			);

		$self->{t_word_conc} = $f3->command(
				-label => gui_window->gui_jchar('コンコーダンス（KWIC）'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::word_conc->open;
				})},
				-state => 'disable'
			);

		$f3->separator;
		
		$self->{t_word_freq} = $f3->command(
				-label => gui_window->gui_jchar('出現回数 分布'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::word_freq->open->count;
				})},
				-state => 'disable'
			);

		$self->{t_word_list} = $f3->command(
				-label => gui_window->gui_jchar('品詞別 出現回数順 リスト'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					my $target = $::project_obj->file_WordList;
					mysql_words->csv_list($target);
					gui_OtherWin->open($target);
				})},
				-state => 'disable'
			);

	my $f8 = $f->cascade(
			-label => gui_window->gui_jchar('文書'),
			 -font => "TKFN",
			 -tearoff=>'no'
		);

		$self->{t_doc_search} = $f8->command(
				-label => gui_window->gui_jchar('文書検索'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::doc_search->open;
				})},
				-state => 'disable'
			);

		$self->{t_word_ass} = $f8->command(
				-label => gui_window->gui_jchar('抽出語 連関規則'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::word_ass->open;
				})},
				-state => 'disable'
			);

		$f8->separator;

		$self->{m_b3_crossout} = $f8->cascade(
				-label => gui_window->gui_jchar("「文書ｘ抽出語」表の出力",'euc'),
				-font => "TKFN",
				-state => 'disable',
				-tearoff=>'no'
			);

			$self->{m_b3_crossout_csv} = $self->{m_b3_crossout}->command(
				-label => gui_window->gui_jchar("CSVファイル"),
				-font  => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::morpho_crossout::csv->open;
				})},
			);

			$self->{m_b3_crossout_spss} = $self->{m_b3_crossout}->command(
				-label => gui_window->gui_jchar("SPSSファイル"),
				-font  => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::morpho_crossout::spss->open;
				})},
			);

			$self->{m_b3_crossout_tab} = $self->{m_b3_crossout}->command(
				-label => gui_window->gui_jchar("タブ区切り"),
				-font  => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::morpho_crossout::tab->open;
				})},
			);

		$self->{m_b3_contxtout} = $f8->cascade(
				-label => gui_window->gui_jchar("「抽出語ｘ文脈ベクトル」表の出力",'euc'),
				-font => "TKFN",
				-state => 'disable',
				-tearoff=>'no'
			);

			$self->{m_b3_contxtout_csv} = $self->{m_b3_contxtout}->command(
				-label => gui_window->gui_jchar("CSVファイル"),
				-font  => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::contxt_out::csv->open;
				})},
			);

			$self->{m_b3_contxtout_spss} = $self->{m_b3_contxtout}->command(
				-label => gui_window->gui_jchar("SPSSファイル"),
				-font  => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::contxt_out::spss->open;
				})},
			);

			$self->{m_b3_contxtout_tab} = $self->{m_b3_contxtout}->command(
				-label => gui_window->gui_jchar("タブ区切り"),
				-font  => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::contxt_out::tab->open;
				})},
			);

	my $f5 = $f->cascade(
			-label => gui_window->gui_jchar('コーディング'),
			 -font => "TKFN",
			 -tearoff=>'no'
		);

		$self->{t_cod_count} = $f5->command(
			-label => gui_window->gui_jchar('単純集計'),
			-font => "TKFN",
			-command => sub {$mw->after(10,sub{
					gui_window::cod_count->open;
				})},
			-state => 'disable'
		);

		$self->{t_cod_tab} = $f5->command(
			-label => gui_window->gui_jchar('章・節・段落ごとの集計'),
			-font => "TKFN",
			-command => sub {$mw->after(10,sub{
					gui_window::cod_tab->open;
				})},
			-state => 'disable'
		);

		$self->{t_cod_outtab} = $f5->command(
			-label => gui_window->gui_jchar('外部変数とのクロス集計'),
			-font => "TKFN",
			-command => sub {$mw->after(10,sub{
					gui_window::cod_outtab->open;
				})},
			-state => 'disable'
		);

		$self->{t_cod_jaccard} = $f5->command(
			-label => gui_window->gui_jchar('コード間関連'),
			-font => "TKFN",
			-command => sub {$mw->after(10,sub{
					gui_window::cod_jaccard->open;
				})},
			-state => 'disable'
		);

		$f5->separator();

		$self->{t_cod_out} = $f5->cascade(
			-label => gui_window->gui_jchar('コーディング結果の出力'),
			 -font => "TKFN",
			 -tearoff=>'no'
		);

			$self->{t_cod_out_csv} = $self->{t_cod_out}->command(
				-label => gui_window->gui_jchar('CSVファイル'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
						gui_window::cod_out::csv->open;
					})},
				-state => 'disable'
			);

			$self->{t_cod_out_spss} = $self->{t_cod_out}->command(
				-label => gui_window->gui_jchar('SPSSファイル'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
						gui_window::cod_out::spss->open;
					})},
				-state => 'disable'
			);

			$self->{t_cod_out_tab} = $self->{t_cod_out}->command(
				-label => gui_window->gui_jchar('タブ区切り'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
						gui_window::cod_out::tab->open;
					})},
				-state => 'disable'
			);

	$f->separator();
	
	my $f_out_var = $f->cascade(
		-label => gui_window->gui_jchar('外部変数'),
		 -font => "TKFN",
		 -tearoff=>'no'
	);

		$self->{t_out_read} = $f_out_var->cascade(
			-label => gui_window->gui_jchar('読み込み'),
			 -font => "TKFN",
			 -tearoff=>'no'
		);

			$self->{t_out_read_csv} = $self->{t_out_read}->command(
				-label => gui_window->gui_jchar('CSVファイル'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
						gui_window::outvar_read::csv->open;
					})},
				-state => 'disable'
			);

			$self->{t_out_read_tab} = $self->{t_out_read}->command(
				-label => gui_window->gui_jchar('タブ区切り'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
						gui_window::outvar_read::tab->open;
					})},
				-state => 'disable'
			);

		$self->{t_out_list} = $f_out_var->command(
			-label => gui_window->gui_jchar('変数リスト・値ラベル'),
			-font => "TKFN",
			-command => sub {$mw->after(10,sub{
					gui_window::outvar_list->open;
				})},
			-state => 'disable'
		);

	my $f6 = $f->cascade(
		-label => gui_window->gui_jchar('テキストファイルの変形'),
		 -font => "TKFN",
		 -tearoff=>'no'
	);

		$self->{t_txt_pickup} = $f6->command(
			-label => gui_window->gui_jchar('部分テキストの取り出し'),
			-font => "TKFN",
			-command => sub {$mw->after(10,sub{
					gui_window::txt_pickup->open;
				})},
			-state => 'disable'
		);

		$self->{t_txt_html2mod} = $f6->command(
			-label => gui_window->gui_jchar('HTMLからCSVに変換'),
			-font => "TKFN",
			-command => sub {$mw->after(10,sub{
					gui_window::txt_html2csv->open;
				})},
			-state => 'disable'
		);


	my $f2 = $f->cascade(
			-label => gui_window->gui_jchar('SQL文 入力'),
			 -font => "TKFN",
			 -tearoff=>'no'
		);
	
		$self->{t_sql_select} = $f2->command(
				-label => gui_window->gui_jchar('SELECT'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::sql_select->open;
				})},
				-state => 'disable'
			);

		$self->{t_sql_do} = $f2->command(
				-label => gui_window->gui_jchar('その他'),
				-font => "TKFN",
				-command => sub {$mw->after(10,sub{
					gui_window::sql_do->open;
				})},
				-state => 'disable'
			);



	#------------#
	#   ヘルプ   #
	
	$msg = gui_window->gui_jchar('ヘルプ(H)','euc');
	$f = $menubar->cascade(
		-label => "$msg",
		-font => "TKFN",
		-underline => $::config_obj->underline_conv(7),
		-tearoff=>'no'
	);
	
		$msg = gui_window->gui_jchar('使用説明書（PDF形式）','euc');
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command => sub{ $mw->after
				(
					10,
					sub { gui_OtherWin->open('khcoder_manual.pdf'); }
				);
			},
		);
		
		$msg = gui_window->gui_jchar('最新情報','euc');
		$f->command(
			-label => $msg,
			-font => "TKFN",
			-command =>sub{ $mw->after
				(
					10,
					sub {
					 gui_OtherWin->open('http://khc.sourceforge.net');
					}
				);
			},
		);
		
		$msg = gui_window->gui_jchar('KH Coderについて','euc');
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
	$mw->bind(
		'<Control-Key-w>',
		sub{ $mw->after(10,sub{
					$::main_gui->close_all;
					undef $::project_obj;
					$::main_gui->menu->refresh;
					$::main_gui->inner->refresh;
				});}
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
		'm_b1_hukugo',
	);

	# 形態素解析が行われていればActive
	my @menu1 = (
		't_word_search',
		't_word_list',
		't_word_freq',
		't_word_ass',
		't_word_conc',
		'm_b3_check',
		't_cod_count',
		't_cod_tab',
		't_cod_jaccard',
		't_cod_out',
		't_cod_outtab',
		't_cod_out_spss',
		't_cod_out_csv',
		't_cod_out_tab',
		't_txt_html2mod',
		'm_b3_crossout',
		'm_b3_crossout_csv',
		'm_b3_crossout_spss',
		'm_b3_crossout_tab',
		't_txt_pickup',
		't_doc_search',
		't_out_read',
		't_out_read_csv',
		't_out_read_tab',
		't_out_list',
		'm_b3_contxtout',
		'm_b3_contxtout_spss',
		'm_b3_contxtout_csv',
		'm_b3_contxtout_tab',
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
