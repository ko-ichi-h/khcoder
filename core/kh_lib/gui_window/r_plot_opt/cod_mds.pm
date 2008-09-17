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
		-text => $self->gui_jchar('  次元：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_dim_number} = $fd->Entry(
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

	&gui_window::word_mds::make_plot(
		base_win       => $self,
		font_size      => $fontsize,
		plot_size      => $self->gui_jg( $self->{entry_plot_size}->get ),
		method         => $self->{method_opt},
		r_command      => $r_command,
		plotwin_name   => 'cod_mds',
		dim_number     => $self->gui_jg( $self->{entry_dim_number}->get ),
	);

}

sub win_title{
	return 'コーディング・多次元尺度法の調整';
}

sub win_name{
	return 'w_cod_mds_plot_opt';
}

1;