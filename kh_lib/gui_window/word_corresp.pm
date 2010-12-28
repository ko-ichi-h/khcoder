package gui_window::word_corresp;
use base qw(gui_window);

use strict;
use Tk;

use kh_r_plot;
use gui_widget::tani;
use gui_widget::hinshi;
use mysql_crossout;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));

	my $lf = $win->LabFrame(
		-label => 'Words',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1, -side => 'left');

	$lf->Label(
		-text => gui_window->gui_jchar('■布置する語の選択'),
		-font => "TKFN",
		-foreground => 'blue'
	)->pack(-anchor => 'w', -pady => 2);

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf,
		verb   => '布置',
		type   => 'corresp',
	);


	my $lf2 = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0);

	# 入力データの設定

	$lf2->Label(
		-text => $self->gui_jchar('■対応分析の設定'),
		-font => "TKFN",
		-foreground => 'blue'
	)->pack(-anchor => 'w', -pady => 2);

	$lf2->Label(
		-text => $self->gui_jchar('分析に使用するクロス表の種類：'),
		-font => "TKFN",
	)->pack(-anchor => 'nw', -padx => 2, -pady => 2);

	my $fi = $lf2->Frame()->pack(
		-fill   => 'x',
		-expand => 0,
		-padx   => 2,
		-pady   => 2
	);

	$fi->Label(
		-text => $self->gui_jchar('　　','euc'),
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
		-fill   => 'x',
		-expand => 0
	);

	$self->{radio} = 0;
	$fi_1->Radiobutton(
		-text             => $self->gui_jchar('抽出語 ｘ 文書'),
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 0,
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w');

	my $fi_2 = $fi_1->Frame()->pack(-anchor => 'w');
	$fi_2->Label(
		-text => $self->gui_jchar('　　','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{label_high} = $fi_2->Label(
		-text => $self->gui_jchar('集計単位：','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{opt_frame_high} = $fi_2;
	
	my $fi_4 = $fi_1->Frame()->pack(-anchor => 'w');
	$fi_4->Label(
		-text => $self->gui_jchar('　　','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{label_high2} = $fi_4->Checkbutton(
		-text     => $self->gui_jchar('見出しまたは文書番号を同時布置'),
		-variable => \$self->{biplot},
	)->pack(
		-anchor => 'w',
		-side  => 'left',
	);

	$fi_1->Radiobutton(
		-text             => $self->gui_jchar('抽出語 ｘ 外部変数'),
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 1,
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w');

	my $fi_3 = $fi_1->Frame()->pack(-anchor => 'w');
	$fi_3->Label(
		-text => $self->gui_jchar('　　','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{label_var} = $fi_3->Label(
		-text => $self->gui_jchar('変数：','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{opt_frame_var} = $fi_3;
	$self->refresh;

	# 差異の顕著な語のみ分析
	my $fsw = $lf2->Frame()->pack(
		-fill => 'x',
		-pady => 2,
	);

	$fsw->Checkbutton(
		-text     => $self->gui_jchar('差異が顕著な語を分析に使用：'),
		-variable => \$self->{check_filter_w},
		-command  => sub{ $self->refresh_flw;},
	)->pack(
		-anchor => 'w',
		-side  => 'left',
	);

	$self->{entry_flw_l1} = $fsw->Label(
		-text => $self->gui_jchar('上位'),
		-font => "TKFN",
	)->pack(-side => 'left', -padx => 0);

	$self->{entry_flw} = $fsw->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 0);
	$self->{entry_flw}->insert(0,'50');
	$self->{entry_flw}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_flw});

	$self->{entry_flw_l2} = $fsw->Label(
		-text => $self->gui_jchar('語'),
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
		-text     => $self->gui_jchar('原点から離れた語のみラベル表示：'),
		-variable => \$self->{check_filter},
		-command  => sub{ $self->refresh_flt;},
	)->pack(
		-anchor => 'w',
		-side  => 'left',
	);

	$self->{entry_flt_l1} = $fs->Label(
		-text => $self->gui_jchar('上位'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_flt} = $fs->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 0);
	$self->{entry_flt}->insert(0,'50');
	$self->{entry_flt}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_flt});

	$self->{entry_flt_l2} = $fs->Label(
		-text => $self->gui_jchar('語'),
		-font => "TKFN",
	)->pack(-side => 'left');
	$self->refresh_flt;

	# 成分
	my $fd = $lf2->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 2,
	);

	$fd->Label(
		-text => $self->gui_jchar('プロットする成分：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	#$self->{entry_d_n} = $fd->Entry(
	#	-font       => "TKFN",
	#	-width      => 2,
	#	-background => 'white',
	#)->pack(-side => 'left', -padx => 2);
	#$self->{entry_d_n}->insert(0,'2');
	#$self->{entry_d_n}->bind("<Key-Return>",sub{$self->calc;});
	#$self->config_entry_focusin($self->{entry_d_n});

	$fd->Label(
		-text => $self->gui_jchar(' X軸'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_d_x} = $fd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_d_x}->insert(0,'1');
	$self->{entry_d_x}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_d_x});

	$fd->Label(
		-text => $self->gui_jchar(' Y軸'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_d_y} = $fd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_d_y}->insert(0,'2');
	$self->{entry_d_y}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_d_y});

	# フォントサイズ
	my $ff = $lf2->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 4,
	);

	$ff->Label(
		-text => $self->gui_jchar('フォントサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_font_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_font_size}->insert(0,'80');
	$self->{entry_font_size}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_font_size});

	$ff->Label(
		-text => $self->gui_jchar('%'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$ff->Label(
		-text => $self->gui_jchar('  プロットサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_plot_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_plot_size}->insert(0,'640');
	$self->{entry_plot_size}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_plot_size});

	$win->Checkbutton(
			-text     => $self->gui_jchar('実行時にこの画面を閉じない','euc'),
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$win->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->calc;});}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se');

	$self->_settings_load;

	return $self;
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
	$settings->{d_x}       = $self->gui_jg( $self->{entry_d_x}->get );
	$settings->{d_y}       = $self->gui_jg( $self->{entry_d_y}->get );
	$settings->{plot_size} = $self->gui_jg( $self->{entry_plot_size}->get );
	$settings->{font_size} = $self->gui_jg( $self->{entry_font_size}->get );

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
		$self->{opt_body_var}->set_value( $settings->{var_id} );
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
		# 利用できる変数があるかどうかチェック
		my $h = mysql_outvar->get_list;
		my @options = ();
		foreach my $i (@{$h}){
			push @options, [$self->gui_jchar($i->[1]), $i->[2]];
		}
		
		if (@options){
			$self->{opt_body_var} = gui_widget::optmenu->open(
				parent  => $self->{opt_frame_var},
				pack    => {-side => 'left', -padx => 2},
				options => \@options,
				variable => \$self->{var_id},
			);
			$self->{opt_body_var_ok} = 1;
		} else {
			$self->{opt_body_var} = gui_widget::optmenu->open(
				parent  => $self->{opt_frame_var},
				pack    => {-side => 'left', -padx => 2},
				options => 
					[
						[$self->gui_jchar('利用不可'), undef],
					],
				variable => \$self->{var_id},
			);
			$self->{opt_body_var_ok} = 0;
		}
	}

	#------------------------------#
	#   上位の文書単位選択Widget   #

	unless ($self->{opt_body_high}){

		my %tani_name = (
			"bun" => "文",
			"dan" => "段落",
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
			);
			$self->{opt_body_high_ok} = 1;
		} else {
			$self->{opt_body_high} = gui_widget::optmenu->open(
				parent  => $self->{opt_frame_high},
				pack    => {-side => 'left', -padx => 2},
				options => 
					[
						[$self->gui_jchar('利用不可'), undef],
					],
				variable => \$self->{high},
			);
			$self->{opt_body_high_ok} = 0;
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
		
		$self->{opt_body_var}->configure(-state => 'disable');
		$self->{label_var}->configure(-foreground => 'gray');
	}
	elsif ($self->{radio} == 1){
		$self->{opt_body_high}->configure(-state => 'disable');
		$self->{label_high}->configure(-foreground => 'gray');
		$self->{label_high2}->configure(-state => 'disable');

		if ($self->{opt_body_var_ok}){
			$self->{opt_body_var}->configure(-state => 'normal');
		} else {
			$self->{opt_body_var}->configure(-state => 'disable');
		}
		$self->{label_var}->configure(-foreground => 'black');
	}
	
	return 1;
}

