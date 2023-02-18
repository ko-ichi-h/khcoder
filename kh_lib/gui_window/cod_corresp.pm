package gui_window::cod_corresp;
use base qw(gui_window);
use utf8;
use strict;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # コーディング・対応分析：オプション

	my $lf = $win->LabFrame(
		-label => 'Codes',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 0, -side => 'left',-anchor => 'w');

	my $rf = $win->Frame()
		->pack(-fill => 'both', -expand => 1);

	my $lf2 = $rf->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);


	# ルール・ファイル
	my %pack0 = (
		-anchor => 'w',
		#-padx => 2,
		#-pady => 2,
		-fill => 'x',
		-expand => 0,
	);
	$self->{codf_obj} = gui_widget::codf->open(
		parent  => $lf,
		pack    => \%pack0,
		command => sub{$self->read_cfile;},
	);
	
	# コーディング単位
	my $f1 = $lf->Frame()->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 4
	);
	$f1->Label(
		-text => kh_msg->get('coding_unit'), # コーディング単位：
		-font => "TKFN",
	)->pack(-side => 'left');
	my %pack1 = (
		-anchor => 'w',
		-padx => 2,
		-pady => 2,
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $f1,
		command => sub { $self->refresh; $self->biplot_config; },
		pack   => \%pack1,
	);

	# コード選択
	$lf->Label(
		-text => kh_msg->get('select_codes'), # コード選択：
		-font => "TKFN",
	)->pack(-anchor => 'nw', -padx => 2, -pady => 0);

	my $f2 = $lf->Frame()->pack(
		-fill   => 'both',
		-expand => 1,
		-padx   => 2,
		-pady   => 2
	);

	$f2->Label(
		-text => '    ',
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);

	my $f2_1 = $f2->Frame(
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

	# コード選択用HList
	$self->{hlist} = $f2_1->Scrolled(
		'HList',
		-scrollbars         => 'osoe',
		#-relief             => 'sunken',
		-font               => 'TKFN',
		-selectmode         => 'none',
		-indicator => 0,
		-highlightthickness => 0,
		-columns            => 1,
		-borderwidth        => 0,
		-height             => 12,
	)->pack(
		-fill   => 'both',
		-expand => 1
	);

	my $f2_2 = $f2->Frame()->pack(
		-fill   => 'x',
		-expand => 0,
		-side   => 'left'
	);
	$f2_2->Button(
		-text => kh_msg->gget('all'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->select_all;}
	)->pack(-pady => 3);
	$f2_2->Button(
		-text => kh_msg->gget('clear'),,
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->select_none;}
	)->pack();

	$lf->Label(
		-text => kh_msg->get('sel3'), # 　　※コードを3つ以上選択して下さい。
		-font => "TKFN",
	)->pack(
		-anchor => 'w',
		-padx   => 4,
		-pady   => 2,
	);

	# 入力データの設定
	$lf2->Label(
		-text => kh_msg->get('matrix_type'), # 分析に使用するデータ表の種類：
		-font => "TKFN",
	)->pack(-anchor => 'nw', -padx => 2, -pady => 0);

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

	$self->{radio} = 1;
	#$fi_1->Radiobutton(
	#	-text             => kh_msg->get('c_d'), # コード ｘ 文書（同時布置なし）
	#	-font             => "TKFN",
	#	-variable         => \$self->{radio},
	#	-value            => 0,
	#	-command          => sub{ $self->refresh;},
	#)->pack(-anchor => 'w');

	$fi_1->Radiobutton(
		-text             => kh_msg->get('c_dd'), # コード ｘ 上位の章・節・段落
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 1,
		-command          => sub{ $self->refresh; $self->biplot_config;},
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
		-text => kh_msg->get('gui_window::word_corresp->unit'), # 集計単位：
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
	$self->{biplot} = 1;
	$self->{label_high2} = $fi_4->Checkbutton(
		-text     => kh_msg->get('gui_window::word_corresp->biplot'), # 見出しまたは文書番号を同時布置
		-variable => \$self->{biplot},
	)->pack(
		-anchor => 'w',
		-side  => 'left',
	);

	$fi_1->Radiobutton(
		-text             => kh_msg->get('c_v'), # コード ｘ 外部変数
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 2,
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w');

	my $fi_3 = $fi_1->Frame()->pack(
		-anchor => 'w',
		-fill   => 'both',
		-expand => 1,
	);
	$self->{label_var} = $fi_3->Label(
		-text => '    ',
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{opt_frame_var} = $fi_3;

	my $vars = mysql_outvar->get_list;
	$vars = @{$vars};
	if ( $::project_obj->status_from_table == 1 && $vars ){
		$self->{radio} = 2;
	}

	# 差異の顕著な語のみ分析
	my $fsw = $lf2->Frame()->pack(
		-fill => 'x',
		-pady => 2,
	);

	$self->{check_filter_w} = 1;
	$self->{check_filter_w_widget} = $fsw->Checkbutton(
		-text     => kh_msg->get('flw'), # 差異が顕著なコードを分析に使用：
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
	$self->{entry_flw}->insert(0,'50');
	$self->{entry_flw}->bind("<Key-Return>",sub{$self->_calc;});
	$self->{entry_flw}->bind("<KP_Enter>",sub{$self->_calc;});
	$self->config_entry_focusin($self->{entry_flw});

	$self->refresh_flw;

	# 特徴的な語のみラベル表示
	my $fs = $lf2->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 2,
	);

	$fs->Checkbutton(
		-text     => kh_msg->get('flt'), # 原点から離れたコードのみラベル表示：
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
	$self->{entry_flt}->insert(0,'50');
	$self->{entry_flt}->bind("<Key-Return>",sub{$self->_calc;});
	$self->{entry_flt}->bind("<KP_Enter>",sub{$self->_calc;});
	$self->config_entry_focusin($self->{entry_flt});

	$self->refresh_flt;

	$self->refresh;

	# バブルプロット
	$self->{bubble_obj} = gui_widget::bubble->open(
		parent       => $lf2,
		type         => 'corresp',
		command      => sub{ $self->_calc; },
		pack    => {
			-anchor   => 'w',
		},
	);

	# 成分
	$self->{xy_obj} = gui_widget::r_xy->open(
		parent    => $lf2,
		command   => sub{ $self->_calc; },
		pack      => { -anchor => 'w', -pady => 2 },
	);

	# フォントサイズ
	$self->{font_obj} = gui_widget::r_font->open(
		parent    => $lf2,
		command   => sub{ $self->_calc; },
		pack      => { -anchor   => 'w' },
		show_bold => 1,
		plot_size => $::config_obj->plot_size_codes,
	);

	#SCREEN Plugin
	use screen_code::correspond;
	&screen_code::correspond::add_menu($self,$lf2,1);
	#SCREEN Plugin

	$rf->Checkbutton(
			-text     => kh_msg->gget('r_dont_close'),
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	# OK・キャンセル
	my $f3 = $rf->Frame()->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 2
	);

	$f3->Button(
		-text => kh_msg->gget('cancel'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2);

	$self->{ok_btn} = $f3->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-state => 'disable',
		-command => sub{$self->_calc;}
	)->pack(-side => 'right');
	$self->{ok_btn}->focus;

	$self->read_cfile;

	return $self;
}

# 「特徴語に注目」のチェックボックス
sub refresh_flt{
	my $self = shift;
	if ( $self->{check_filter} ){
		$self->{entry_flt}   ->configure(-state => 'normal');
		$self->{entry_flt_l1}->configure(-state => 'normal');
	} else {
		$self->{entry_flt}   ->configure(-state => 'disabled');
		$self->{entry_flt_l1}->configure(-state => 'disabled');
	}
	return $self;
}

sub refresh_flw{
	my $self = shift;
	if ( $self->{check_filter_w} ){
		$self->{entry_flw}   ->configure(-state => 'normal');
		$self->{entry_flw_l1}->configure(-state => 'normal');
	} else {
		$self->{entry_flw}   ->configure(-state => 'disabled');
		$self->{entry_flw_l1}->configure(-state => 'disabled');
	}
	return $self;
}

sub refresh_same_doc_unit{
	my $self = shift;
	if ( $self->tani eq $self->{high} ){
		$self->{check_filter_w_widget}->configure(-state => 'disabled');
		$self->{entry_flw}   ->configure(-state => 'disabled');
		$self->{entry_flw_l1}->configure(-state => 'disabled');
	} else {
		$self->{check_filter_w_widget}->configure(-state => 'normal');
		$self->refresh_flw;
	}
}

sub biplot_config{
	my $self = shift;
	
	my $tani2 = $self->{high};
	return 0 unless $tani2;

	my $n = mysql_exec->select("select count(*) from $tani2",1)->hundle->fetch->[0];
	
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

# ラジオボタン関連
sub refresh{
	my $self = shift;
	unless ($self->{tani_obj}){return 0;}

	#------------------------#
	#   外部変数選択Widget   #

	unless ($self->{last_tani} eq $self->tani){
		if ($self->{opt_body_var}){
			$self->{opt_body_var}->destroy;
		}

		# 利用できる変数をチェック
		my %tani_check = ();
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			$tani_check{$i} = 1;
			last if ($self->tani eq $i);
		}
		# これ何だろう？ 2011 06/16
		#if ($self->tani eq 'bun'){
		#	%tani_check = ();
		#	$tani_check{'bun'} = 1;
		#}
		
		$self->{last_tani} = $self->tani;
		
		my $h = mysql_outvar->get_list;
		my @options = ();
		foreach my $i (@{$h}){
			if ($tani_check{$i->[0]}){
				push @options, [$self->gui_jchar($i->[1]), $i->[2]];
				#print "varid: $i->[2]\n";
			}
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

	#------------------------------#
	#   上位の文書単位選択Widget   #

		my @tanis   = ();
		if ($self->{opt_body_high}){
			$self->{opt_body_high}->destroy;
		}

		my %tani_name = (
			"bun" => kh_msg->gget('sentence'), # 文
			"dan" => kh_msg->gget('paragraph'), # 段落
			"h5"  => "H5",
			"h4"  => "H4",
			"h3"  => "H3",
			"h2"  => "H2",
			"h1"  => "H1",
		);

		@tanis = ();
		my $if_old_v_is_valid = 0;
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			if (
				mysql_exec->select(
					"select status from status where name = \'$i\'",1
				)->hundle->fetch->[0]
			){
				# コーディング単位が「文」の場合、「段落」単位での集計は不可
				# （見出し文が存在するため）
				if (
					   $i eq 'dan'
					&& $self->tani eq 'bun'
					&& @tanis
				) {
					next;
				}
				
				push @tanis, [ $tani_name{$i}, $i ];
				$if_old_v_is_valid = 1 if $i eq $self->{high};
			}
			last if ($self->tani eq $i);
		}
		$self->{high} = undef unless $if_old_v_is_valid;

		if (@tanis){
			$self->{opt_body_high} = gui_widget::optmenu->open(
				parent  => $self->{opt_frame_high},
				pack    => {-side => 'left', -padx => 2},
				options => \@tanis,
				variable => \$self->{high},
				command => sub{$self->refresh_same_doc_unit; $self->biplot_config;},
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
	}

	#----------------------------------#
	#   Widgetの有効・無効を切り替え   #

	if ($self->{radio} == 0){
		$self->{opt_body_high}->configure(-state => 'disable');
		$self->{label_high}->configure(-foreground => 'gray');
		
		$self->{opt_body_var}->configure(-selectbackground => 'gray');
		$self->{opt_body_var}->configure(-background => 'gray');
		
		$self->{check_filter_w_widget}->configure(-state => 'disabled');
		$self->{entry_flw}   ->configure(-state => 'disabled');
		$self->{entry_flw_l1}->configure(-state => 'disabled');
	}
	elsif ($self->{radio} == 1){
		if ($self->{opt_body_high_ok}){
			$self->{opt_body_high}->configure(-state => 'normal');
		} else {
			$self->{opt_body_high}->configure(-state => 'disable');
		}
		$self->{label_high}->configure(-foreground => 'black');
		
		$self->{opt_body_var}->configure(-selectbackground => 'gray');
		$self->{opt_body_var}->configure(-background => 'gray');

		$self->{check_filter_w_widget}->configure(-state => 'normal');
		$self->{label_high2}->configure(-state => 'normal');
		$self->refresh_flw;
		$self->refresh_flt;
		
		$self->refresh_same_doc_unit;
		#$self->{entry_flw}   ->configure(-state => 'normal');
		#$self->{entry_flw_l1}->configure(-state => 'normal');
	}
	elsif ($self->{radio} == 2){
		$self->{opt_body_high}->configure(-state => 'disable');
		$self->{label_high2}->configure(-state => 'disable');
		$self->{label_high}->configure(-foreground => 'gray');

		$self->{opt_body_var}->configure(-selectbackground => $::config_obj->color_ListHL_back);
		$self->{opt_body_var}->configure(-background => 'white');
		gui_hlist->update4scroll( $self->{opt_body_var} );

		$self->{check_filter_w_widget}->configure(-state => 'normal');
		$self->refresh_flw;
		#$self->{entry_flw}   ->configure(-state => 'normal');
		#$self->{entry_flw_l1}->configure(-state => 'normal');
	}
	
	return 1;
}

# コーディングルール・ファイルの読み込み
sub read_cfile{
	my $self = shift;
	
	$self->{hlist}->delete('all');
	
	unless (-e $self->cfile ){
		return 0;
	}
	
	my $cod_obj = kh_cod::func->read_file($self->cfile);
	
	unless (eval(@{$cod_obj->codes})){
		return 0;
	}

	my $left = $self->{hlist}->ItemStyle('window',-anchor => 'w');

	my $row = 0;
	$self->{checks} = undef;
	foreach my $i (@{$cod_obj->codes}){
		
		$self->{checks}[$row]{check} = 1;
		$self->{checks}[$row]{name}  = $i->name; # 修正！ 2010 12/24
		
		my $c = $self->{hlist}->Checkbutton(
			-text     => $i->name,
			-variable => \$self->{checks}[$row]{check},
			-command  => sub{ $self->check_selected_num; },
			-anchor => 'w',
		);
		
		$self->{checks}[$row]{widget} = $c;
		
		$self->{hlist}->add($row,-at => "$row");
		$self->{hlist}->itemCreate(
			$row,0,
			-itemtype  => 'window',
			-style     => $left,
			-widget    => $c,
		);
		++$row;
	}
	
	$self->check_selected_num;
	
	return $self;
}

sub start_raise{
	my $self = shift;
	
	# コード選択を読み取り
	my %selection = ();
	foreach my $i (@{$self->{checks}}){
		if ($i->{check}){
			$selection{$i->{name}} = 1;
		} else {
			$selection{$i->{name}} = -1;
		}
	}
	
	# ルールファイルを再読み込み
	$self->read_cfile;
	
	# 選択を適用
	foreach my $i (@{$self->{checks}}){
		if ($selection{$i->{name}} == 1 || $selection{$i->{name}} == 0){
			$i->{check} = 1;
		} else {
			$i->{check} = 0;
		}
	}
	
	$self->{hlist}->update;
	return 1;
}


# コードが3つ以上選択されているかチェック
sub check_selected_num{
	my $self = shift;
	
	my $selected_num = 0;
	foreach my $i (@{$self->{checks}}){
		++$selected_num if $i->{check};
	}
	
	if ($selected_num >= 3){
		$self->{ok_btn}->configure(-state => 'normal');
	} else {
		$self->{ok_btn}->configure(-state => 'disable');
	}
	return $self;
}

# すべて選択
sub select_all{
	my $self = shift;
	foreach my $i (@{$self->{checks}}){
		$i->{widget}->select;
	}
	$self->check_selected_num;
	return $self;
}

# クリア
sub select_none{
	my $self = shift;
	foreach my $i (@{$self->{checks}}){
		$i->{widget}->deselect;
	}
	$self->check_selected_num;
	return $self;
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

# プロット作成＆表示
sub _calc{
	my $self = shift;

	#if ( $self->{radio} == 1 ){
	#	if ( $self->tani eq $self->{high} ){
	#		# この場合は上位見出しを取得しない
	#		$self->{radio} = 0;
	#	}
	#}

	my @selected = ();
	foreach my $i (@{$self->{checks}}){
		push @selected, $i->{name} if $i->{check};
	}

	my $vars;
	if ($self->{radio} == 2){
		foreach my $i ( $self->{opt_body_var}->selectionGet ){
			push @{$vars}, $self->{vars}[$i][1];
		}
		
		unless ( @{$vars} ){
			gui_errormsg->open(
				type => 'msg',
				msg  => kh_msg->get('gui_window::word_corresp->select_var'), # 外部変数を1つ以上選択してください。
			);
			return 0;
		}
		
		my $tani2 = '';
		foreach my $i (@{$vars}){
			if ($tani2){
				unless (
					$tani2
					eq mysql_outvar::a_var->new(undef,$i)->{tani}
				){
					gui_errormsg->open(
						type => 'msg',
						msg  => kh_msg->get('gui_window::word_corresp->check_var_unit'), # '現在の所、集計単位が異なる外部変数を同時に使用することはできません。',
					);
					return 0;
				}
			} else {
				$tani2 = mysql_outvar::a_var->new(undef,$i)
					->{tani};
			}
		}
	}

	my $d_x = $self->{xy_obj}->x;
	my $d_y = $self->{xy_obj}->y;

	my $wait_window = gui_wait->start;

	# データ取得
	my $r_command = '';
	unless ( $r_command =  kh_cod::func->read_file($self->cfile)->out2r_selected($self->tani,\@selected) ){ # 修正！ 2010 12/24
		gui_errormsg->open(
			type   => 'msg',
			window  => \$self->win_obj,
			msg    => kh_msg->get('er_zero'), # 出現数が0のコードは利用できません。
		);
		#$self->close();
		$wait_window->end(no_dialog => 1);
		return 0;
	}

	# データ整形
	$r_command .= "\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "row.names(d) <- c(";
	foreach my $i (@{$self->{checks}}){
		if ( $i->{check} ){
			my $name = $i->{name};
			if ( index($name,'＊') == 0 || index($name,'*') == 0){
				substr($name, 0, 1) = '';
			}
			$name = kh_r_plot->quote($name);
			$r_command .= $name.',';
		}
	}
	chop $r_command;
	$r_command .= ")\n";
	$r_command .= "d <- t(d)\n";
	
	# 上位見出しの付与
	if ($self->{radio} == 1){
		my $tani_low  = $self->tani;
		my $tani_high = $self->{high};
		
		unless ($tani_high){
			gui_errormsg->open(
				type   => 'msg',
				window  => \$self->win_obj,
				msg    => kh_msg->get('er_unit'), # 集計単位の選択が不正です。
			);
			return 0;
		}
		
		my $sql = '';
		if ($tani_low eq $tani_high){
			$sql .= "SELECT $tani_high.id\n";
			$sql .= "FROM $tani_high\n";
			$sql .= "ORDER BY $tani_high.id\n";
		} else {
			$sql .= "SELECT $tani_high.id\n";
			$sql .= "FROM $tani_high, $tani_low\n";
			$sql .= "WHERE\n";
			my $n = 0;
			foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
				$sql .= "AND " if $n;
				$sql .= "$tani_low.$i"."_id = $tani_high.$i"."_id\n";
				++$n;
				if ($i eq $tani_high){
					last;
				}
			}
			$sql .= "ORDER BY $tani_low.id\n";
		}
		
		
		my $max = mysql_exec->select("SELECT MAX(id) FROM $tani_high",1)
			->hundle->fetch->[0];
		my %names = ();
		my $n = 1;
		my $headings = "hn <- c(";
		while ($n <= $max){
			$names{$n} = mysql_getheader->get($tani_high, $n);

			if (length($names{$n})){
				$names{$n} =~ s/"/ /g;
				$headings .= "\"$names{$n}\",";
			}

			++$n;
		}
		chop $headings;

		$r_command .= "v <- c(";
		my $h = mysql_exec->select($sql,1)->hundle;
		while (my $i = $h->fetch){
			$r_command .= "$i->[0],";
		}
		chop $r_command;
		$r_command .= ")\n";

		$r_command .= &r_command_aggr_str;

		if ( length($headings) > 7 ){
			$headings .= ")\n";
			#print Jcode->new($headings)->sjis, "\n";
			$r_command .= $headings;
			$r_command .= "d <- as.matrix(d)\n";
			$r_command .= "rownames(d) <- hn[as.numeric( rownames(d) )]\n";
		}
	}

	# 外部変数の付与
	$r_command .= "v_count <- 0\n";
	$r_command .= "v_pch   <- NULL\n";
	if ($self->{radio} == 2){
		my $tani = $self->tani;
		
		my $n_v = 0;
		foreach my $i (@{$vars}){
			my $var_obj = mysql_outvar::a_var->new(undef,$i);
			my $sql = '';
			if ( $var_obj->{tani} eq $tani){
				$sql .= "SELECT $var_obj->{column} FROM $var_obj->{table} ";
				$sql .= "ORDER BY id";
			} else {
				$sql .= "SELECT $var_obj->{table}.$var_obj->{column}\n";
				
				$sql .= "FROM $tani\n";
				$sql .= "LEFT JOIN $var_obj->{tani} ON\n";
				my $n = 0;
				foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
					$sql .= "\t";
					$sql .= "and " if $n;
					$sql .= "$var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
					++$n;
					last if ($var_obj->{tani} eq $i);
				}
				$sql .= "LEFT JOIN $var_obj->{table} ON $var_obj->{tani}.id = $var_obj->{table}.id\n";
				
				#$sql .= "FROM $tani, $var_obj->{tani}, $var_obj->{table}\n";
				#$sql .= "WHERE\n";
				#$sql .= "	$var_obj->{tani}.id = $var_obj->{table}.id\n";
				#foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
				#	$sql .= "	and $var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
				#	last if ($var_obj->{tani} eq $i);
				#}
				
				$sql .= "ORDER BY $tani.id";
				#print "$sql\n";
			}
		
			$r_command .= "v$n_v <- c(";
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
			#print "num1: $n\n";
			chop $r_command;
			$r_command .= ")\n";
			++$n_v;
		}
		$r_command .= &r_command_aggr_var($n_v);
	}
	# 外部変数が無かった場合
	$r_command .= '
		if ( length(v_pch) == 0 ) {
			v_pch   <- 3
			v_count <- 1
		}
	';

	# 対応分析実行のためのRコマンド
	$r_command .=
		"if ( length(v_pch) > 1 ){ v_pch <- v_pch[rowSums(d) > 0] }\n";
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	my $filter = 0;
	if ( $self->{check_filter} ){
		$filter = $self->gui_jgn( $self->{entry_flt}->get );
	}

	my $filter_w = 0;
	if ( $self->{check_filter_w} && $self->{radio} != 0){
		$filter_w = $self->gui_jgn( $self->{entry_flw}->get );
	}

	my $biplot = 1;
	if ($self->{radio} == 1){
		$biplot = $self->gui_jg( $self->{biplot} );
	}

	my $plot = &gui_window::word_corresp::make_plot(
		$self->{xy_obj}->params,
		flt          => $filter,
		flw          => $filter_w,
		biplot       => $biplot,
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		r_command    => $r_command,
		plotwin_name => 'cod_corresp',
		bubble       => $self->{bubble_obj}->check_bubble,
		std_radius   => $self->{bubble_obj}->chk_std_radius,
		resize_vars  => $self->{bubble_obj}->chk_resize_vars,
		bubble_size  => $self->{bubble_obj}->size,
		bubble_var   => $self->{bubble_obj}->var,
		use_alpha    => $self->{bubble_obj}->alpha,
	);

	$wait_window->end(no_dialog => 1);
	return 0 unless $plot;

	# プロットWindowを開く
	if ($::main_gui->if_opened('w_cod_corresp_plot')){
		$::main_gui->get('w_cod_corresp_plot')->close;
	}
	
	gui_window::r_plot::cod_corresp->open(
		plots       => $plot->{result_plots},
		#ax          => $self->{ax},
	);

	# 後処理
	unless ( $self->{radio} ){
		$self->{radio} = 1;
	}
	
	unless ( $self->{check_rm_open} ){
		$self->withd;
	}

}

sub r_command_aggr_var_old{
	my $t = << 'END_OF_the_R_COMMAND';

# aggregate
n_total <- table(v)
d <- aggregate(d,list(name = v), sum)
row.names(d) <- d$name
d$name <- NULL
d       <- d[       order(rownames(d      )), ]
n_total <- n_total[ order(rownames(n_total))  ]
#------------------------------------------------------------------------------
n_total <- subset(
	n_total,
	row.names(d) != "欠損値" & row.names(d) != "." & row.names(d) != "missing"
)
d <- subset(
	d,
	row.names(d) != "欠損値" & row.names(d) != "." & row.names(d) != "missing"
)
#------------------------------------------------------------------------------
n_total <- subset(n_total,rowSums(d) > 0)

END_OF_the_R_COMMAND
return $t;
}

sub r_command_aggr_var{
	my $n_v = shift;
	my $t = << 'END_OF_the_R_COMMAND';

# aggregate
aggregate_with_var <- function(d, doc_length_mtr, v) {
	d       <- aggregate(d,list(name = v), sum)
	n_total <- as.matrix( table(v) )

	row.names(d) <- d$name
	d$name <- NULL

	d       <- d[       order(rownames(d      )), ]
	n_total <- n_total[ order(rownames(n_total)), ]

	n_total <- subset(
		n_total,
		row.names(d) != "欠損値" & row.names(d) != "." & regexpr("^missing$", row.names(d), ignore.case = T, perl = T) == -1
	)
	d <- subset(
		d,
		row.names(d) != "欠損値" & row.names(d) != "." & regexpr("^missing$", row.names(d), ignore.case = T, perl = T) == -1
	)
	n_total <- as.matrix(n_total)
	return( list(d, n_total) )
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

d       <- dd

n_total <- nn
n_total <- subset(n_total, rowSums(d) > 0)
n_total <- n_total[,1]

END_OF_the_R_COMMAND2

	return $t;
}


sub r_command_aggr_str{
	my $t = << 'END_OF_the_R_COMMAND';

# aggregate
n_total <- table(v)
d <- aggregate(d,list(name = v), sum)
row.names(d) <- d$name
d$name <- NULL
d       <- d[       order(rownames(d      )), ]
n_total <- n_total[ order(rownames(n_total))  ]
n_total <- subset(n_total,rowSums(d) > 0)

END_OF_the_R_COMMAND
return $t;
}

#--------------#
#   アクセサ   #

sub cfile{
	my $self = shift;
	return $self->{codf_obj}->cfile;
}
sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}
sub win_name{
	return 'w_cod_corresp';
}
1;