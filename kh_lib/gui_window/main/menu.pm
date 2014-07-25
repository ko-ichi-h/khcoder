package gui_window::main::menu;

use strict;
use Tk;

# メニューの設定：プロジェクトが選択されればActive
my @menu0 = (
	'm_b1_mark',
	'm_b2_morpho',
	't_sql_select',
	'm_b0_close',
	#'m_b1_hukugo',
	#'m_b1_hukugo_te',
	#'m_b2_datacheck',
);

# メニューの設定：形態素解析が行われていればActive
my @menu1 = (
	't_word_search',
	#'t_word_list',
	't_word_list_cf',
	't_word_freq',
	't_word_df_freq',
	't_word_ass',
	't_word_conc',
	'm_b3_check',
	't_cod_count',
	#'t_cod_tab',
	't_cod_jaccard',
	#'t_cod_multi',
	't_cod_out',
	't_cod_outtab',
	't_cod_out_spss',
	't_cod_out_csv',
	't_cod_out_tab',
	't_cod_out_var',
	't_txt_html2mod',
	'm_b3_crossout',
	'm_b3_crossout_csv',
	'm_b3_crossout_spss',
	'm_b3_crossout_tab',
	'm_b3_crossout_var',
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
	'm_b0_export',
	't_cas_bayes',
	't_bayes_learn',
	't_bayes_predict',
	't_bayes_view',
	't_bayes_view_log',
);


#------------------#
#   メニュー作成   #
#------------------#