#----------#
#   実行   #

sub calc{
	my $self = shift;
	
	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}
	
	my $tani2 = '';
	if ($self->{radio} == 0){
		$tani2 = $self->gui_jg($self->{high});
	}
	elsif ($self->{radio} == 1){
		if ( length($self->{var_id}) ){
			$tani2 = mysql_outvar::a_var->new(undef,$self->{var_id})->{tani};
		}
	}

	unless ($tani2){
		gui_errormsg->open(
			type => 'msg',
			msg  => '集計単位または変数の選択が不正です。',
		);
		return 0;
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
			msg  => '少なくとも3つ以上の抽出語を布置して下さい。',
		);
		return 0;
	}

	if ($check_num > 200){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					 '現在の設定では'.$check_num.'語が布置されます。'
					."\n"
					.'布置する語の数は100〜150程度におさえることを推奨します。'
					."\n"
					.'続行してよろしいですか？'
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
	}

	$self->_settings_save;

	my $ans = $self->win_obj->messageBox(
		-message => $self->gui_jchar
			(
			   "この処理には時間がかかることがあります。\n".
			   "続行してよろしいですか？"
			),
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	unless ($ans =~ /ok/i){ return 0; }

	#my $w = gui_wait->start;

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
	)->run;

	# 外部変数の付与
	if ($self->{radio} == 1){
		unless ($self->{var_id}){
			gui_errormsg->open(
				type   => 'msg',
				window  => \$self->win_obj,
				msg    => "外部変数の選択が不正です。"
			);
			return 0;
		}
		my $var_obj = mysql_outvar::a_var->new(undef,$self->{var_id});
		
		my $sql = '';
		$sql .= "SELECT $var_obj->{column} FROM $var_obj->{table} ";
		$sql .= "ORDER BY id";
		
		$r_command .= "v <- c(";
		my $h = mysql_exec->select($sql,1)->hundle;
		my $n = 0;
		while (my $i = $h->fetch){
			if ( length( $var_obj->{labels}{$i->[0]} ) ){
				my $t = $var_obj->{labels}{$i->[0]};
				$t =~ s/"/ /g;
				$r_command .= "\"$t\",";
			} else {
				$r_command .= "\"$i->[0]\",";
			}
			++$n;
		}
		
		chop $r_command;
		$r_command .= ")\n";
		$r_command .= &r_command_aggr;
	}

	# 空の行・空の列を削除
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

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	my $filter = 0;
	if ( $self->{check_filter} ){
		$filter = $self->gui_jg( $self->{entry_flt}->get );
	}

	my $filter_w = 0;
	if ( $self->{check_filter_w} ){
		$filter_w = $self->gui_jg( $self->{entry_flw}->get );
	}

	&make_plot(
		#d_n          => $self->gui_jg( $self->{entry_d_n}->get ),
		d_x          => $self->gui_jg( $self->{entry_d_x}->get ),
		d_y          => $self->gui_jg( $self->{entry_d_y}->get ),
		flt          => $filter,
		flw          => $filter_w,
		biplot       => $biplot,
		plot_size    => $self->gui_jg( $self->{entry_plot_size}->get ),
		font_size    => $fontsize,
		r_command    => $r_command,
		plotwin_name => 'word_corresp',
	);

	unless ( $self->{check_rm_open} ){
		$self->close;
	}

}


