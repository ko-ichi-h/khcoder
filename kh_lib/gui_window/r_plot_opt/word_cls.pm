package gui_window::r_plot_opt::word_cls;
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
			],
		variable => \$self->{method_dist},
	);
	if ( $self->{command_f} =~ /euclid/ ){
		$widget_dist->set_value('euclid');
	} else {
		$widget_dist->set_value('binary');
	}


	$f4->Label(
		-text => $self->gui_jchar('クラスター数：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_cluster_number} = $f4->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	if ( $self->{command_f} =~ /rect\.hclust.+k=([0-9]+)[, \)]/ ){
		$self->{entry_cluster_number}->insert(0,$1);
	} else {
		$self->{entry_cluster_number}->insert(0,'0');
	}
	$self->{entry_cluster_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_cluster_number});

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
		|| $self->gui_jg( $self->{entry_plot_size}->get )      =~ /Auto/i
	) {
		gui_errormsg->open(
			type => 'msg',
			msg  => "このWindowでは「Auto」指定はできません。数値を入力してください",
		);
		return 0;
	}

	$r_command .= "# END: DATA\n";

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	&gui_window::word_cls::make_plot(
		base_win       => $self,
		cluster_number => $self->gui_jg( $self->{entry_cluster_number}->get ),
		font_size      => $fontsize,
		plot_size      => $self->gui_jg( $self->{entry_plot_size}->get ),
		r_command      => $r_command,
		plotwin_name   => 'word_cls',
		method_dist    => $self->gui_jg( $self->{method_dist} ),
	);

	return 1;
}

sub win_title{
	return '抽出語・クラスター分析：調整';
}

sub win_name{
	return 'w_word_cls_plot_opt';
}

1;