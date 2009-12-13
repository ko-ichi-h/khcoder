package gui_window::r_plot_opt::cod_corresp;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# 成分
	my $fd = $lf->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 4,
	);

	$fd->Label(
		-text => $self->gui_jchar('プロットする成分'),
		-font => "TKFN",
	)->pack(-side => 'left');

	#$self->{entry_d_n} = $fd->Entry(
	#	-font       => "TKFN",
	#	-width      => 2,
	#	-background => 'white',
	#)->pack(-side => 'left', -padx => 2);
	#if ($self->{command_f} =~ /corresp\(d, nf=([0-9]+)\)/){
	#	$self->{entry_d_n}->insert(0,$1);
	#} else {
	#	$self->{entry_d_n}->insert(0,'2');
	#}
	#$self->{entry_d_n}->bind("<Key-Return>",sub{$self->calc;});
	#$self->config_entry_focusin($self->{entry_d_n});

	$fd->Label(
		-text => $self->gui_jchar('  x軸：'),
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
		-text => $self->gui_jchar('  y軸：'),
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
	return $self;
}

sub calc{
	my $self = shift;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)library\(MASS\).+/s){
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

	my $biplot = 0;
	$biplot = 1 if $self->{command_f} =~ /rscore/;
	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	&gui_window::word_corresp::make_plot(
		base_win     => $self,
		#d_n          => $self->gui_jg( $self->{entry_d_n}->get ),
		d_x          => $self->gui_jg( $self->{entry_d_x}->get ),
		d_y          => $self->gui_jg( $self->{entry_d_y}->get ),
		biplot       => $biplot,
		plot_size    => $self->gui_jg( $self->{entry_plot_size}->get ),
		font_size    => $fontsize,
		r_command    => $r_command,
		plotwin_name => 'cod_corresp',
	);

	$self->close
}

sub win_title{
	return 'コーディング・対応分析：調整';
}

sub win_name{
	return 'w_cod_corresp_plot_opt';
}

1;