sub make_plot{
	my %args = @_;
	$args{flt} = 0 unless $args{flt};
	$args{flw} = 0 unless $args{flw};

	my $fontsize = $args{font_size};
	my $r_command = $args{r_command};

	kh_r_plot->clear_env;

	$r_command .= "d_x <- $args{d_x}\n";
	$r_command .= "d_y <- $args{d_y}\n";
	$r_command .= "flt <- $args{flt}\n";
	$r_command .= "flw <- $args{flw}\n";

	$r_command .= "library(MASS)\n";
	#$r_command .= "c <- corresp(d, nf=min( nrow(d), ncol(d) ) )\n";

	$r_command .= &r_command_filter;

	$r_command .= "k <- c\$cor^2\n";
	$r_command .=
		"txt <- cbind( 1:length(k), round(k,4), round(100*k / sum(k),2) )\n";
	$r_command .= "colnames(txt) <- c('成分','固有値','寄与率')\n";
	$r_command .= "print( txt )\n";
	$r_command .= "k <- round(100*k / sum(k),2)\n";

	# プロットのためのRコマンド

	my ($r_command_2a, $r_command_2, $r_command_a);
	my ($r_com_gray, $r_com_gray_a);
	if ($args{biplot} == 0){                      # 同時布置なし
		# ラベルとドットをプロット
		$r_command_2a = 
			 "plot(cb <- cbind(c\$cscore[,d_x], c\$cscore[,d_y], ptype),"
				.'col=c("mediumaquamarine","mediumaquamarine","#ADD8E6")[cb[,3]],'
				.'pch=c(20,0,1)[cb[,3]],'
				.'xlab=paste("成分",d_x,"（",k[d_x],"%）",sep=""),'
				.'ylab=paste("成分",d_y,"（",k[d_y],"%）",sep="")'
				.")\n"
			."library(maptools)\n"
			."pointLabel(x=c\$cscore[,d_x], y=c\$cscore[,d_y],"
				."labels=rownames(c\$cscore), cex=$fontsize, offset=0)\n";
		;
		$r_command_2 = $r_command.$r_command_2a;
		
		# ドットのみプロット
		$r_command_a .=
			 "plot(cb <- cbind(c\$cscore[,d_x], c\$cscore[,d_y], ptype),"
				.'pch=c(1,15,4)[cb[,3]],'
				.'xlab=paste("成分",d_x,"（",k[d_x],"%）",sep=""),'
				.'ylab=paste("成分",d_y,"（",k[d_y],"%）",sep="")'
				.")\n"
		;
	} else {                                      # 同時布置あり
		# ラベルとドットをプロット
		$r_command_2a .= 
			 'plot(cb <- rbind('
				."cbind(c\$cscore[,d_x], c\$cscore[,d_y], ptype),"
				."cbind(c\$rscore[,d_x], c\$rscore[,d_y], 2)"
				.'),'
				.'pch=c(20,0,1)[cb[,3]],'
				.'col=c("mediumaquamarine","mediumaquamarine","#ADD8E6")[cb[,3]],'
				.'xlab=paste("成分",d_x,"（",k[d_x],"%）",sep=""),'
				.'ylab=paste("成分",d_y,"（",k[d_y],"%）",sep="")'
				." )\n"
			."library(maptools)\n"
			."labcd <- pointLabel("
				."x=c(c\$cscore[,d_x], c\$rscore[,d_x]),"
				."y=c(c\$cscore[,d_y], c\$rscore[,d_y]),"
				."labels=c(rownames(c\$cscore),rownames(c\$rscore)),"
				."cex=$fontsize,offset=0,doPlot=F)\n"
			.'text('
				.'labcd$x, labcd$y, rownames(cb),'
				."cex=$fontsize,"
				.'offset=0,'
				.'col=c("black","red","black")[cb[,3]]'
				.')'."\n"
		;
		$r_command_2 = $r_command.$r_command_2a;
		
		# グレースケールのプロット
		$r_com_gray_a .= &r_command_slab_my;
		$r_com_gray_a .= 
			 'plot(cb <- rbind('
				."cbind(c\$cscore[,d_x], c\$cscore[,d_y], ptype),"
				."cbind(c\$rscore[,d_x], c\$rscore[,d_y], 2)"
				.'),'
				.'pch=c(20,0,1)[cb[,3]],'
				.'col=c("gray65","gray50","gray65")[cb[,3]],'
				.'xlab=paste("成分",d_x,"（",k[d_x],"%）",sep=""),'
				.'ylab=paste("成分",d_y,"（",k[d_y],"%）",sep="")'
				.")\n"
		;
		$r_com_gray =                             # command_fにのみ追加
			 $r_command
			.$r_com_gray_a
			."library(maptools)\n"
			."labcd <- pointLabel("
				."x=c(c\$cscore[,d_x], c\$rscore[,d_x]),"
				."y=c(c\$cscore[,d_y], c\$rscore[,d_y]),"
				."labels=c(rownames(c\$cscore),rownames(c\$rscore)),"
				."cex=$fontsize,offset=0,doPlot=F)\n"
		;
		my $temp_cmd =                            # _f・_aに共通
			 "cb  <- cbind(cb, labcd\$x, labcd\$y)\n"
			."cb1 <-  subset(cb, cb[,3]==1)\n"
			."cb2 <-  subset(cb, cb[,3]==2)\n"
			.'text('
				.'cb1[,4], cb1[,5], rownames(cb1),'
				."cex=$fontsize,"
				.'offset=0,'
				.'col="black",'
				.')'."\n"
			."library(ade4)\n"
			.'s.label_my(cb2, xax=4, yax=5, label=rownames(cb2),'
				.'boxes=T,'
				."clabel=$fontsize,"
				.'addaxes=F,'
				.'include.origin=F,'
				.'grid=F,'
				.'cpoint=0,'
				.'cneig=0,'
				.'cgrid=0,'
				.'add.plot=T,'
				.')'."\n"
			.'points(cb2[,1], cb2[,2], pch=0, col="gray50")'."\n"
		;
		$r_com_gray   .= $temp_cmd;
		$r_com_gray_a .= $temp_cmd;

		# ドットのみをプロット
		$r_command_a .=
			 'plot(cb <- rbind('
				."cbind(c\$cscore[,d_x], c\$cscore[,d_y], ptype),"
				."cbind(c\$rscore[,d_x], c\$rscore[,d_y], 2)"
				.'),'
				.'pch=c(1,15,4)[cb[,3]],'
				.'xlab=paste("成分",d_x,"（",k[d_x],"%）",sep=""),'
				.'ylab=paste("成分",d_y,"（",k[d_y],"%）",sep="")'
				.")\n"
		;
	}

	$r_command .= $r_command_a;

	# プロット作成
	my $flg_error = 0;
	my $plot1 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		#command_a => $r_command_a,
		command_f => $r_command,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or $flg_error = 1;

	my $plot2 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_2',
		command_a => $r_command_2a,
		command_f => $r_command_2,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or $flg_error = 1;

	my $plotg;
	my @plots = ();
	if ($r_com_gray_a){
		my $plotg = kh_r_plot->new(
			name      => $args{plotwin_name}.'_g',
			command_a => $r_com_gray_a,
			command_f => $r_com_gray,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;
		@plots = ($plot2,$plotg,$plot1);
	} else {
		@plots = ($plot2,$plot1);
	}

	my $txt = $plot1->r_msg;
	if ( length($txt) ){
		$txt = Jcode->new($txt)->sjis if $::config_obj->os eq 'win32';
		print "-------------------------[Begin]-------------------------[R]\n";
		print "$txt\n";
		print "---------------------------------------------------------[R]\n";
	}

	# プロットWindowを開く
	kh_r_plot->clear_env;
	my $plotwin_id = 'w_'.$args{plotwin_name}.'_plot';
	if ($::main_gui->if_opened($plotwin_id)){
		$::main_gui->get($plotwin_id)->close;
	}
	my $plotwin = 'gui_window::r_plot::'.$args{plotwin_name};
	
	return 0 if $flg_error;
	
	$plotwin->open(
		plots       => \@plots,
		no_geometry => 1,
	);

}

sub r_command_aggr{
	my $t = << 'END_OF_the_R_COMMAND';

d              <- aggregate(d,list(name = v), sum)
doc_length_mtr <- aggregate(doc_length_mtr,list(name = v), sum)

row.names(d) <- d$name
d$name <- NULL
row.names(doc_length_mtr) <- doc_length_mtr$name
doc_length_mtr$name <- NULL

d              <- d[              order(rownames(d             )), ]
doc_length_mtr <- doc_length_mtr[ order(rownames(doc_length_mtr)), ]

doc_length_mtr <- subset(
	doc_length_mtr,
	row.names(d) != "欠損値" & row.names(d) != "." & row.names(d) != "missing"
)
d <- subset(
	d,
	row.names(d) != "欠損値" & row.names(d) != "." & row.names(d) != "missing"
)

END_OF_the_R_COMMAND
return $t;
}

sub r_command_filter{
	my $t = << 'END_OF_the_R_COMMAND';

# 差異の顕著な語のみ分析に使用
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
	d <- subset(d, rowSums(d) > 0)
}

c <- corresp(d, nf=min( nrow(d), ncol(d) ) )

# 特徴的な語のみラベル表示
if ( (flt > 0) && (flt < nrow(c$cscore)) ){
	sort  <- NULL
	limit <- NULL
	names <- NULL
	ptype <- NULL
	
	# 原点からの距離を計算
	for (i in 1:nrow(c$cscore) ){
		sort <- c(sort, c$cscore[i,d_x] ^ 2 + c$cscore[i,d_y] ^ 2 )
	}
	
	# 上位のもののみラベル付け
	limit <- sort[order(sort,decreasing=T)][flt]
	for (i in 1:nrow(c$cscore) ){
		if ( sort[i] >= limit ){
			names <- c(names, rownames(c$cscore)[i])
			ptype <- c(ptype, 1)
		} else {
			names <- c(names, NA)
			ptype <- c(ptype, 3)
		}
	}
	rownames(c$cscore) <- names;
} else {
	ptype <- 1
}

END_OF_the_R_COMMAND
return $t;
}


