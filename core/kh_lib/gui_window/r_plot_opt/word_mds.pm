package gui_window::r_plot_opt::word_mds;
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
	if ( $self->{command_f} =~ /euclid/ ){
		$widget_dist->set_value('euclid');
	}
	elsif  ( $self->{command_f} =~ /binary/ ){
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

	if ( $self->{command_f} =~ /symbols\(/ ){
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

	$r_command .= "# END: DATA\n";

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	my $wait_window = gui_wait->start;
	&gui_window::word_mds::make_plot(
		font_size      => $fontsize,
		plot_size      => $self->gui_jg( $self->{entry_plot_size}->get ),
		method         => $self->gui_jg( $self->{method_opt}  ),
		method_dist    => $self->gui_jg( $self->{method_dist} ),
		r_command      => $r_command,
		plotwin_name   => 'word_mds',
		dim_number     => $self->gui_jg( $self->{entry_dim_number}->get ),
		bubble       => $self->{bubble_obj}->check_bubble,
		std_radius   => $self->{bubble_obj}->chk_std_radius,
		bubble_size  => $self->{bubble_obj}->size,
		bubble_var   => $self->{bubble_obj}->var,
	);
	$wait_window->end(no_dialog => 1);
	$self->close;
}

sub win_title{
	return '抽出語・多次元尺度法：調整';
}

sub win_name{
	return 'w_word_mds_plot_opt';
}

1;