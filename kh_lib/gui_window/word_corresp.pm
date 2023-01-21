package gui_window::word_corresp;
use base qw(gui_window);
use utf8;

use strict;
use Tk;

use kh_r_plot::corresp;
use gui_widget::tani;
use gui_widget::hinshi;
use mysql_crossout;
use plotR::network;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));

	my $lf = $win->LabFrame(
		-label => kh_msg->get('option_words'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
		-foreground => 'blue',
	)->pack(-fill => 'both', -expand => 0, -side => 'left',-anchor => 'w');

	my $rf = $win->Frame()
		->pack(-fill => 'both', -expand => 1);

	my $lf2 = $rf->LabFrame(
		-label => kh_msg->get('option_ca'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
		-foreground => 'blue',
	)->pack(-fill => 'both', -expand => 1);

	$self->{words_obj} = gui_widget::words->open(
		parent       => $lf,
		verb         => kh_msg->get('plot'), # 布置
		type         => 'corresp',
	);

	# 入力データの設定
	my $lf3 = $lf2->Frame->pack(-anchor => 'nw');
	$lf3->Label(
		-text => kh_msg->get('matrix'), # 分析に使用するデータ表の種類：
		-font => "TKFN",
	)->pack(-anchor => 'nw', -padx => 2, -pady => 2, -side => 'left');

	$self->{sampling_obj} = gui_widget::sampling->open(
		parent => $lf3,
		pack   => { -side => 'left' },
		command => sub{$self->calc;},
	);

	my $fi = $lf2->Frame()->pack(
		-fill   => 'both',
		-expand => 1,
		-padx   => 2,
		-pady   => 2
	);

	$fi->Label(
		-text => '    ',
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);

	my $fi_1 = $fi->Frame(
		-borderwidth        => 2,
		-relief             => 'sunken',
	)->pack(
		-anchor => 'w',
		-side   => 'left',
		-pady   => 2,
		-padx   => 2,
		-fill   => 'both',
		-expand => 1
	);

	$self->{radio} = 0;
	$fi_1->Radiobutton(
		-text             => kh_msg->get('w_d'), # 抽出語 ｘ 文書
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 0,
		-command          => sub{ $self->refresh; $self->sampling_config;},
	)->pack(-anchor => 'w');

	my $fi_2 = $fi_1->Frame()->pack(-anchor => 'w');
	$fi_2->Label(
		-text => '    ',
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{label_high} = $fi_2->Label(
		-text => kh_msg->get('unit'), # 集計単位：
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{opt_frame_high} = $fi_2;
	
	my $fi_4 = $fi_1->Frame()->pack(-anchor => 'w');
	$fi_4->Label(
		-text => '    ',
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{label_high2} = $fi_4->Checkbutton(
		-text     => kh_msg->get('biplot'), # 見出しまたは文書番号を同時布置
		-variable => \$self->{biplot},
	)->pack(
		-anchor => 'w',
		-side  => 'left',
	);

	$fi_1->Radiobutton(
		-text             => kh_msg->get('w_v'), # 抽出語 ｘ 外部変数
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 1,
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w');

	my $vars = mysql_outvar->get_list;
	$vars = @{$vars};
	if ( $::project_obj->status_from_table == 1 && $vars ){
		$self->{radio} = 1;
	}

	my $fi_3 = $fi_1->Frame()->pack(
		-anchor => 'w',
		-fill   => 'both',
		-expand => 1,
	);
	
	$fi_3->Label(
		-text => '    ',
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{opt_frame_var} = $fi_3;
	
	$self->refresh;

	# 差異の顕著な語のみ分析
	$self->{check_filter_w} = 1;                  # デフォルトでON
	my $fsw = $lf2->Frame()->pack(
		-fill => 'x',
		-pady => 2,
	);

	$fsw->Checkbutton(
		-text     => kh_msg->get('flw'), # 差異が顕著な語を分析に使用：
		-variable => \$self->{check_filter_w},
		-command  => sub{ $self->refresh_flw;},
	)->pack(
		-anchor => 'w',
		-side  => 'left',
	);

	$self->{entry_flw_l1} = $fsw->Label(
		-text => kh_msg->get('top'), # 上位
		-font => "TKFN",
	)->pack(-side => 'left', -padx => 0);

	$self->{entry_flw} = $fsw->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 0);
	$self->{entry_flw}->insert(0,'60');
	$self->{entry_flw}->bind("<Key-Return>", sub{$self->calc;});
	$self->{entry_flw}->bind("<KP_Enter>",   sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_flw});

	$self->{entry_flw_l2} = $fsw->Label(
		-text => kh_msg->get('words'), # 語
		-font => "TKFN",
	)->pack(-side => 'left', -padx => 0);
	$self->refresh_flw;

	# 特徴的な語のみラベル表示
	my $fs = $lf2->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 2,
	);

	$fs->Checkbutton(
		-text     => kh_msg->get('flt'), # 原点から離れた語のみラベル表示：
		-variable => \$self->{check_filter},
		-command  => sub{ $self->refresh_flt;},
	)->pack(
		-anchor => 'w',
		-side  => 'left',
	);

	$self->{entry_flt_l1} = $fs->Label(
		-text => kh_msg->get('top'), # 上位
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_flt} = $fs->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 0);
	$self->{entry_flt}->insert(0,'60');
	$self->{entry_flt}->bind("<Key-Return>",sub{$self->calc;});
	$self->{entry_flt}->bind("<KP_Enter>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_flt});

	$self->{entry_flt_l2} = $fs->Label(
		-text => kh_msg->get('words'), # 語
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->refresh_flt;

	# バブルプロット
	$self->{bubble_obj} = gui_widget::bubble->open(
		parent       => $lf2,
		type         => 'corresp',
		command      => sub{ $self->calc; },
		pack    => {
			-anchor   => 'w',
		},
	);

	# 成分
	$self->{xy_obj} = gui_widget::r_xy->open(
		parent    => $lf2,
		command   => sub{ $self->calc; },
		pack      => { -anchor => 'w', -pady => 2 },
	);

	# フォントサイズ
	$self->{font_obj} = gui_widget::r_font->open(
		parent    => $lf2,
		command   => sub{ $self->calc; },
		pack      => { -anchor   => 'w' },
		show_bold => 1,
	);

	#SCREEN Plugin
	use screen_code::correspond;
	&screen_code::correspond::add_menu($self,$lf2,0);
	#SCREEN Plugin
	
	$rf->Checkbutton(
			-text     => kh_msg->gget('r_dont_close'), # 実行時にこの画面を閉じない
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$rf->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$rf->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se')->focus;

	#SCREEN Plugin
	use screen_code::batch_plugin;
	&screen_code::batch_plugin::add_button_batch($self,$rf);
	#SCREEN Plugin

	
	$self->_settings_load;
	$self->sampling_config;
	return $self;
}

sub sampling_config{
	my $self = shift;
	return unless $self->{entry_flw_l1};
	
	my $tani2 = $self->tani2;

	my $n = mysql_exec->select("select count(*) from $tani2",1)->hundle->fetch->[0];
	$self->{sampling_obj}->onoff($n);
	
	# Biplot configuration
	if ($n <= 20) {
		$self->{biplot} = 1;
	} else {
		$self->{biplot} = 0;
	}
	
	if ($self->{label_high2}) {
		$self->{label_high2}->configure(-state => 'normal');
		$self->{label_high2}->update;
		
		if ($n > $::config_obj->corresp_max_values) {
			$self->{label_high2}->configure(-state => 'disabled');
		}
	}
}

sub tani2{
	my $self = shift;
	my $tani2;
	my $vars;
	
	if ($self->{radio} == 0){
		$tani2 = $self->gui_jg($self->{high});
	}
	elsif ($self->{radio} == 1){
		my $i = $self->{opt_body_var}->selectionGet->[0];
		$i = $self->{vars}[$i][1];
		$tani2 = mysql_outvar::a_var->new(undef,$i)->{tani};
	}
	
	#print "tani2: $tani2\n";
	return $tani2;
}

# 設定の保存（「OK」をクリックして実行する時に）
sub _settings_save{
	my $self = shift;
	my $settings;

	$settings->{radio}     = $self->{radio};
	$settings->{tani2}     = $self->gui_jg($self->{high});
	$settings->{biplot}    = $self->{biplot};
	$settings->{var_id}    = $self->{var_id};

	#$settings->{d_n}       = $self->gui_jg( $self->{entry_d_n}->get );
	$settings->{d_x}       = $self->{xy_obj}->x,
	$settings->{d_y}       = $self->{xy_obj}->y,
	$settings->{plot_size} = $self->{font_obj}->plot_size,
	$settings->{font_size} = $self->{font_obj}->font_size,

	$::project_obj->save_dmp(
		name => $self->win_name,
		var  => $settings,
	);

	# 抽出語選択の設定も保存しておく
	# （読み込みは自動だが、保存は手動…）
	$self->{words_obj}->settings_save;

	return $self;
}

# 設定の読み込み（画面を開く時に）
sub _settings_load{
	my $self = shift;

	return 1; # この機能でのみ設定がすべて保存されるようにすると、
	          # 他の機能とのバランスが悪そうなので、保存してある
	          # 設定を（今の所）敢えて読み込まないことに…。

	my $settings = $::project_obj->load_dmp(
		name => $self->win_name,
	) or return 0;

	# エントリー
	foreach my $i ('d_n', 'd_x', 'd_y', 'plot_size', 'font_size'){
		if ( length($settings->{$i}) ){
			$self->{'entry_'.$i}->delete(0,'end');
			$self->{'entry_'.$i}->insert(0,$settings->{$i});
		}
	}

	# 「抽出語ｘ文書」 or 「抽出語ｘ外部変数」
	$self->{radio} = $settings->{radio};
	$self->refresh;

	# 「抽出語ｘ文書」の場合
	if ( $self->{radio} == 0 ){
		$self->{opt_body_high}->set_value( $settings->{tani2} );
		if ($settings->{biplot}){
			$self->{label_high2}->select;
		} else {
			$self->{label_high2}->deselect;
		}
	}

	# 「抽出語ｘ外部変数」の場合
	elsif ( $self->{radio} == 1 ) {
		#$self->{opt_body_var}->set_value( $settings->{var_id} );
	}
}

# 「特徴語に注目」のチェックボックス
sub refresh_flt{
	my $self = shift;
	if ( $self->{check_filter} ){
		$self->{entry_flt}   ->configure(-state => 'normal');
		$self->{entry_flt_l1}->configure(-state => 'normal');
		$self->{entry_flt_l2}->configure(-state => 'normal');
	} else {
		$self->{entry_flt}   ->configure(-state => 'disabled');
		$self->{entry_flt_l1}->configure(-state => 'disabled');
		$self->{entry_flt_l2}->configure(-state => 'disabled');
	}
	return $self;
}

sub refresh_flw{
	my $self = shift;
	if ( $self->{check_filter_w} ){
		$self->{entry_flw}   ->configure(-state => 'normal');
		$self->{entry_flw_l1}->configure(-state => 'normal');
		$self->{entry_flw_l2}->configure(-state => 'normal');
	} else {
		$self->{entry_flw}   ->configure(-state => 'disabled');
		$self->{entry_flw_l1}->configure(-state => 'disabled');
		$self->{entry_flw_l2}->configure(-state => 'disabled');
	}
	return $self;
}




# ラジオボタン関連
sub refresh{
	my $self = shift;
	unless ($self->tani){return 0;}

	#------------------------#
	#   外部変数選択Widget   #

	my @options = ();
	my @tanis   = ();

	unless ($self->{opt_body_var}){
		# 利用できる変数をチェック
		my $h = mysql_outvar->get_list;
		my @options = ();
		foreach my $i (@{$h}){
			push @options, [$self->gui_jchar($i->[1]), $i->[2]];
		}
		
		# リスト表示
		$self->{vars} = \@options;
		$self->{opt_body_var} = $self->{opt_frame_var}->Scrolled(
			'HList',
			-scrollbars         => 'osoe',
			-header             => '0',
			-itemtype           => 'text',
			-font               => 'TKFN',
			-columns            => '1',
			-height             => '4',
			-background         => 'white',
			-selectforeground   => $::config_obj->color_ListHL_fore,
			-selectbackground   => $::config_obj->color_ListHL_back,
			-selectborderwidth  => 0,
			-highlightthickness => 0,
			-selectmode         => 'extended',
			-browsecmd          => sub{ $self->sampling_config; },
		)->pack(
			-anchor => 'w',
			-padx   => '2',
			-pady   => '2',
			-fill   => 'both',
			-expand => 1
		);
		
		my $row = 0;
		foreach my $i (@options){
			$self->{opt_body_var}->add($row, -at => "$row");
			$self->{opt_body_var}->itemCreate(
				$row,
				0,
				-text => $i->[0],
			);
			++$row;
		}
		
		$self->{opt_body_var}->selectionSet(0)
				if $self->{opt_body_var}->info('exists', 0);
		
		#$self->{opt_body_var} = gui_widget::chklist->open(
		#	parent  => $self->{opt_frame_var},
		#	options => \@options,
		#	default => 0,
		#	height  => 3,
		#	pack    => {
		#		-side   => 'left',
		#		-padx   => 2,
		#		-fill   => 'both',
		#		-expand => 1
		#	},
		#);
		#$self->{opt_body_var_ok} = 1;
	}

	#------------------------------#
	#   上位の文書単位選択Widget   #

	unless ($self->{opt_body_high}){

		my %tani_name = (
			"bun" => kh_msg->gget('sentence'),
			"dan" => kh_msg->gget('paragraph'),
			"h5"  => "H5",
			"h4"  => "H4",
			"h3"  => "H3",
			"h2"  => "H2",
			"h1"  => "H1",
		);

		@tanis = ();
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			if (
				mysql_exec->select(
					"select status from status where name = \'$i\'",1
				)->hundle->fetch->[0]
			){
				push @tanis, [$self->gui_jchar($tani_name{$i}),$i];
			}
		}

		if (@tanis){
			$self->{opt_body_high} = gui_widget::optmenu->open(
				parent  => $self->{opt_frame_high},
				pack    => {-side => 'left', -padx => 2},
				options => \@tanis,
				variable => \$self->{high},
				command => sub {$self->sampling_config;},
			);
			$self->{opt_body_high_ok} = 1;
		} else {
			$self->{opt_body_high} = gui_widget::optmenu->open(
				parent  => $self->{opt_frame_high},
				pack    => {-side => 'left', -padx => 2},
				options => 
					[
						[kh_msg->get('na'), undef], # 利用不可
					],
				variable => \$self->{high},
			);
			$self->{opt_body_high_ok} = 0;
		}
		
		#print "ok0\n";
		if ($self->{high} =~ /h[1-5]/){
			my $chk =
				mysql_exec->select("select max(id) from $self->{high} ")
					->hundle->fetch->[0];
			#print "ok1\n";
			if ($chk <= 20){
				$self->{biplot} = 1;
				$self->{label_high2}->update;
				#print "ok2\n";
			}
		}
	}

	#----------------------------------#
	#   Widgetの有効・無効を切り替え   #

	if ($self->{radio} == 0){
		if ($self->{opt_body_high_ok}){
			$self->{opt_body_high}->configure(-state => 'normal');
		} else {
			$self->{opt_body_high}->configure(-state => 'disable');
		}
		$self->{label_high}->configure(-foreground => 'black');
		$self->{label_high2}->configure(-state => 'normal');
		
		$self->{opt_body_var}->configure(-selectbackground => 'gray');
		$self->{opt_body_var}->configure(-background => 'gray');
	}
	elsif ($self->{radio} == 1){
		$self->{opt_body_high}->configure(-state => 'disable');
		$self->{label_high}->configure(-foreground => 'gray');
		$self->{label_high2}->configure(-state => 'disable');

		$self->{opt_body_var}->configure(-selectbackground => $::config_obj->color_ListHL_back);
		$self->{opt_body_var}->configure(-background => 'white');

	}
	
	return 1;
}

sub start_raise{
	my $self = shift;
	$self->{words_obj}->settings_load;
}

sub start{
	my $self = shift;

	# Windowを閉じる際のバインド
	$self->win_obj->bind(
		'<Control-Key-q>',
		sub{ $self->withd; }
	);
	$self->win_obj->bind(
		'<Key-Escape>',
		sub{ $self->withd; }
	);
	$self->win_obj->protocol('WM_DELETE_WINDOW', sub{ $self->withd; });
}

#----------#
#   実行   #

sub calc{
	my $self = shift;
	
	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('select_pos'), # 品詞が1つも選択されていません。
		);
		return 0;
	}

	my $tani2 = '';
	my $vars;
	if ($self->{radio} == 0){
		$tani2 = $self->gui_jg($self->{high});
	}
	elsif ($self->{radio} == 1){
		foreach my $i ( $self->{opt_body_var}->selectionGet ){
			push @{$vars}, $self->{vars}[$i][1];
		}
		
		unless ( @{$vars} ){
			gui_errormsg->open(
				type => 'msg',
				msg  => kh_msg->get('select_var'), # 外部変数を1つ以上選択してください。
			);
			return 0;
		}
		
		foreach my $i (@{$vars}){
			if ($tani2){
				unless (
					$tani2
					eq mysql_outvar::a_var->new(undef,$i)->{tani}
				){
					gui_errormsg->open(
						type => 'msg',
						msg  => kh_msg->get('check_var_unit'), # 現在の所、集計単位が異なる外部変数を同時に使用することはできません。
					);
					return 0;
				}
			} else {
				$tani2 = mysql_outvar::a_var->new(undef,$i)
					->{tani};
			}
		}
	}

	my $rownames = 0;
	$rownames = 1 if ($self->{radio} == 0 and $self->{biplot} == 1);

	my $check_num = mysql_crossout::r_com->new(
		tani     => $self->tani,
		tani2    => $tani2,
		hinshi   => $self->hinshi,
		max      => $self->max,
		min      => $self->min,
		max_df   => $self->max_df,
		min_df   => $self->min_df,
	)->wnum;

	$check_num =~ s/,//g;
	#print "$check_num\n";

	if ($check_num < 3){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('select_3words'), # 少なくとも3つ以上の抽出語を布置して下さい。
		);
		return 0;
	}

	if ($check_num > 200){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					kh_msg->get('too_many1') # 現在の設定では
					.$check_num
					.kh_msg->get('too_many2') # 語が布置されます。
					."\n"
					.kh_msg->get('too_many3') # 布置する語の数は100〜150程度におさえることを推奨します。
					."\n"
					.kh_msg->get('too_many4') # 続行してよろしいですか？
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
	}

	$self->_settings_save;

	my $w = gui_wait->start;

	# データの取り出し
	my $r_command = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $tani2,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		rownames => $rownames,
		sampling => $self->{sampling_obj}->parameter,
	)->run;
	$r_command .= "if ( is.null( rownames(d) ) ){ rownames(d) = 1:nrow(d) }\n";
	$r_command .= "v_count <- 0\n";
	$r_command .= "v_pch   <- NULL\n";

	# random sampling
	my $threshold = 2;
	srand 11;
	if ( $self->{sampling_obj}->parameter ){
		my $tani = $tani2;
		my $target = $self->{sampling_obj}->parameter;
		my $n = mysql_exec->select("select count(*) from $tani",1)->hundle->fetch->[0];
		if ($target < $n){
			$threshold = $target / $n;
			$threshold = sprintf("%.5f",$threshold);
		}
		#print "sampling th: $threshold\n";
	}

	# 外部変数の付与
	if ($self->{radio} == 1){
		
		my $n_v = 0;
		foreach my $i (@{$vars}){
			my $var_obj = mysql_outvar::a_var->new(undef,$i);
			
			my $sql = '';
			$sql .= "SELECT $var_obj->{column} FROM $var_obj->{table} ";
			$sql .= "ORDER BY id";
			
			$r_command .= "v$n_v <- c(";
			my $h = mysql_exec->select($sql,1)->hundle;
			while (my $i = $h->fetch){
				if (rand() <= $threshold) {
					$i->[0] = Encode::decode('utf8', $i->[0]) unless utf8::is_utf8($i->[0]);
					if ( length( $var_obj->{labels}{$i->[0]} ) ){
						my $t = $var_obj->{labels}{$i->[0]};
						$t =~ s/"/ /g;
						$r_command .= "\"$t\",";
					} else {
						$r_command .= "\"$i->[0]\",";
					}
				}
			}
			
			chop $r_command;
			$r_command .= ")\n";
			++$n_v;
		}
		
		$r_command .= &r_command_aggr($n_v);
	}

	# 外部変数が無かった場合
	$r_command .= '
		if ( length(v_pch) == 0 ) {
			v_pch   <- 3
			v_count <- 1
		}
	';

	# 空の行・空の列を削除
	$r_command .=
		"if ( length(v_pch) > 1 ){ v_pch <- v_pch[rowSums(d) > 0] }\n";
	$r_command .=
		"doc_length_mtr <- subset(doc_length_mtr, rowSums(d) > 0)\n";
	$r_command .=
		"d              <- subset(d,              rowSums(d) > 0)\n";
	$r_command .= "n_total <- doc_length_mtr[,2]\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	my $biplot = 1;
	$biplot = 0 if $self->{radio} == 0 and $self->{biplot} == 0;

	my $filter = 0;
	if ( $self->{check_filter} ){
		$filter = $self->gui_jgn( $self->{entry_flt}->get );
	}

	my $filter_w = 0;
	if ( $self->{check_filter_w} ){
		$filter_w = $self->gui_jgn( $self->{entry_flw}->get );
	}

	my $plot = &make_plot(
		$self->{xy_obj}->params,
		flt          => $filter,
		flw          => $filter_w,
		biplot       => $biplot,
		font_size    => $self->{font_obj}->font_size,
		font_bold    => $self->{font_obj}->check_bold_text,
		plot_size    => $self->{font_obj}->plot_size,
		r_command    => $r_command,
		bubble       => $self->{bubble_obj}->check_bubble,
		std_radius   => $self->{bubble_obj}->chk_std_radius,
		resize_vars  => $self->{bubble_obj}->chk_resize_vars,
		bubble_size  => $self->{bubble_obj}->size,
		bubble_var   => $self->{bubble_obj}->var,
		use_alpha    => $self->{bubble_obj}->alpha,
		plotwin_name => 'word_corresp',
	);

	$w->end(no_dialog => 1);
	return 0 unless $plot;
	
	# プロットWindowを開く
	my $plotwin_id = 'w_word_corresp_plot';
	if ($::main_gui->if_opened($plotwin_id)){
		$::main_gui->get($plotwin_id)->close;
	}
	
	gui_window::r_plot::word_corresp->open(
		plots       => $plot->{result_plots},
		coord       => $plot->{coord},
		ratio       => $plot->{ratio},
		#no_geometry => 1,
	);

	unless ( $self->{check_rm_open} ){
		$self->withd;
	}

}