sub r_command_slab_my{
	return '
# 枠付きプロット関数の設定
s.label_my <- function (dfxy, xax = 1, yax = 2, label = row.names(dfxy),
    clabel = 1, 
    pch = 20, cpoint = if (clabel == 0) 1 else 0, boxes = TRUE, 
    neig = NULL, cneig = 2, xlim = NULL, ylim = NULL, grid = TRUE, 
    addaxes = TRUE, cgrid = 1, include.origin = TRUE, origin = c(0, 
        0), sub = "", csub = 1.25, possub = "bottomleft", pixmap = NULL, 
    contour = NULL, area = NULL, add.plot = FALSE) 
{
    dfxy <- data.frame(dfxy)
    opar <- par(mar = par("mar"))
    on.exit(par(opar))
    par(mar = c(0.1, 0.1, 0.1, 0.1))
    coo <- scatterutil.base(dfxy = dfxy, xax = xax, yax = yax, 
        xlim = xlim, ylim = ylim, grid = grid, addaxes = addaxes, 
        cgrid = cgrid, include.origin = include.origin, origin = origin, 
        sub = sub, csub = csub, possub = possub, pixmap = pixmap, 
        contour = contour, area = area, add.plot = add.plot)
    if (!is.null(neig)) {
        if (is.null(class(neig))) 
            neig <- NULL
        if (class(neig) != "neig") 
            neig <- NULL
        deg <- attr(neig, "degrees")
        if ((length(deg)) != (length(coo$x))) 
            neig <- NULL
    }
    if (!is.null(neig)) {
        fun <- function(x, coo) {
            segments(coo$x[x[1]], coo$y[x[1]], coo$x[x[2]], coo$y[x[2]], 
                lwd = par("lwd") * cneig)
        }
        apply(unclass(neig), 1, fun, coo = coo)
    }
    if (clabel > 0) 
        scatterutil.eti(coo$x, coo$y, label, clabel, boxes)
    if (cpoint > 0 & clabel < 1e-06) 
        points(coo$x, coo$y, pch = pch, cex = par("cex") * cpoint)
    #box()
    invisible(match.call())
}
';

}
#--------------#
#   アクセサ   #


sub label{
	return '抽出語・対応分析：オプション';
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