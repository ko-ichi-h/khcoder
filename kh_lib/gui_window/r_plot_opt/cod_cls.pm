package gui_window::r_plot_opt::cod_cls;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# クラスター数
	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f4->Label(
		-text => $self->gui_jchar('距離：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget_dist = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				['Jaccard', 'binary'],
				['Euclid',  'euclid'],
				['Cosine',  'pearson'],
			],
		variable => \$self->{method_dist},
	);
	if ( $self->{command_f} =~ /euclid/ ){
		$widget_dist->set_value('euclid');
	}
	elsif  ( $self->{command_f} =~ /binary/ ){
		$widget_dist->set_value('binary');
	}
	else {
		$widget_dist->set_value('pearson');
	}

	# クラスター数
	my $f5 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f5->Label(
		-text => $self->gui_jchar('クラスター数：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_cluster_number} = $f5->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_cluster_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_cluster_number});

	$f5->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-side => 'left');

	
	$f5->Checkbutton(
			-text     => $self->gui_jchar('クラスターの色分け','euc'),
			-variable => \$self->{check_color_cls},
			-anchor => 'w',
	)->pack(-anchor => 'w', -side => 'left');

	# 設定の読み取り
	if ( $self->{command_f} =~ /n_cls <- ([0-9]+)\n/ ){
		$self->{entry_cluster_number}->insert(0,$1);
	} else {
		$self->{entry_cluster_number}->insert(0,'0');
	}

	if ( $self->{command_f} =~ /ggplot2/ ){
		$self->{check_color_cls} = 1;
	} else {
		$self->{check_color_cls} = 0;
	}

	return $self;
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

	if (
		   $self->gui_jg( $self->{entry_cluster_number}->get ) =~ /Auto/i
		|| $self->{font_obj}->plot_size                        =~ /Auto/i
	) {
		gui_errormsg->open(
			type => 'msg',
			msg  => "このWindowでは「Auto」指定はできません。数値を入力してください",
		);
		return 0;
	}

	$r_command .= "# END: DATA\n";

	my $wait_window = gui_wait->start;
	&gui_window::word_cls::make_plot(
		cluster_number => $self->gui_jg( $self->{entry_cluster_number}->get ),
		cluster_color  => $self->gui_jg( $self->{check_color_cls} ),
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		r_command      => $r_command,
		plotwin_name   => 'cod_cls',
		method_dist    => $self->gui_jg( $self->{method_dist} ),
	);
	$wait_window->end(no_dialog => 1);
	$self->close;
	return 1;
}

sub win_title{
	return 'コーディング・クラスター分析：調整';
}

sub win_name{
	return 'w_cod_cls_plot_opt';
}

1;