sub make{
	my $class = shift;
	my $mw    = shift;
	my $self;
	
	#my $menubar = $mw->Menu(-type => 'menubar');
	my $menubar = $mw->Menu();
	$mw->configure(-menu => $menubar);

	#------------------#
	#   プロジェクト   #

	my $msg = gui_window->gui_jm( kh_msg->get('project') );
	my $f1 = $menubar->cascade(
		-label => $msg,
		-font => "TKFN",
		-underline => index($msg, 'P'),
		-tearoff=>'no'
	);

		my $m4a_project = $f1->command(
			-label => kh_msg->get('new'),
			-font => "TKFN",
			-command =>
				sub{gui_window::project_new->open;},
			-accelerator => 'Ctrl+N'
		);
		$f1->command(
			-label => kh_msg->get('open'),
			-font => "TKFN",
			-command =>
				sub{gui_window::project_open->open;},
			-accelerator => 'Ctrl+O'
		);
		$self->{m_b0_close} = $f1->command(
			-label => kh_msg->get('close'),
			-font => "TKFN",
			-state => 'disable',
			-command =>
				sub{
						$self->mc_close_project;
					},
			-accelerator => 'Ctrl+W'
		);
		
		$f1->separator();

		$f1->command(
			-label => kh_msg->get('import'),
			-font => "TKFN",
			-command =>
				sub{
						$self->mc_import_project;
					},
		);

		$self->{m_b0_export} = $f1->command(
			-label => kh_msg->get('export'),
			-font => "TKFN",
			-state => 'disable',
			-command =>
				sub{
						$self->mc_export_project;
					},
		);

		$f1->separator();
		
		$f1->command(
			-label => kh_msg->get('config'),
			-font => "TKFN",
			-command => 
				sub{gui_window::sysconfig->open;},
		);
		#$f->separator();
		
		$f1->command(
			-label => kh_msg->get('exit'),
			-font => "TKFN",
			-command => sub{
						$::main_gui->get('main_window')->close or exit;
					},
			-accelerator => 'Ctrl+Q'
		);

	#------------#
	#   前処理   #

	my $f = $menubar->cascade(
		-label => gui_window->gui_jm( kh_msg->get('prep') ),
		-font => "TKFN",
		-underline => index(kh_msg->get('prep'), 'R'),
		-tearoff=>'no'
	);

		$self->{m_b2_datacheck} = $f->command(
				-label => kh_msg->get('check'),
				-font => "TKFN",
				-command => sub{
					my $ans = $mw->messageBox(
						-message => kh_msg->gget('cont_big_pros'),
						-icon    => 'question',
						-type    => 'OKCancel',
						-title   => 'KH Coder'
					);
					unless ($ans =~ /ok/i){ return 0; }
					$self->mc_datacheck;
				},
				-state => 'disable'
			);

		$self->{m_b2_morpho} = $f->command(
				-label => kh_msg->get('run_prep'),
				-font => "TKFN",
				-command => sub{
					my $ans = $mw->messageBox(
						-message => kh_msg->gget('cont_big_pros'),
						-icon    => 'question',
						-type    => 'OKCancel',
						-title   => 'KH Coder'
					);
					unless ($ans =~ /ok/i){ return 0; }
					$self->mc_morpho;
				},
				-state => 'disable'
			);
		$f->separator();
		$self->{m_b1_mark} = $f->command(
				-label => kh_msg->get('words_selection'),
				-font => "TKFN",
				-command => sub{
					gui_window::dictionary->open;
				},
				-state => 'disable'
			);

		my $f_hukugo = $f->cascade(
				-label => kh_msg->get('words_cluster'),
				-font => "TKFN",
				-tearoff=>'no'
			);

		$self->{m_b1_hukugo_te} = $f_hukugo->command(
				-label => kh_msg->get('use_termextract'),
				-font => "TKFN",
				-command => sub{
						gui_window::use_te->open;
				},
				-state => 'disable'
			);

		$self->{m_b1_hukugo} = $f_hukugo->command(
				-label => kh_msg->get('use_chasen'), #gui_window->gui_jchar('茶筌による連結'),
				-font => "TKFN",
				-command => sub{
					$self->mc_hukugo;
				},
				-state => 'disable'
			);

		$f->separator();

		$self->{m_b3_check} = $f->command(
				-label => kh_msg->get('check_morpho'), #gui_window->gui_jchar('語の抽出結果を確認'),
				-font => "TKFN",
				-command => sub{
					gui_window::morpho_check->open;
				},
				-state => 'disable'
			);

	#------------#
	#   ツール   #

	$f = $menubar->cascade(
		-label => gui_window->gui_jm( kh_msg->get('tools') ),
		-font => "TKFN",
		-underline => index(kh_msg->get('tools'),'T'),
		-tearoff=>'no'
	);

	my $f3 = $f->cascade(
			-label => kh_msg->get('words'),#gui_window->gui_jchar('抽出語'),
			-font => "TKFN",
			-tearoff=>'no'
		);

		$self->{t_word_list_cf} = $f3->command(
				-label => kh_msg->get('word_freq'), #gui_window->gui_jchar('抽出語リスト'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_list->open;
				},
				-state => 'disable'
			);

		my $f_wd_stats = $f3->cascade(
			-label => kh_msg->get('desc_stats'),
			-font => "TKFN",
			-tearoff=>'no'
		);
		
		$self->{t_word_freq} = $f_wd_stats->command(
				-label => kh_msg->get('freq_tf'),#gui_window->gui_jchar('出現回数の分布'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_freq->open->count;
				},
				-state => 'disable'
			);

		$self->{t_word_df_freq} = $f_wd_stats->command(
				-label => kh_msg->get('freq_df'),#gui_window->gui_jchar('文書数の分布'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_df_freq->open->count;
				},
				-state => 'disable'
			);

		$self->{t_word_tf_df} = $f_wd_stats->command(
				-label => kh_msg->get('tf_df'),#gui_window->gui_jchar('出現回数ｘ文書数のプロット'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_tf_df->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_word_tf_df' if $::config_obj->R;

		$f3->separator;

		$self->{t_word_search} = $f3->command(
				-label => kh_msg->get('word_search'),#gui_window->gui_jchar('抽出語検索'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_search->open;
				},
				-state => 'disable'
			);

		$self->{t_word_conc} = $f3->command(
				-label => kh_msg->get('kwic'),#gui_window->gui_jchar('KWICコンコーダンス'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_conc->open;
				},
				-state => 'disable'
			);

		$self->{t_word_ass} = $f3->command(
				-label => kh_msg->get('word_ass'),#gui_window->gui_jchar('関連語探索'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_ass->open;
				},
				-state => 'disable'
			);

		$f3->separator;

		$self->{t_word_corresp} = $f3->command(
				-label => kh_msg->get('corresp'),#gui_window->gui_jchar('対応分析'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_corresp->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_word_corresp' if $::config_obj->R;

		$self->{t_word_mds} = $f3->command(
				-label => kh_msg->get('mds'),#gui_window->gui_jchar('多次元尺度構成法'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_mds->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_word_mds' if $::config_obj->R;

		$self->{t_word_cls} = $f3->command(
				-label => kh_msg->get('h_cluster'),#gui_window->gui_jchar('階層的クラスター分析'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_cls->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_word_cls' if $::config_obj->R;

		$self->{t_word_netgraph} = $f3->command(
				-label => kh_msg->get('netg'),#gui_window->gui_jchar('共起ネットワーク'),
				-font => "TKFN",
				-command => sub{
					gui_window::word_netgraph->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_word_netgraph' if $::config_obj->R;

		$self->{t_word_som} = $f3->command(
				-label => kh_msg->get('som'), # 自己組織化マップ
				-font => "TKFN",
				-command => sub{
					gui_window::word_som->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_word_som' if $::config_obj->R;

	my $f8 = $f->cascade(
			-label => kh_msg->get('docs'),#gui_window->gui_jchar('文書'),
			-font => "TKFN",
			-tearoff=>'no'
		);

		$self->{t_doc_search} = $f8->command(
				-label => kh_msg->get('doc_search'),#gui_window->gui_jchar('文書検索'),
				-font => "TKFN",
				-command => sub{
					gui_window::doc_search->open;
				},
				-state => 'disable'
			);

		$self->{t_doc_cls} = $f8->command(
				-label => kh_msg->get('cluster'),#gui_window->gui_jchar('クラスター分析'),
				-font => "TKFN",
				-command => sub{
					gui_window::doc_cls->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_doc_cls' if $::config_obj->R;

		$self->{t_cas_bayes} = $f8->cascade(
			-label => kh_msg->get('docs_bayes'),#gui_window->gui_jchar('ベイズ学習による分類'),
			 -font => "TKFN",
			 -tearoff=>'no'
		);

		$self->{t_bayes_learn} = $self->{t_cas_bayes}->command(
			-label => kh_msg->get('bayes_learn'),#gui_window->gui_jchar('外部変数から学習'),
			-font => "TKFN",
			-command => sub{
				gui_window::bayes_learn->open;
			},
			-state => 'disable'
		);

		$self->{t_bayes_predict} = $self->{t_cas_bayes}->command(
			-label => kh_msg->get('bayes_classi'),#gui_window->gui_jchar('学習結果を用いた自動分類'),
			-font => "TKFN",
			-command => sub{
				gui_window::bayes_predict->open;
			},
			-state => 'disable'
		);

		$self->{t_cas_bayes}->separator;

		$self->{t_bayes_view} = $self->{t_cas_bayes}->command(
			-label => kh_msg->get('check_learning'),#gui_window->gui_jchar('学習結果ファイルの内容を確認'),
			-font => "TKFN",
			-command => sub{
				$self->mc_view_knb;
			},
			-state => 'disable'
		);

		$self->{t_bayes_view_log} = $self->{t_cas_bayes}->command(
			-label => kh_msg->get('check_classi'),#gui_window->gui_jchar('分類ログファイルの内容を確認'),
			-font => "TKFN",
			-command => sub{
				$self->mc_view_nbl;
			},
			-state => 'disable'
		);

		$f8->separator;

		$self->{m_b3_crossout} = $f8->cascade(
				-label => kh_msg->get('doc_term_mtrx'),#gui_window->gui_jchar("「文書ｘ抽出語」表の出力",'euc'),
				-font => "TKFN",
				-state => 'disable',
				-tearoff=>'no'
			);

			$self->{m_b3_crossout_csv} = $self->{m_b3_crossout}->command(
				-label => kh_msg->gget('csv_f'),#gui_window->gui_jchar("CSVファイル"),
				-font  => "TKFN",
				-command => sub{
					gui_window::morpho_crossout::csv->open;
				},
			);

			$self->{m_b3_crossout_spss} = $self->{m_b3_crossout}->command(
				-label => kh_msg->gget('spss_f'),#gui_window->gui_jchar("SPSSファイル"),
				-font  => "TKFN",
				-command => sub{
					gui_window::morpho_crossout::spss->open;
				},
			);

			$self->{m_b3_crossout_tab} = $self->{m_b3_crossout}->command(
				-label => kh_msg->gget('tab_f'),#gui_window->gui_jchar("タブ区切り"),
				-font  => "TKFN",
				-command => sub{
					gui_window::morpho_crossout::tab->open;
				},
			);

			$self->{m_b3_crossout}->separator;

			$self->{m_b3_crossout_var} = $self->{m_b3_crossout}->command(
				-label => kh_msg->gget('wm_f'),#gui_window->gui_jchar("不定長CSV （WordMiner）"),
				-font  => "TKFN",
				-command => sub{
					gui_window::morpho_crossout::var->open;
				},
			);

		$self->{m_b3_contxtout} = $f8->cascade(
				-label => kh_msg->get('term_vec_mtrx'),#gui_window->gui_jchar("「抽出語ｘ文脈ベクトル」表の出力",'euc'),
				-font => "TKFN",
				-state => 'disable',
				-tearoff=>'no'
			);

			$self->{m_b3_contxtout_csv} = $self->{m_b3_contxtout}->command(
				-label => kh_msg->gget('csv_f'),
				-font  => "TKFN",
				-command => sub{
					gui_window::contxt_out::csv->open;
				},
			);

			$self->{m_b3_contxtout_spss} = $self->{m_b3_contxtout}->command(
				-label => kh_msg->gget('spss_f'),
				-font  => "TKFN",
				-command => sub{
					gui_window::contxt_out::spss->open;
				},
			);

			$self->{m_b3_contxtout_tab} = $self->{m_b3_contxtout}->command(
				-label => kh_msg->gget('tab_f'),
				-font  => "TKFN",
				-command => sub{
					gui_window::contxt_out::tab->open;
				},
			);

	my $f5 = $f->cascade(
			-label => kh_msg->get('coding'),#gui_window->gui_jchar('コーディング'),
			 -font => "TKFN",
			 -tearoff=>'no'
		);

		$self->{t_cod_count} = $f5->command(
			-label => kh_msg->get('freq'),#gui_window->gui_jchar('単純集計'),
			-font => "TKFN",
			-command => sub{
					gui_window::cod_count->open;
				},
			-state => 'disable'
		);

		#$self->{t_cod_tab} = $f5->command(
		#	-label => kh_msg->get('cross_st'),#gui_window->gui_jchar('章・節・段落ごとの集計'),
		#	-font => "TKFN",
		#	-command => sub{
		#			gui_window::cod_tab->open;
		#		},
		#	-state => 'disable'
		#);

		$self->{t_cod_outtab} = $f5->command(
			-label => kh_msg->get('cross_vr'),#gui_window->gui_jchar('外部変数とのクロス集計'),
			-font => "TKFN",
			-command => sub{
					gui_window::cod_outtab->open;
				},
			-state => 'disable'
		);

		$self->{t_cod_jaccard} = $f5->command(
			-label => kh_msg->get('jac_mtrx'),#gui_window->gui_jchar('類似度行列'),
			-font => "TKFN",
			-command => sub{
					gui_window::cod_jaccard->open;
				},
			-state => 'disable'
		);

		$f5->separator();

		$self->{t_cod_corresp} = $f5->command(
				-label => kh_msg->get('corresp'),#gui_window->gui_jchar('対応分析'),
				-font => "TKFN",
				-command => sub{
					gui_window::cod_corresp->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_cod_corresp' if $::config_obj->R;

		#$self->{t_cod_multi} = $f5->cascade(
		#	-label => gui_window->gui_jchar('コード間関連'),
		#	 -font => "TKFN",
		#	 -tearoff=>'no'
		#);

		$self->{t_cod_mds} = $f5->command(
				-label => kh_msg->get('mds'),#gui_window->gui_jchar('多次元尺度構成法'),
				-font => "TKFN",
				-command => sub{
					gui_window::cod_mds->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_cod_mds' if $::config_obj->R;

		$self->{t_cod_cls} = $f5->command(
				-label => kh_msg->get('h_cluster'),
				-font => "TKFN",
				-command => sub{
					gui_window::cod_cls->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_cod_cls' if $::config_obj->R;

		$self->{t_cod_netg} = $f5->command(
				-label => kh_msg->get('netg'),#gui_window->gui_jchar('共起ネットワーク'),
				-font => "TKFN",
				-command => sub{
					gui_window::cod_netg->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_cod_netg' if $::config_obj->R;

		$self->{t_cod_som} = $f5->command(
				-label => kh_msg->get('som'), # 自己組織化マップ
				-font => "TKFN",
				-command => sub{
					gui_window::cod_som->open;
				},
				-state => 'disable'
			);
		push @menu1, 't_cod_som' if $::config_obj->R;

		$f5->separator();

		$self->{t_cod_out} = $f5->cascade(
			-label => kh_msg->get('output_cod'),#gui_window->gui_jchar('コーディング結果の出力'),
			 -font => "TKFN",
			 -tearoff=>'no'
		);

			$self->{t_cod_out_csv} = $self->{t_cod_out}->command(
				-label => kh_msg->gget('csv_f'),#gui_window->gui_jchar('CSVファイル'),
				-font => "TKFN",
				-command => sub{
						gui_window::cod_out::csv->open;
					},
				-state => 'disable'
			);

			$self->{t_cod_out_spss} = $self->{t_cod_out}->command(
				-label => kh_msg->gget('spss_f'),#gui_window->gui_jchar('SPSSファイル'),
				-font => "TKFN",
				-command => sub{
						gui_window::cod_out::spss->open;
					},
				-state => 'disable'
			);

			$self->{t_cod_out_tab} = $self->{t_cod_out}->command(
				-label => kh_msg->gget('tab_f'),#gui_window->gui_jchar('タブ区切り'),
				-font => "TKFN",
				-command => sub{
						gui_window::cod_out::tab->open;
					},
				-state => 'disable'
			);

			$self->{t_cod_out}->separator();

			$self->{t_cod_out_var} = $self->{t_cod_out}->command(
				-label => kh_msg->gget('wm_f'),#gui_window->gui_jchar('不定長CSV （WordMiner）'),
				-font => "TKFN",
				-command => sub{
						gui_window::cod_out::var->open;
					},
				-state => 'disable'
			);

	$f->separator();
	
	my $f_out_var = $f->cascade(
		-label => kh_msg->get('vars_heads'),#gui_window->gui_jchar('外部変数と見出し'),
		 -font => "TKFN",
		 -tearoff=>'no'
	);

		$self->{t_out_read} = $f_out_var->cascade(
			-label => kh_msg->get('read'),#gui_window->gui_jchar('読み込み'),
			 -font => "TKFN",
			 -tearoff=>'no'
		);

			$self->{t_out_read_csv} = $self->{t_out_read}->command(
				-label => kh_msg->gget('csv_f'),#gui_window->gui_jchar('CSVファイル'),
				-font => "TKFN",
				-command => sub{
						gui_window::outvar_read::csv->open;
					},
				-state => 'disable'
			);

			$self->{t_out_read_tab} = $self->{t_out_read}->command(
				-label => kh_msg->gget('tab_f'),#gui_window->gui_jchar('タブ区切り'),
				-font => "TKFN",
				-command => sub{
						gui_window::outvar_read::tab->open;
					},
				-state => 'disable'
			);

		$self->{t_out_list} = $f_out_var->command(
			-label => kh_msg->get('var_list'),#gui_window->gui_jchar('リストの確認・管理'),
			-font => "TKFN",
			-command => sub{
					gui_window::outvar_list->open;
				},
			-state => 'disable'
		);

	my $f6 = $f->cascade(
		-label => kh_msg->get('text_format'),#gui_window->gui_jchar('テキストファイルの変形'),
		 -font => "TKFN",
		 -tearoff=>'no'
	);

		$self->{t_txt_pickup} = $f6->command(
			-label => kh_msg->get('partial'),#gui_window->gui_jchar('部分テキストの取り出し'),
			-font => "TKFN",
			-command => sub{
					gui_window::txt_pickup->open;
				},
			-state => 'disable'
		);

		$self->{t_txt_html2mod} = $f6->command(
			-label => kh_msg->get('to_csv'),#gui_window->gui_jchar('HTMLからCSVに変換'),
			-font => "TKFN",
			-command => sub{
					gui_window::txt_html2csv->open;
				},
			-state => 'disable'
		);


	# プラグインの読み込み
	$f->separator();
	my $f_p = $f->cascade(
			-label => kh_msg->get('plugin'),#gui_window->gui_jchar('プラグイン'),
			-font => "TKFN",
			-tearoff=>'no'
		);

	my @plugins;
	my $read_each = sub {
		return if(-d $File::Find::name);
		return unless $_ =~ /.+\.pm/;
		substr($_, length($_) - 3, length($_)) = '';
		push @plugins, $_;
	};
	use File::Find;
	push @INC, $::config_obj->cwd.'/plugin_'.$::config_obj->msg_lang;
	find($read_each, $::config_obj->cwd.'/plugin_'.$::config_obj->msg_lang);

	foreach (@plugins){
		unless (eval "use $_; 1"){
			my $err = $@;
			gui_errormsg->open(
				type => 'msg',
				msg  => "plugin error at ".$_.".pm\n\nerror: \n$err"
			);
			print "$err\n";
			return 0;
		}
		my $conf = $_->plugin_config;
		unless ( defined($conf) ){
			next;
		}
		
		my $cu = $_;
		my $mother = $f_p;
		
		# グループ指定に対応
		if ( length($conf->{menu_grp}) ){
			unless ( $self->{plugin_cascades}{$conf->{menu_grp}} ){
				$self->{plugin_cascades}{$conf->{menu_grp}} = $f_p->cascade(
					-label   => gui_window->gui_jchar($conf->{menu_grp}),
					-font    => "TKFN",
					-tearoff =>'no'
				);
			}
			$mother = $self->{plugin_cascades}{$conf->{menu_grp}};
		}
		
		# メニューコマンド作成
		my $tmp_menu = $mother->command(
				-label => gui_window->gui_jchar($conf->{name}),
				-font => "TKFN",
				-command => sub{
					$cu->exec;
				},
				-state => 'disable'
		);
		
		# メニュー設定
		$conf->{menu_cnf} = 0 unless defined($conf->{menu_cnf});
		if ($conf->{menu_cnf} == 0){
			$tmp_menu->configure(-state, 'normal');
		}
		elsif ($conf->{menu_cnf} == 1){
			$self->{'t_plugin_'.$_} = $tmp_menu;
			push @menu0, 't_plugin_'.$_;
		}
		elsif ($conf->{menu_cnf} == 2){
			$self->{'t_plugin_'.$_} = $tmp_menu;
			push @menu1, 't_plugin_'.$_;
		}
	}



	$self->{t_sql_select} = $f->command(
			-label => kh_msg->get('exec_sql'),#gui_window->gui_jchar('SQL文の実行'),
			-font => "TKFN",
			-command => sub{
				gui_window::sql_select->open;
			},
			-state => 'disable'
		);

	#------------#
	#   ヘルプ   #
	
	$f = $menubar->cascade(
		-label => gui_window->gui_jm( kh_msg->get('help') ),#"$msg",
		-font => "TKFN",
		-underline => index(kh_msg->get('help'),'H'),
		-tearoff=>'no'
	);
	
		$f->command(
			-label => kh_msg->get('man'),
			-font => "TKFN",
			-command => sub { gui_OtherWin->open('khcoder_manual.pdf'); },
		);
		
		$f->command(
			-label => kh_msg->get('web'),
			-font => "TKFN",
			-command => sub {
					 gui_OtherWin->open('http://khc.sourceforge.net');
					},
		);
		
		$f->command(
			-label => kh_msg->get('about'),
			-command => sub{gui_window::about->open;},
			-font => "TKFN",
		);

	#--------------------#
	#   キー・バインド   #
	
	$mw->bind(
		'<Control-Key-o>',
		sub{gui_window::project_open->open;}
	);
	$mw->bind(
		'<Control-Key-n>',
		sub{gui_window::project_new->open;}
	);
	$mw->bind(
		'<Control-Key-v>',
		sub{gui_window::about->open;}
	);
	$mw->bind(
		'<Control-Key-w>',
		sub{$self->mc_close_project;}
	);

	bless $self, $class;
	return $self;
}

#------------------------------------#
#   一行を越えるメニュー・コマンド   #
#------------------------------------#

sub mc_view_nbl{
	my @types = (
		[ "KH Coder: Naive Bayes Logs",[qw/.nbl/] ],
		["All files",'*']
	);
	my $path = $::main_gui->mw->getOpenFile(
		-defaultextension => '.nbl',
		-filetypes        => \@types,
		-title            =>
			gui_window->gui_jt( kh_msg->get('open_nbl') ), # 閲覧する分類ログファイルを選択
		-initialdir       => gui_window->gui_jchar($::config_obj->cwd),
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);
	
	my $win = $::main_gui->get('w_bayes_view_log');
	$win->close if Exists( $win->{win_obj} );
	
	gui_window::bayes_view_log->open($path);
}

sub mc_view_knb{
	my @types = (
		[ "KH Coder: Naive Bayes Moldels",[qw/.knb/] ],
		["All files",'*']
	);
	my $path = $::main_gui->mw->getOpenFile(
		-defaultextension => '.knb',
		-filetypes        => \@types,
		-title            =>
			gui_window->gui_jt( kh_msg->get('open_knb') ), # 閲覧する学習結果ファイルを選択
		-initialdir       => gui_window->gui_jchar($::config_obj->cwd),
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);
	
	my $win = $::main_gui->get('w_bayes_view_knb');
	$win->close if Exists( $win->{win_obj} );
	
	gui_window::bayes_view_knb->open($path);
	
	# my $dist = $::project_obj->file_TempCSV;
	# kh_nbayes::Util->knb2csv(
	# 	path => $path,
	# 	csv  => $dist,
	# );
	# gui_OtherWin->open($dist);
}
sub mc_import_project{
	require kh_project_io;

	# KHCファイルのパス
	my @types = (
		['KH Coder',[qw/.khc/] ],
		["All Files",'*']
	);
	my $path = $::main_gui->mw->getOpenFile(
		-defaultextension => '.khc',
		-filetypes        =>  \@types,
		-title            =>
			gui_window->gui_jt( kh_msg->get('import_win_title') ),
		-initialdir       => gui_window->gui_jchar($::config_obj->cwd),
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);
	
	# 分析対象ファイルの保存場所
	my $info = &kh_project_io::get_info($path);
	return undef unless length($info->{file_name});
	@types = (
		['Data Files',[qw/.txt .html .htm/] ],
		["All Files",'*']
	);
	my $path_s = $::main_gui->mw->getSaveFile(
		-defaultextension => '.khc',
		-filetypes        =>  \@types,
		-title            =>
			gui_window->gui_jt( kh_msg->get('import_save_path') ),
		-initialdir       => gui_window->gui_jchar($::config_obj->cwd),
		-initialfile      => gui_window->gui_jchar($info->{file_name})
	);
	unless ($path_s){
		return 0;
	}
	$path_s = gui_window->gui_jg_filename_win98($path_s);
	$path_s = gui_window->gui_jg($path_s);
	$path_s = $::config_obj->os_path($path_s);
	
	# 実行
	my $w = gui_wait->start;
	&kh_project_io::import($path,$path_s);
	$w->end;
	
	# プロジェクトマネージャーを表示
	gui_window::project_open->open;

}
sub mc_export_project{
	require kh_project_io;

	# ファイル名
	my @types = (
		['KH Coder',[qw/.khc/] ],
		["All Files",'*']
	);
	my $path = $::main_gui->mw->getSaveFile(
		-defaultextension => '.khc',
		-filetypes        =>  \@types,
		-title            =>
			gui_window->gui_jt( kh_msg->get('export_win_title') ),
		-initialdir       => gui_window->gui_jchar($::config_obj->cwd),
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);
	
	# 実行
	my $w = gui_wait->start;
	&kh_project_io::export($path);
	$w->end;
}
sub mc_close_project{
	$::main_gui->close_all;
	undef $::project_obj;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;
}
sub mc_datacheck{
	#my $w = gui_wait->start;
	use kh_datacheck;
	kh_datacheck->run;
	#$w->end;
}
sub mc_morpho{
	my $self = shift;
	$::main_gui->close_all;
	my $w = gui_wait->start;
	$self->mc_morpho_exec;
	$w->end;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;
}
sub mc_morpho_exec{
	mysql_ready->first;
	$::project_obj->status_morpho(1);
}
sub mc_hukugo{
	my $self = shift;
	my $mw = $::main_gui->{win_obj};

	my $if_exec = 1;
	if (
		   ( -e $::project_obj->file_HukugoList )
		&& ( mysql_exec->table_exists('hukugo') )
	){
		my $t0 = (stat $::project_obj->file_target)[9];
		my $t1 = (stat $::project_obj->file_HukugoList)[9];
		if ($t0 < $t1){
			$if_exec = 0; # この場合だけ解析しない
		}
	}

	if ($if_exec){
		my $ans = $mw->messageBox(
			-message => kh_msg->gget('cont_big_pros'),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }

		my $w = gui_wait->start;
		use mysql_hukugo;
		mysql_hukugo->run_from_morpho;
		$w->end;
	}

	gui_window::hukugo->open;
}


#------------------------#
#   メニューの状態変更   #
#------------------------#

sub refresh{
	my $self = shift;
	$self->disable_all;

	if ($::project_obj){
		$self->normalize(\@menu0);
		
		# morpho_analyzer
		if ($::config_obj->c_or_j eq 'chasen'){
			$self->normalize([
				'm_b1_hukugo',
				'm_b1_hukugo_te',
				'm_b2_datacheck',
			]);
		}
		elsif ($::config_obj->c_or_j eq 'mecab'){
			$self->normalize([
				'm_b1_hukugo_te',
				'm_b2_datacheck',
			]);
		}
		elsif (
			   $::config_obj->c_or_j        eq 'stanford'
			&& $::config_obj->stanford_lang eq 'en'
		){
			$self->normalize([
				'm_b1_hukugo_te',
			]);
		}

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

sub disable_all{
	my $self = shift;
	foreach my $i (keys %{$self}){
		if (substr($i,0,2) eq 'm_' || substr($i,0,2) eq 't_'){
			$self->{$i}->configure(-state, 'disable');
		}
	}
}

1;
