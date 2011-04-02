package gui_window::cod_corresp;
use base qw(gui_window);

use strict;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt('コーディング・対応分析：オプション'));

	my $lf = $win->LabFrame(
		-label       => 'Options',
		-labelside   => 'acrosstop',
		-borderwidth => 2
	)->pack(
		-fill   => 'both',
		-expand => 1
	);

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
		-text => $self->gui_jchar('コーディング単位：'),
		-font => "TKFN",
	)->pack(-side => 'left');
	my %pack1 = (
		-anchor => 'w',
		-padx => 2,
		-pady => 2,
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $f1,
		command => sub { $self->refresh; },
		pack   => \%pack1,
	);

	# コード選択
	$lf->Label(
		-text => $self->gui_jchar('コード選択：'),
		-font => "TKFN",
	)->pack(-anchor => 'nw', -padx => 2, -pady => 0);

	my $f2 = $lf->Frame()->pack(
		-fill   => 'both',
		-expand => 1,
		-padx   => 2,
		-pady   => 2
	);

	$f2->Label(
		-text => $self->gui_jchar('　　','euc'),
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
		-text => $self->gui_jchar('全て選択'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->select_all;});}
	)->pack(-pady => 3);
	$f2_2->Button(
		-text => $self->gui_jchar('クリア'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->select_none;});}
	)->pack();

	$lf->Label(
		-text => $self->gui_jchar('　　※コードを3つ以上選択して下さい。','euc'),
		-font => "TKFN",
	)->pack(
		-anchor => 'w',
		-padx   => 4,
		-pady   => 2,
	);

	# 入力データの設定
	$lf->Label(
		-text => $self->gui_jchar('分析に使用するデータ表の種類：'),
		-font => "TKFN",
	)->pack(-anchor => 'nw', -padx => 2, -pady => 0);

	my $fi = $lf->Frame()->pack(
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
		-text             => $self->gui_jchar('コード ｘ 文書（同時布置なし）'),
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 0,
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w');

	$fi_1->Radiobutton(
		-text             => $self->gui_jchar('コード ｘ 上位の章・節・段落'),
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 1,
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w');

	my $fi_2 = $fi_1->Frame()->pack(-anchor => 'w');
	$self->{label_high} = $fi_2->Label(
		-text => $self->gui_jchar('　　集計単位：','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{opt_frame_high} = $fi_2;

	$fi_1->Radiobutton(
		-text             => $self->gui_jchar('コード ｘ 外部変数'),
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 2,
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w');

	my $fi_3 = $fi_1->Frame()->pack(-anchor => 'w');
	$self->{label_var} = $fi_3->Label(
		-text => $self->gui_jchar('　　変数：','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{opt_frame_var} = $fi_3;

	# 差異の顕著な語のみ分析
	my $fsw = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2,
	);

	$self->{check_filter_w_widget} = $fsw->Checkbutton(
		-text     => $self->gui_jchar('差異が顕著なコードを分析に使用：'),
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

	$self->refresh_flw;

	# 特徴的な語のみラベル表示
	my $fs = $lf->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 2,
	);

	$fs->Checkbutton(
		-text     => $self->gui_jchar('原点から離れたコードのみラベル表示：'),
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

	$self->refresh_flt;

	$self->refresh;


	# 成分
	my $fd = $lf->Frame()->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 4,
	);

	$fd->Label(
		-text => $self->gui_jchar('プロットする成分'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$fd->Label(
		-text => $self->gui_jchar(' → X軸：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_d_x} = $fd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_d_x}->insert(0,'1');
	$self->{entry_d_x}->bind("<Key-Return>",sub{$self->_calc;});
	$self->config_entry_focusin($self->{entry_d_x});

	$fd->Label(
		-text => $self->gui_jchar('  Y軸：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_d_y} = $fd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_d_y}->insert(0,'2');
	$self->{entry_d_y}->bind("<Key-Return>",sub{$self->_calc;});
	$self->config_entry_focusin($self->{entry_d_y});

	# フォントサイズ
	my $ff = $lf->Frame()->pack(
		-fill => 'x',
		-padx => 2,
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
	$self->{entry_font_size}->bind("<Key-Return>",sub{$self->_calc;});
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
	$self->{entry_plot_size}->insert(0,'480');
	$self->{entry_plot_size}->bind("<Key-Return>",sub{$self->_calc;});
	$self->config_entry_focusin($self->{entry_plot_size});


	$win->Checkbutton(
			-text     => $self->gui_jchar('実行時にこの画面を閉じない','euc'),
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	# OK・キャンセル
	my $f3 = $win->Frame()->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 2
	);

	$f3->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$self->{ok_btn} = $f3->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-state => 'disable',
		-command => sub{ $mw->after(10,sub{$self->_calc;});}
	)->pack(-side => 'right');

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


# ラジオボタン関連
sub refresh{
	my $self = shift;
	unless ($self->{tani_obj}){return 0;}

	#------------------------#
	#   外部変数選択Widget   #

	unless ($self->{last_tani} eq $self->tani){
		my @options = ();
		my @tanis   = ();

		if ($self->{opt_body_var}){
			$self->{opt_body_var}->destroy;
		}

		# 利用できる変数があるかどうかチェック
		my %tani_check = ();
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			$tani_check{$i} = 1;
			last if ($self->tani eq $i);
		}
		if ($self->tani eq 'bun'){
			%tani_check = ();
			$tani_check{'bun'} = 1;
		}
		
		$self->{last_tani} = $self->tani;
		
		my $h = mysql_outvar->get_list;
		my @options = ();
		foreach my $i (@{$h}){
			if ($tani_check{$i->[0]}){
				push @options, [$self->gui_jchar($i->[1]), $i->[2]];
				#print "varid: $i->[2]\n";
			}
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

	#------------------------------#
	#   上位の文書単位選択Widget   #

		if ($self->{opt_body_high}){
			$self->{opt_body_high}->destroy;
		}

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
			last if ($self->tani eq $i);
			
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
		$self->{opt_body_high}->configure(-state => 'disable');
		$self->{label_high}->configure(-foreground => 'gray');
		
		$self->{opt_body_var}->configure(-state => 'disable');
		$self->{label_var}->configure(-foreground => 'gray');
		
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
		
		$self->{opt_body_var}->configure(-state => 'disable');
		$self->{label_var}->configure(-foreground => 'gray');

		$self->{check_filter_w_widget}->configure(-state => 'normal');
		$self->refresh_flw;
		#$self->{entry_flw}   ->configure(-state => 'normal');
		#$self->{entry_flw_l1}->configure(-state => 'normal');
	}
	elsif ($self->{radio} == 2){
		$self->{opt_body_high}->configure(-state => 'disable');
		$self->{label_high}->configure(-foreground => 'gray');

		if ($self->{opt_body_var_ok}){
			$self->{opt_body_var}->configure(-state => 'normal');
		} else {
			$self->{opt_body_var}->configure(-state => 'disable');
		}
		$self->{label_var}->configure(-foreground => 'black');

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
	foreach my $i (@{$cod_obj->codes}){
		
		$self->{checks}[$row]{check} = 1;
		$self->{checks}[$row]{name}  = $i->name; # 修正！ 2010 12/24
		
		my $c = $self->{hlist}->Checkbutton(
			-text     => gui_window->gui_jchar($i->name,'euc'),
			-variable => \$self->{checks}[$row]{check},
			-command  => sub{ 
				$self->win_obj->after(10,sub{ $self->check_selected_num; });
			},
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

# プロット作成＆表示
sub _calc{
	my $self = shift;

	my @selected = ();
	foreach my $i (@{$self->{checks}}){
		push @selected, $i->{name} if $i->{check};
	}

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	#my $d_n = $self->gui_jg( $self->{entry_d_n}->get );
	my $d_x = $self->gui_jg( $self->{entry_d_x}->get );
	my $d_y = $self->gui_jg( $self->{entry_d_y}->get );

	# データ取得
	my $r_command = '';
	unless ( $r_command =  kh_cod::func->read_file($self->cfile)->out2r_selected($self->tani,\@selected) ){ # 修正！ 2010 12/24
		gui_errormsg->open(
			type   => 'msg',
			window  => \$self->win_obj,
			msg    => "出現数が0のコードは利用できません。"
		);
		#$self->close();
		return 0;
	}

	# データ整形
	$r_command .= "\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "row.names(d) <- c(";
	foreach my $i (@{$self->{checks}}){
		my $name = $i->{name};
		substr($name, 0, 2) = ''
			if index($name,'＊') == 0
		;
		$r_command .= '"'.$name.'",'
			if $i->{check}
		;
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
				msg    => "集計単位の選択が不正です。"
			);
			return 0;
		}
		
		my $sql = '';
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
		
		my $max = mysql_exec->select("SELECT MAX(id) FROM $tani_high",1)
			->hundle->fetch->[0];
		my %names = ();
		my $n = 1;
		while ($n <= $max){
			$names{$n} = Jcode->new(
				mysql_getheader->get($tani_high, $n),
				'sjis'
			)->euc;
			++$n;
		}
		
		$r_command .= "v <- c(";
		my $h = mysql_exec->select($sql,1)->hundle;
		while (my $i = $h->fetch){
			if (length($names{$i->[0]})){
				$names{$i->[0]} =~ s/"/ /g;
				$r_command .= "\"$names{$i->[0]}\",";
			} else {
				$r_command .= "$i->[0],";
			}
		}
		chop $r_command;
		$r_command .= ")\n";
		$r_command .= &r_command_aggr_str;
	}
	
	# 外部変数の付与
	if ($self->{radio} == 2){
		unless ($self->{var_id}){
			gui_errormsg->open(
				type   => 'msg',
				window  => \$self->win_obj,
				msg    => "外部変数の選択が不正です。"
			);
			return 0;
		}
		my $tani = $self->tani;
		
		my $sql = '';
		my $var_obj = mysql_outvar::a_var->new(undef,$self->{var_id});
		if ( $var_obj->{tani} eq $tani){
			$sql .= "SELECT $var_obj->{column} FROM $var_obj->{table} ";
			$sql .= "ORDER BY id";
		} else {
			$sql .= "SELECT $var_obj->{table}.$var_obj->{column}\n";
			$sql .= "FROM $tani, $var_obj->{tani}, $var_obj->{table}\n";
			$sql .= "WHERE\n";
			$sql .= "	$var_obj->{tani}.id = $var_obj->{table}.id\n";
			foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
				$sql .= "	and $var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
				last if ($var_obj->{tani} eq $i);
			}
			$sql .= "ORDER BY $tani.id";
		}
		
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
		#print "num1: $n\n";
		chop $r_command;
		$r_command .= ")\n";
		$r_command .= &r_command_aggr_var;
	}
	
	# 対応分析実行のためのRコマンド
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	my $filter = 0;
	if ( $self->{check_filter} ){
		$filter = $self->gui_jg( $self->{entry_flt}->get );
	}

	my $filter_w = 0;
	if ( $self->{check_filter_w} && $self->{radio} != 0){
		$filter_w = $self->gui_jg( $self->{entry_flw}->get );
	}

	&gui_window::word_corresp::make_plot(
		d_x          => $self->gui_jg( $self->{entry_d_x}->get ),
		d_y          => $self->gui_jg( $self->{entry_d_y}->get ),
		flt          => $filter,
		flw          => $filter_w,
		biplot       => $self->gui_jg( $self->{radio} ),
		plot_size    => $self->gui_jg( $self->{entry_plot_size}->get ),
		font_size    => $fontsize,
		r_command    => $r_command,
		plotwin_name => 'cod_corresp',
	);

	unless ( $self->{check_rm_open} ){
		$self->close;
	}

}

sub r_command_aggr_var{
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