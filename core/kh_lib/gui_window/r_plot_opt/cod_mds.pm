package gui_window::r_plot_opt::cod_mds;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# 方法
	my $fd = $lf->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 4,
	);

	$fd->Label(
		-text => $self->gui_jchar('方法：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget = gui_widget::optmenu->open(
		parent  => $fd,
		pack    => {-side => 'left'},
		options =>
			[
				['Classical', 'C'],
				['Kruskal',   'K'],
				['Sammon',    'S'],
			],
		variable => \$self->{method_opt},
	);

	my $method = 'C';
	if ($self->{command_f} =~ /isoMDS/){
		$method = 'K';
	}
	elsif ($self->{command_f} =~ /sammon/){
		$method = 'S';
	}
	$widget->set_value($method);

	$fd->Label(
		-text => $self->gui_jchar('  距離：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget_dist = gui_widget::optmenu->open(
		parent  => $fd,
		pack    => {-side => 'left'},
		options =>
			[
				['Jaccard', 'binary'],
				['Euclid',  'euclid'],
				['Cosine',  'pearson'],
			],
		variable => \$self->{method_dist},
	);
	if ( $self->{command_f} =~ /dj .+euclid/ ){
		$widget_dist->set_value('euclid');
	}
	elsif  ( $self->{command_f} =~ /dj .+binary/ ){
		$widget_dist->set_value('binary');
	}
	else {
		$widget_dist->set_value('pearson');
	}

	# 次元の数
	my $fnd = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 4,
	);

	$fnd->Label(
		-text => $self->gui_jchar('次元：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_dim_number} = $fnd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	
	$self->{entry_dim_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_dim_number});
	if ( $self->{command_f} =~ /k=([123])[\), ]/ ){
		$self->{entry_dim_number}->insert(0,$1);
	} else {
		$self->{entry_dim_number}->insert(0,'2');
	}

	$fnd->Label(
		-text => $self->gui_jchar('（1から3までの範囲で指定）'),
		-font => "TKFN",
	)->pack(-side => 'left');

	# バブルプロット用のパラメーター
	my ($check_bubble, $chk_std_radius, $num_size, $num_var)
		= (0,1,100,100);

	if ( $self->{command_f} =~ /b_size/ ){
		$check_bubble = 1;
	} else {
		$check_bubble = 0;
	}

	if ( $self->{command_f} =~ /std_radius <\- ([0-9]+)\n/ ){
		$chk_std_radius = $1;
	}

	if ( $self->{command_f} =~ /bubble_size <\- ([0-9]+)\n/ ){
		$num_size = $1;
	}

	if ( $self->{command_f} =~ /bubble_var <\- ([0-9]+)\n/ ){
		$num_var = $1;
	}

	# バブルプロット
	$self->{bubble_obj} = gui_widget::bubble->open(
		parent          => $lf,
		type            => 'mds',
		command         => sub{ $self->calc; },
		check_bubble    => $check_bubble,
		chk_std_radius  => $chk_std_radius,
		num_size        => $num_size,
		num_var         => $num_var,
		pack            => {
			-anchor => 'w',
		},
	);

	# クラスター化のパラメーター
	if ( $self->{command_f} =~ /n_cls <\- ([0-9]+)\n/ ){
		$self->{cls_if} = $1;
		if ( $self->{cls_if} ){
			$self->{cls_n} = $self->{cls_if};
			$self->{cls_if} = 1;
		} else {
			$self->{cls_n} = 7;
		}
	} else {
		$self->{cls_if} = 0;
		$self->{cls_n}  = 7;
	}
	if ( $self->{command_f} =~ /cls_raw <\- ([0-9]+)\n/ ){
		my $v = $1;
		if ($v == 1){
			$self->{cls_nei} = 0;
		} else {
			$self->{cls_nei} = 1;
		}
		print "cls_nei: $self->{cls_nei}, v: $v,\n";
	}
	$self->{cls_obj} = gui_widget::cls4mds->open(
		parent       => $lf,
		command      => sub{ $self->calc; },
		pack    => {
			-anchor  => 'w',
		},
		check_cls    => $self->{cls_if},
		cls_n        => $self->{cls_n},
		check_nei    => $self->{cls_nei},
	);

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

	my $wait_window = gui_wait->start;
	&gui_window::word_mds::make_plot(
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		method         => $self->gui_jg( $self->{method_opt}  ),
		method_dist    => $self->gui_jg( $self->{method_dist} ),
		r_command      => $r_command,
		plotwin_name   => 'cod_mds',
		dim_number     => $self->gui_jg( $self->{entry_dim_number}->get ),
		bubble       => $self->{bubble_obj}->check_bubble,
		std_radius   => $self->{bubble_obj}->chk_std_radius,
		bubble_size  => $self->{bubble_obj}->size,
		bubble_var   => $self->{bubble_obj}->var,
		n_cls          => $self->{cls_obj}->n,
		cls_raw        => $self->{cls_obj}->raw,
	);
	$wait_window->end(no_dialog => 1);
	$self->close;

}

sub win_title{
	return 'コーディング・多次元尺度法：調整';
}

sub win_name{
	return 'w_cod_mds_plot_opt';
}

1;