package gui_window::r_plot_opt::cod_corresp;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

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
	#$self->{entry_flw}->insert(0,'50');
	$self->{entry_flw}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_flw});

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
	#$self->{entry_flt}->insert(0,'50');
	$self->{entry_flt}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_flt});

	#$self->refresh_flt;

	$lf->Checkbutton(
		-text     => $self->gui_jchar('コードの出現数を円の大きさで表現（バブル）'),
		-variable => \$self->{check_bubble},
		-command  => sub{ $self->refresh_std_radius;},
	)->pack(
		-anchor => 'w',
	);

	my $frm_std_radius = $lf->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 2,
	);

	$frm_std_radius->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');
	
	$self->{chkw_std_radius} = $frm_std_radius->Checkbutton(
			-text     => $self->gui_jchar('円の大きさを標準化','euc'),
			-variable => \$self->{chk_std_radius},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	# 成分
	my $fd = $lf->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 4,
	);

	$fd->Label(
		-text => $self->gui_jchar('プロットする成分：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$fd->Label(
		-text => $self->gui_jchar(' X軸'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_d_x} = $fd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
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
	$self->{entry_d_y}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_d_y});
	
	if ( $self->{command_f} =~ /\nd_x <\- ([0-9]+)\nd_y <\- ([0-9]+)\n/ ){
		my ($d_x, $d_y) = ($1, $2);
		$self->{entry_d_x}->insert(0,$d_x);
		$self->{entry_d_y}->insert(0,$d_y);
	} else {
		$self->{entry_d_x}->insert(0,'1');
		$self->{entry_d_y}->insert(0,'2');
	}

	if ( $self->{command_f} =~ /\nflt <\- ([0-9]+)\n/ ){
		if ($1){
			$self->{check_filter} = 1;
			$self->{entry_flt}->insert(0,$1);
		} else {
			$self->{check_filter} = 0;
			$self->{entry_flt}->insert(0,'50');
		}
		$self->refresh_flt;
	}

	if ( $self->{command_f} =~ /\nflw <\- ([0-9]+)\n/ ){
		if ($1 > 0){
			$self->{check_filter_w} = 1;
			$self->{entry_flw}->insert(0,$1);
		} else {
			$self->{check_filter_w} = 0;
			$self->{entry_flw}->insert(0,'50');
		}
		$self->refresh_flw;
	}
	
	if ( $self->{command_f} =~ /symbols\(/ ){
		$self->{check_bubble} = 1;
	} else {
		$self->{check_bubble} = 0;
	}

	if ( $self->{command_f} =~ /std_radius <\- ([0-9]+)\n/ ){
		$self->{chk_std_radius} = $1;
	} else {
		$self->{chk_std_radius} = 1;
	}
	$self->refresh_std_radius;

	unless ($self->{command_f} =~ /\n# aggregate\n/){
		$self->{check_filter_w_widget}->configure(-state => 'disabled');
	}

	return $self;
}

# 「特徴語に注目」のチェックボックス
sub refresh_flt{
	my $self = shift;
	if ( $self->{check_filter} ){
		$self->{entry_flt}   ->configure(-state => 'normal');
		$self->{entry_flt_l1}->configure(-state => 'normal');
		#$self->{entry_flt_l2}->configure(-state => 'normal');
	} else {
		$self->{entry_flt}   ->configure(-state => 'disabled');
		$self->{entry_flt_l1}->configure(-state => 'disabled');
		#$self->{entry_flt_l2}->configure(-state => 'disabled');
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

sub refresh_std_radius{
	my $self = shift;
	if ( $self->{check_bubble} ){
		$self->{chkw_std_radius}->configure(-state => 'normal');
	} else {
		$self->{chkw_std_radius}->configure(-state => 'disabled');
	}
}

sub calc{
	my $self = shift;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
		#print "chk: $r_command\n";
		$r_command = Jcode->new($r_command)->euc
			if $::config_obj->os eq 'win32';
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => '調整に失敗しましました。',
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}
	$r_command .= "# END: DATA\n";

	my $biplot = 0;
	$biplot = 1 if $self->{command_f} =~ /rscore/;

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

	my $wait_window = gui_wait->start;
	&gui_window::word_corresp::make_plot(
		base_win     => $self,
		d_x          => $self->gui_jg( $self->{entry_d_x}->get ),
		d_y          => $self->gui_jg( $self->{entry_d_y}->get ),
		flt          => $filter,
		flw          => $filter_w,
		biplot       => $biplot,
		plot_size    => $self->gui_jg( $self->{entry_plot_size}->get ),
		font_size    => $fontsize,
		r_command    => $r_command,
		plotwin_name => 'cod_corresp',
		bubble       => $self->gui_jg( $self->{check_bubble} ),
		std_radius   => $self->gui_jg( $self->{chk_std_radius} ),
	);
	$wait_window->end(no_dialog => 1);
	$self->close
}

sub win_title{
	return 'コーディング・対応分析：調整';
}

sub win_name{
	return 'w_cod_corresp_plot_opt';
}

1;