sub make_plot{
	my %args = @_;
	$args{flt} = 0 unless $args{flt};
	$args{flw} = 0 unless $args{flw};

	my $x_factor = 1;
	if ( $args{bubble} == 1 ){
		$x_factor = 1.285;
	}
	$args{height} = $args{plot_size};
	$args{width}  = int( $args{plot_size} * $x_factor );

	#my $fontsize = 1;
	my $r_command = $args{r_command};
	$args{use_alpha} = 0 unless ( length($args{use_alpha}) );

	$r_command = $r_command;

	kh_r_plot::corresp->clear_env;

	if ($args{font_bold} == 1){
		$args{font_bold} = 2;
	} else {
		$args{font_bold} = 1;
	}
	
	if (length($args{breaks})) {
		$r_command .= "breaks <- c($args{breaks})\n";
	} else {
		$r_command .= "breaks <- NULL\n";
	}
	$r_command .= "text_font <- $args{font_bold}\n";
	$r_command .= "r_max <- 150\n";
	$r_command .= "zoom_factor <- $args{zoom}\n";
	$r_command .= "d_x <- $args{d_x}\n";
	$r_command .= "d_y <- $args{d_y}\n";
	$r_command .= "flt <- $args{flt}\n";
	$r_command .= "flw <- $args{flw}\n";
	$r_command .= "bubble_plot <- $args{bubble}\n";
	$r_command .= "biplot <- $args{biplot}\n";
	#$r_command .= "cex=$fontsize\n";
	$r_command .= "use_alpha <- $args{use_alpha}\n";
	$r_command .= "show_origin <- $args{show_origin}\n";
	$r_command .= "scaling <- \"$args{scaling}\"\n";
	$r_command .= "corresp_max_values <- ".$::config_obj->corresp_max_values."\n";
	$r_command .= "
		if ( exists(\"saving_emf\") || exists(\"saving_eps\") ){
			use_alpha <- 0 
		}
	";

	$r_command .= "name_dim <- '".kh_msg->pget('dim')."'\n"; # 成分
	$r_command .= "name_eig <- '".kh_msg->pget('eig')."'\n"; # 固有値
	$r_command .= "name_exp <- '".kh_msg->pget('exp')."'\n"; # 寄与率
	
	$args{margin_top}    = 0 unless length($args{margin_top}   );
	$args{margin_bottom} = 0 unless length($args{margin_bottom});
	$args{margin_left}   = 0 unless length($args{margin_left}  );
	$args{margin_right}  = 0 unless length($args{margin_right} );
	$r_command .= "margin_top <- $args{margin_top}\n";
	$r_command .= "margin_bottom <- $args{margin_bottom}\n";
	$r_command .= "margin_left <- $args{margin_left}\n";
	$r_command .= "margin_right <- $args{margin_right}\n";

	$r_command .= "library(MASS)\n";

	$r_command .= &r_command_filter;

	$r_command .= "k <- c\$cor^2\n";
	$r_command .=
		"txt <- cbind( 1:length(k), round(k,4), round(100*k / sum(k),2) )\n";
	$r_command .= "colnames(txt) <- c(name_dim,name_eig,name_exp)\n";
	$r_command .= "print( txt )\n";
	$r_command .= "inertias <- round(k,4)\n";
	$r_command .= "k <- round(100*k / sum(k),2)\n";

	# プロットのためのRコマンド
	my ($r_command_3a, $r_command_3);
	my ($r_command_2a, $r_command_2);
	my ($r_com_gray, $r_com_gray_a);

	# 初期化
	$r_command .= "font_size <- $args{font_size}\n";
	$r_command .= "resize_vars <- $args{resize_vars}\n";
	$r_command .= "bubble_size <- $args{bubble_size}\n";
	$r_command .= "labcd <- NULL\n\n";
	my $common = $r_command;
	
	# ドットのみ
	$r_command .= "plot_mode <- \"color\"\n";
	$r_command .= &r_command_bubble(%args);

	# カラー
	$r_command_2a .= "plot_mode <- \"dots\"\n";
	$r_command_2a .= &r_command_bubble(%args);
	$r_command_2  = $common.$r_command_2a;

	if ($args{biplot}){
		# 変数のみ
		$r_command_3a .= "plot_mode <- \"vars\"\n";
		$r_command_3a .= "if (biplot==0){\n plot(0,0,pch=3)\n text(0,0.5,\"No output\")\n}\n";
		$r_command_3a .= "if (biplot==1){\n";
		$r_command_3a .= &r_command_bubble(%args);
		$r_command_3a .= "\n}\n";
		$r_command_3  = $common.$r_command_3a;
		
		# グレースケール
		$r_com_gray_a .= "plot_mode <- \"gray\"\n";
		$r_com_gray_a .= &r_command_bubble(%args);
		$r_com_gray = $common.$r_com_gray_a;
	}


	# プロット作成
	my $plot1 = kh_r_plot::corresp->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command,
		width     => int( $args{plot_size} * $x_factor ),
		height    => $args{plot_size},
		font_size => $args{font_size},
	) or return 0;

	my $plot2 = kh_r_plot::corresp->new(
		name      => $args{plotwin_name}.'_2',
		command_a => $r_command_2a,
		command_f => $r_command_2,
		width     => int( $args{plot_size} * $x_factor ),
		height    => $args{plot_size},
		font_size => $args{font_size},
	) or return 0;

	my ($plotg, $plotv);
	my @plots = ();
	if ($r_com_gray_a){
		$plotg = kh_r_plot::corresp->new(
			name      => $args{plotwin_name}.'_g',
			command_a => $r_com_gray_a,
			command_f => $r_com_gray,
			width     => int( $args{plot_size} * $x_factor ),
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or return 0;
		
		$plotv = kh_r_plot::corresp->new(
			name      => $args{plotwin_name}.'_v',
			command_a => $r_command_3a,
			command_f => $r_command_3,
			width     => int( $args{plot_size} * $x_factor ),
			height    => $args{plot_size},
			font_size => $args{font_size},
		) or return 0;
		@plots = ($plot1,$plotg,$plotv,$plot2);
	} else {
		@plots = ($plot1,$plot2);
	}

	my $txt = $plot1->r_msg;
	if ( length($txt) ){
		print "-------------------------[Begin]-------------------------[R]\n";
		print "$txt\n";
		print "---------------------------------------------------------[R]\n";
	}

	# write coordinates to a file
	my $csv = $::project_obj->file_TempCSV;
	$::config_obj->R->send("
		write.table(out_coord, file=\"".$::config_obj->uni_path($csv)."\", fileEncoding=\"UTF-8\", sep=\"\\t\", quote=F, col.names=F)\n
	");

	# get XY ratio
	$::config_obj->R->send("
		if (asp == 1){
			ratio = ( xlimv[2] - xlimv[1] ) / ( ylimv[2] - ylimv[1] )
		} else {
			ratio = 0
		}
		print( paste0('<ratio>', ratio ,'</ratio>') )
	");
	my $ratio = $::config_obj->R->read;
	if ( $ratio =~ /<ratio>(.+)<\/ratio>/) {
		$ratio = $1;
	}

	# get breaks of bubble plot legend
	if ($args{bubble}){
		$::config_obj->R->send('
			legend_breaks_n <- ""
			for ( i in 1:length(breaks_a) ){
				legend_breaks_n <- paste(legend_breaks_n, breaks_a[i], sep = ", ")
			}
			print(paste0("<breaks>", legend_breaks_n, "</breaks>"))
		');
		my $breaks = $::config_obj->R->read;
		if ( $breaks =~ /<breaks>(.+)<\/breaks>/) {
			$breaks = $1;
			substr($breaks, 0, 2) = '';
		}
		foreach my $i (@plots){
			$i->{command_f} .= "\n# breaks: $breaks\n";
		}
		#print "breaks: $breaks\n";
	}

	kh_r_plot::corresp->clear_env;

	my $plotR;
	$plotR->{result_plots} = \@plots,
	$plotR->{coord} = $csv;
	$plotR->{ratio} = $ratio;
	
	return $plotR;
}


sub r_command_aggr{
	my $n_v = shift;
	my $t =
		"name_nav <- '"
		.kh_msg->pget('nav')
		."'\n"; # 欠損値
	$t .= << 'END_OF_the_R_COMMAND';

aggregate_with_var <- function(d, doc_length_mtr, v) {
	d              <- aggregate(d,list(name = v), sum)
	doc_length_mtr <- aggregate(doc_length_mtr,list(name = v), sum)

	row.names(d) <- d$name
	d$name <- NULL
	row.names(doc_length_mtr) <- doc_length_mtr$name
	doc_length_mtr$name <- NULL

	d              <- d[              order(rownames(d             )), ]
	doc_length_mtr <- doc_length_mtr[ order(rownames(doc_length_mtr)), ]

	tf <- row.names(d) != name_nav & row.names(d) != "." & regexpr("^missing$", row.names(d), ignore.case = T, perl = T) == -1
	
	doc_length_mtr <- subset(doc_length_mtr, tf)
	d <- subset(d, tf)

	# doc_length_mtr <- subset(doc_length_mtr, rowSums(d) > 0)
	# d              <- subset(d,              rowSums(d) > 0)

	return( list(d, doc_length_mtr) )
}

dd <- NULL
nn <- NULL

END_OF_the_R_COMMAND

	$t .= "for (i in list(";
	for (my $i = 0; $i < $n_v; ++$i){
		$t .= "v$i,";
	}
	chop $t;
	$t .= ")){\n";

	$t .= << 'END_OF_the_R_COMMAND2';

	cur <- aggregate_with_var(d, doc_length_mtr, i)
	dd <- rbind(dd, cur[[1]])
	nn <- rbind(nn, cur[[2]])
	v_count <- v_count + 1
	v_pch <- c( v_pch, rep(v_count + 2, nrow(cur[[1]]) ) )
}

d              <- as.matrix( dd )
doc_length_mtr <- as.matrix( nn )

END_OF_the_R_COMMAND2

	return $t;
}

sub r_command_filter{
	my $t = << 'END_OF_the_R_COMMAND';

# Filter words by chi-square value
if ( (flw > 0) && (flw < ncol(d)) ){
	sort  <- NULL
	for (i in 1:ncol(d) ){
		# print( paste(colnames(d)[i], chisq.test( cbind(d[,i], n_total - d[,i]) )$statistic) )
		sort <- c(
			sort, 
			chisq.test( cbind(d[,i], n_total - d[,i]) )$statistic
		)
	}
	d <- d[,order(sort,decreasing=T)]
	d <- d[,1:flw]
	
	if (exists("doc_length_mtr")){
		doc_length_mtr <- subset(doc_length_mtr, rowSums(d) > 0)
		n_total <- doc_length_mtr[,2]
	}
	d <- subset(d, rowSums(d) > 0)
}

d_max <- min( nrow(d), ncol(d) ) - 1
if (d_x > d_max){
	d_x <- d_max
}
if (d_y > d_max){
	d_y <- d_max
}

c <- corresp(d, nf=d_max )

if ( nrow(d) > corresp_max_values ){
	biplot <- 0
}

if (d_max == 1){
	c$cscore <- as.matrix( c$cscore )
	c$rscore <- as.matrix( c$rscore )
	colnames(c$cscore) <- c("X1")
	colnames(c$rscore) <- c("X1")
}

# Dilplay Labels only for distinctive words
if ( (flt > 0) && (flt < nrow(c$cscore)) ){
	sort  <- NULL
	limit <- NULL
	names <- NULL
	ptype <- NULL
	
	# compute distance from (0,0)
	for (i in 1:nrow(c$cscore) ){
		sort <- c(sort, c$cscore[i,d_x] ^ 2 + c$cscore[i,d_y] ^ 2 )
	}
	
	# Put labels to top words
	limit <- sort[order(sort,decreasing=T)][flt]
	for (i in 1:nrow(c$cscore) ){
		if ( sort[i] >= limit ){
			names <- c(names, rownames(c$cscore)[i])
			ptype <- c(ptype, 1)
		} else {
			names <- c(names, NA)
			ptype <- c(ptype, 2)
		}
	}
	rownames(c$cscore) <- names;
} else {
	ptype <- 1
}

pch_cex <- 1
if ( v_count > 1 ){
	pch_cex <- 1.25
}

# Zooming area near the origin

log_conv <- function(x, y, a){
	log_base <- 10
	
	# Find Cosine theta
	OA  <- sqrt( x^2 + y^2 )
	OA[OA == 0] <- 0.00000000000000000001
	Cos <- x / OA
	
	# Convert OA
	OA <- log(OA + 1, log_base)
	OA <- OA * a
	OA <- log(OA + 1, log_base)
	OA <- OA * a
	OA <- log(OA + 1, log_base)

	# Find OB
	OB <- Cos * OA
	
	# Find AB
	AB = sqrt( OA^2 - OB^2 )
	AB[y < 0] <- AB[y < 0] * -1
	
	cbind(OB, AB)
}

axp <- NULL
if (zoom_factor >= 1 ){
	scaling <- "none"
	axp <- c(0,0,1)

	r <- log_conv( c$cscore[,d_x], c$cscore[,d_y], zoom_factor )
	c$cscore[,d_x] <- r[,1]
	c$cscore[,d_y] <- r[,2]

	r <- log_conv( c$rscore[,d_x], c$rscore[,d_y], zoom_factor )
	c$rscore[,d_x] <- r[,1]
	c$rscore[,d_y] <- r[,2]
}

# Scaling
asp <- 0
if (scaling == "sym"){
	for (i in 1:d_max){
		c$cscore[,i] <- c$cscore[,i] * c$cor[i]
		c$rscore[,i] <- c$rscore[,i] * c$cor[i]
	}
	asp <- 1
} else if (scaling == "symbi"){
	for (i in 1:d_max){
		c$cscore[,i] <- c$cscore[,i] * sqrt( c$cor[i] )
		c$rscore[,i] <- c$rscore[,i] * sqrt( c$cor[i] )
	}
	asp <- 1
}


END_OF_the_R_COMMAND
return $t;
}

sub r_command_bubble{
	my %args = @_;
	return '

library(ggplot2)

font_family <- "'.$::config_obj->font_plot_current.'"

if ( exists("PERL_font_family") ){
	font_family <- PERL_font_family
}

#-----------------------------------------------------------------------------#
#                           prepare label positions
#-----------------------------------------------------------------------------#

# compute label positions
if (biplot == 1 && plot_mode != "vars"){
	cb <- rbind(
		cbind(c$cscore[,d_x], c$cscore[,d_y], ptype),
		cbind(c$rscore[,d_x], c$rscore[,d_y], v_pch)
	)
} else if (plot_mode == "vars") {
	cb <- cbind(c$rscore[,d_x], c$rscore[,d_y], v_pch)
} else {
	cb <- cbind(c$cscore[,d_x], c$cscore[,d_y], ptype)
}

if ( (is.null(labcd) && plot_mode != "dots" ) || plot_mode == "vars"){

	png_width  <- '.$args{width}.'
	png_height <- '.$args{height}.' 
	png_width  <- png_width - 0.16 * bubble_size / 100 * png_width
	dpi <- 72 * min(png_width, png_height) / 640
	p_size <- 12 * dpi / 72;
	png("temp.png", width=png_width, height=png_height, unit="px", pointsize=p_size)

	#if ( exists("PERL_font_family") ){
	#	par(family=PERL_font_family) 
	#}

	plot(
		x=c(c$cscore[,d_x],c$rscore[,d_x]),
		y=c(c$cscore[,d_y],c$rscore[,d_y]),
		asp=asp
	)

	library(maptools)
	labcd <- pointLabel(
		x=cb[,1],
		y=cb[,2],
		labels=rownames(cb),
		cex=font_size,
		offset=0,
		doPlot=F
	)

	xorg <- cb[,1]
	yorg <- cb[,2]
	#cex  <- 1

	n_words_chk <- c( length(c$cscore[,d_x]) )
	if (flt > 0) {
		n_words_chk <- c(n_words_chk, flt)
	}
	if (flw > 0) {
		n_words_chk <- c(n_words_chk, flw)
	}
	if ( 
		   ( (biplot == 0) && (min(n_words_chk) < 300) )
		|| (
			   (biplot == 1)
			&& ( min(n_words_chk) < 300 )
			&& ( length(c$rscore[,d_x]) < r_max )
		)
	){

		library(wordcloud)
		'.&plotR::network::r_command_wordlayout.'

		cex <- font_size * 1.05
		if (font_size > 1){
			cex <- cex + (font_size - 1) * 1.05
		}
		nc <- wordlayout(
			labcd$x,
			labcd$y,
			rownames(cb),
			cex=cex,
			xlim=c(  par( "usr" )[1], par( "usr" )[2] ),
			ylim=c(  par( "usr" )[3], par( "usr" )[4] )
		)

		xlen <- par("usr")[2] - par("usr")[1]
		ylen <- par("usr")[4] - par("usr")[3]

		segs <- NULL
		for (i in 1:length( rownames(cb) ) ){
			x <- ( nc[i,1] + .5 * nc[i,3] - labcd$x[i] ) / xlen
			y <- ( nc[i,2] + .5 * nc[i,4] - labcd$y[i] ) / ylen
			dst <- sqrt( x^2 + y^2 )
			if ( dst > 0.05 ){
				segs <- rbind(
					segs,
					c(
						nc[i,1] + .5 * nc[i,3], nc[i,2] + .5 * nc[i,4],
						xorg[i], yorg[i]
					) 
				)
			}
		}

		xorg <- labcd$x
		yorg <- labcd$y
		labcd$x <- nc[,1] + .5 * nc[,3]
		labcd$y <- nc[,2] + .5 * nc[,4]
	}
	
	text(labcd$x, labcd$y, rownames(cb))
	dev.off()
}


#-----------------------------------------------------------------------------#
#                              start plotting
#-----------------------------------------------------------------------------#

#-----------#
#   Words   #

b_size <- NULL
for (i in rownames(c$cscore)){
	if ( is.na(i) || is.null(i) || is.nan(i) ){
		b_size <- c( b_size, 1 )
	} else {
		b_size <- c( b_size, sum( d[,i] ) )
	}
}

col_bg_words <- NA
col_bg_vars  <- NA

if (plot_mode == "color"){
	col_dot_words <- "#00CED1"
	col_dot_vars  <- "#FF6347"
	if (color_universal_design == 1){
		col_dot_words <- "#74add1" # #2c7bb6
		col_dot_vars  <- "#f46d43"
	}
	if ( use_alpha == 1 ){
		col_bg_words <- "#48D1CC"
		col_bg_vars  <- "#FFA07A"
		if (color_universal_design == 1){
			col_bg_words <- "#abd9e9"
			col_bg_vars  <- "#FFA07A"
		}
		
		rgb <- col2rgb(col_bg_words) / 255
		col_bg_words <- rgb( rgb[1], rgb[2], rgb[3])
		
		rgb <- col2rgb(col_bg_vars) / 255
		col_bg_vars <- rgb( rgb[1], rgb[2], rgb[3])
	}
}

if (plot_mode == "gray"){
	col_dot_words <- "gray55"
	col_dot_vars  <- "gray30"
}

if (plot_mode == "vars"){
	col_dot_words <- "#ADD8E6"
	col_dot_vars  <- "red"
}

if (plot_mode == "dots"){
	col_dot_words <- "black"
	col_dot_vars  <- "black"
}

g <- ggplot()

df.words <- data.frame(
	x    = c$cscore[,d_x],
	y    = c$cscore[,d_y],
	size = b_size,
	type = ptype
)

df.words.sub <- subset(df.words, type==2)
df.words     <- subset(df.words, type==1)

if (bubble_plot == 1){
	g <- g + geom_point(
		data=df.words,
		aes(x=x, y=y, size=size),
		shape=21,
		#colour = NA,
		fill = col_bg_words,
		alpha=0.15
	)
	
	g <- g + geom_point(
		data=df.words,
		aes(x=x, y=y, size=size),
		shape=21,
		colour = col_dot_words,
		fill = NA,
		alpha=1,
		show.legend = F
	)
	
	# bubble plot legend configuration
	limits_a <- c(NA, NA);
	if (is.null(breaks)){
		breaks <- labeling::extended(
			min(df.words$size, na.rm=T),
			max(df.words$size, na.rm=T),
			5
		)
		breaks_a <- NULL
		for ( i in 1:length(breaks) ){
			if (
				   min(df.words$size, na.rm=T) <= breaks[i]
				&& max(df.words$size, na.rm=T) >= breaks[i]
			){
				breaks_a <- c(breaks_a, breaks[i])
			}
		}
		breaks <- breaks_a
	} else {
		breaks_a <- breaks
		if (  min(breaks) < min(df.words$size, na.rm=T) ){
			limits_a[1] <- min(breaks)
		}
		if (  max(breaks) > max(df.words$size, na.rm=T) ){
			limits_a[2] <- max(breaks)
		}
	}
	
	g <- g + scale_size_area(
		max_size= 30 * bubble_size / 100,
		breaks = breaks_a,
		limits = limits_a,
		guide = guide_legend(
			title = "Frequency:",
			override.aes = list(colour="black", fill=NA, alpha=1),
			label.hjust = 1,
			order = 2
		)
	)
} else {
	g <- g + geom_point(
		data=df.words,
		aes(x=x, y=y),
		size = 2,
		shape=16,
		colour = col_dot_words,
		alpha=1,
		show.legend = F
	)
}

if ( nrow(df.words.sub) > 0 ){
	g <- g + geom_point(
		data=df.words.sub,
		aes(x=x, y=y),
		shape=19,
		size=2,
		colour = "#ADD8E6",
		alpha=1,
		show.legend = F
	)
}

#---------------#
#   Variables   #

if ( biplot == 1 ){
	df.vars <- data.frame(
		x    = c$rscore[,d_x],
		y    = c$rscore[,d_y],
		size = n_total * max(b_size) / max(n_total) * 0.6,
		type = v_pch
	)

	if ( (resize_vars == 1) && (bubble_plot == 1) ) {
		g <- g + geom_point(
			data=df.vars,
			aes(x=x, y=y, size=size, shape=factor(type) ),
			#colour = NA,
			fill = col_bg_vars,
			alpha=0.2,
			show.legend = F
		)

		g <- g + geom_point(
			data=df.vars,
			aes(x=x, y=y, size=size, shape=factor(type) ),
			colour = col_dot_vars,
			fill = NA,
			alpha=1,
			show.legend = F
		)
	} else {
		g <- g + geom_point(
			data=df.vars,
			aes(x=x, y=y, shape=factor(type) ),
			colour = NA,
			fill = col_bg_vars,
			alpha=0.2,
			size=3.5,
			show.legend = F
		)

		g <- g + geom_point(
			data=df.vars,
			aes(x=x, y=y, shape=factor(type) ),
			colour = col_dot_vars,
			fill = NA,
			alpha=1,
			size=3.5,
			show.legend = F
		)
	}

	g <- g + scale_shape_manual(
		values = c(22:25,0-6)
	)
}

#------------#
#   Labels   #

# label colors
if (plot_mode == "color"){
	#if (bubble_plot == 1){
		col_txt_words <- "black"
		col_txt_vars  <- "#d73027"
	#} else {
	#	col_txt_words <- "black"
	#	col_txt_vars  <- "#FF6347"
	#}
}

if (plot_mode == "gray"){
	col_txt_words <- "black"
	col_txt_vars  <- "black"
}

if (plot_mode == "vars"){
	col_txt_words <- "black"
	col_txt_vars  <- "black"
}

if (plot_mode == "dots"){
	col_txt_words <- NA
	col_txt_vars  <- NA
}

if ( text_font == 1 ){
	font_face <- "plain"
} else {
	font_face <- "bold"
}

if ( exists("df.labels.save ") == F ){
	df.labels.save <- data.frame(
		x    = labcd$x,
		y    = labcd$y,
		labs = rownames(cb),
		cols = cb[,3]
	)
}

if (plot_mode != "dots") {
	df.labels <- data.frame(
		x    = labcd$x,
		y    = labcd$y,
		labs = rownames(cb),
		cols = cb[,3]
	)
	if ( plot_mode == "gray" ){
		df.labels.var  <- subset(df.labels, cols == 3)
		df.labels <- subset(df.labels, cols != 3)
		g <- g + geom_label(
			data=df.labels.var,
			family=font_family,
			fontface="bold",
			label.size=0.25 * font_size,
			size=4 * font_size,
			label.padding=unit(1.8 * font_size, "mm"),
			colour="white",
			fill="gray50",
			#alpha=0.7,
			aes(x=x, y=y,label=labs)
		)
		if (
			exists("df.vars")
			&& ( (resize_vars == 0) || (bubble_plot == 0) ) 
		){
			g <- g + geom_point(
				data=df.vars,
				aes(x=x, y=y, shape=factor(type) ),
				colour = col_dot_vars,
				fill = NA,
				alpha=1,
				size=3.5,
				show.legend = F
			)
		}
	}
	
	g <- g + geom_text(
		data=df.labels,
		aes(x=x, y=y,label=labs,colour=factor(cols)),
		size=4 * font_size,
		family=font_family,
		fontface=font_face
		#colour="black"
	)
	
	#label_legend <- guide_legend(
	#	title = "Labels:",
	#	key.theme   = element_rect(colour = "gray30"),
	#	override.aes = list(size=5),
	#	order = 1
	#)
	label_legend <- "none"
	
	g <- g + scale_color_manual(
		values = c(col_txt_words, col_txt_vars, col_txt_vars),
		breaks = c(1,3),
		labels = c("Words / Codes", "Variables"),
		guide = label_legend
	)

	
	
	if ( exists("segs") ){
		if ( is.null(segs) == F){
			colnames(segs) <- c("x1", "y1", "x2", "y2")
			segs <- as.data.frame(segs)
			g <- g + geom_segment(
				aes(x=x1, y=y1, xend=x2, yend=y2),
				data=segs,
				colour="gray60"
			)
		}
	}
}

if (plot_mode == "vars"){
	labcd <- NULL
}

#--------------------#
#   Configurations   #

#if ( asp == 1 ){
#	g <- g + coord_fixed()
#}

g <- g + labs(
	x=paste(name_dim,d_x,"  (",inertias[d_x],",  ", k[d_x],"%)",sep=""),
	y=paste(name_dim,d_y,"  (",inertias[d_y],",  ", k[d_y],"%)",sep="")
)
g <- g + theme_classic(base_family=font_family)
g <- g + theme(
	legend.key   = element_rect(colour = NA, fill= NA),
	axis.line.x    = element_line(colour = "black", size=0.5),
	axis.line.y    = element_line(colour = "black", size=0.5),
	axis.title.x = element_text(face="plain", size=11, angle=0),
	axis.title.y = element_text(face="plain", size=11, angle=90),
	axis.text.x  = element_text(face="plain", size=11, angle=0),
	axis.text.y  = element_text(face="plain", size=11, angle=0),
	legend.title = element_text(face="bold",  size=11, angle=0),
	legend.text  = element_text(face="plain", size=11, angle=0)
)

#---------------------#
#   show the origin   #

if (show_origin == 1){
	line_color <- "gray30"
	
	lim_chk <-ggplot_build(g)
	xlims <- lim_chk$panel$ranges[[1]]$x.range
	ylims <- lim_chk$panel$ranges[[1]]$y.range
	if ( is.null(xlims) ){
		xlims <- lim_chk$layout$panel_ranges[[1]]$x.range
		ylims <- lim_chk$layout$panel_ranges[[1]]$y.range
	}
	if ( is.null(xlims) ){
		xlims <- lim_chk$layout$panel_params[[1]]$x.range
		ylims <- lim_chk$layout$panel_params[[1]]$y.range
	}

	if (zoom_factor >= 1){
		g <- g + scale_x_continuous( limits=xlims, expand=c(0,0), breaks=c(0) )
		g <- g + scale_y_continuous( limits=ylims, expand=c(0,0), breaks=c(0) )
	} else {
		g <- g + scale_x_continuous( limits=xlims, expand=c(0,0) )
		g <- g + scale_y_continuous( limits=ylims, expand=c(0,0) )
	}
	
	m_x <- (xlims[2] - xlims[1]) * 0.03
	m_y <- (ylims[2] - ylims[1]) * 0.03
	
	g <- g + geom_segment(
		aes(x = xlims[1], y = 0, xend = m_x, yend = 0),
		size=0.25,
		linetype="dashed",
		colour=line_color
	)
	g <- g + geom_segment(
		aes(x = 0, y = ylims[1], xend = 0, yend = m_y),
		size=0.25,
		linetype="dashed",
		colour=line_color
	)
} else {
	if (zoom_factor >= 1){
		g <- g + scale_x_continuous( breaks=c(0) )
		g <- g + scale_y_continuous( breaks=c(0) )
	} 
}

#-----------------------------#
#   for clickable image map   #

# fix range
if ( exists("xlimv") == F ){
	# for setting xlim & ylim
	out_coord <- cbind(
		c( df.labels.save$x, df.words$x),
		c( df.labels.save$y, df.words$y)
	)
	
	xlimv <- c(
		min( out_coord[,1] ) - 0.04 * ( max( out_coord[,1] ) - min( out_coord[,1] ) ),
		max( out_coord[,1] ) + 0.04 * ( max( out_coord[,1] ) - min( out_coord[,1] ) )
	)
	ylimv <- c(
		min( out_coord[,2] ) - 0.04 * ( max( out_coord[,2] ) - min( out_coord[,2] ) ),
		max( out_coord[,2] ) + 0.04 * ( max( out_coord[,2] ) - min( out_coord[,2] ) )
	)
	
	# for saving
	out_coord <- cbind(
		df.labels.save$x,
		df.labels.save$y
	)
	rownames(out_coord) <- df.labels.save$labs
}

m_t <- ( ylimv[2] - ylimv[1] ) * margin_top    / 100
m_b <- ( ylimv[2] - ylimv[1] ) * margin_bottom / 100
m_l <- ( xlimv[2] - xlimv[1] ) * margin_left   / 100
m_r <- ( xlimv[2] - xlimv[1] ) * margin_right  / 100

ylimv[2] <- ylimv[2] + m_t
ylimv[1] <- ylimv[1] - m_b
xlimv[1] <- xlimv[1] - m_l
xlimv[2] <- xlimv[2] + m_r

# aspect ratio
if (asp == 1){
	g <- g + coord_fixed(
		xlim=xlimv,
		ylim=ylimv,
		expand = F
	)
} else {
	g <- g + coord_cartesian(
		xlim=xlimv,
		ylim=ylimv,
		expand = F
	)
}

# coordinates for saving
if (plot_mode == "color"){
	df.labels.save <- subset(df.labels.save, cols != 3)
	out_coord <- cbind(
		df.labels.save$x,
		df.labels.save$y
	)
	rownames(out_coord) <- df.labels.save$labs
	
	add <- -1 * xlimv[1]
	div <- add + xlimv[2]
	out_coord[,1] <- ( out_coord[,1] + add ) / div
	
	add <- -1 *  ylimv[1]
	div <- add + ylimv[2]
	out_coord[,2] <- ( out_coord[,2] + add ) / div
}

# fixing width of legends to 22%
if ( bubble_plot == 0 ){
	saving_file <- 1
}

flag_printed <- 0

if ( exists("saving_file") ){
	if ( saving_file == 0){
		if ( as.numeric( substr( packageVersion("ggplot2"), 1, 1) ) <= 2 ){   # ggplot2 v2.x.x
			library(grid)
			library(gtable)
			g <- ggplotGrob(g)
			target_legend_width <- convertX(
				unit( image_width * 0.22, "in" ),
				"mm"
			)
			diff_mm <- diff( c(
				convertX( g$widths[5], "mm" ),
				target_legend_width
			))
			if ( diff_mm > 0 ){
				g <- gtable_add_cols(g, unit(diff_mm, "mm"))
			}
			
			# fixing width of left spaces to 4.25 char (we need this with ggplot2 v3.x.x too???)
			diff_char <- diff( c(
				convertX( g$widths[1] + g$widths[2] + g$widths[3], "char" ),
				unit(4.25, "char")
			))
			if ( diff_char > 0 ){
				g <- gtable_add_cols(g, unit(diff_char, "char"), pos=0)
			}
			grid.draw(g)
			flag_printed <- 1
		} else {                                                              # ggplot2 v3.x.x
			library(cowplot)
			grid <- plot_grid(
				g + theme(legend.position = "none"), # plot without legends
				get_legend(g),                       # legends only
				rel_widths = c(78, 22),
				#labels = c("A", "B"),
				nrow = 1
			)
			print(grid)
			flag_printed <- 1
		}
	}
}

if (flag_printed == 0){
	print(g)
}



';
}


#--------------#
#   アクセサ   #


sub label{
	return kh_msg->get('win_title'); # 抽出語・対応分析：オプション
}

sub win_name{
	return 'w_word_corresp';
}

sub min{
	my $self = shift;
	return $self->{words_obj}->min;
}
sub max{
	my $self = shift;
	return $self->{words_obj}->max;
}
sub min_df{
	my $self = shift;
	return $self->{words_obj}->min_df;
}
sub max_df{
	my $self = shift;
	return $self->{words_obj}->max_df;
}
sub tani{
	my $self = shift;
	return $self->{words_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{words_obj}->hinshi;
}



1;