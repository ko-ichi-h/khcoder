package gui_window::r_plot_opt::cod_mds;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# アルゴリズム選択
	$self->{mds_obj} = gui_widget::r_mds->open(
		parent       => $lf,
		command      => sub{ $self->calc; },
		pack         => { -anchor   => 'w'},
		r_cmd        => $self->{command_f},
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
	$self->_configure_mother;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
		#print "chk: $r_command\n";
		#$r_command = Jcode->new($r_command)->euc
		#	if $::config_obj->os eq 'win32';
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('r_net_msg_fail'),
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}

	$r_command .= "# END: DATA\n";

	my $wait_window = gui_wait->start;
	my $plot = &gui_window::word_mds::make_plot(
		font_size    => $self->{font_obj}->font_size,
		font_bold    => $self->{font_obj}->check_bold_text,
		plot_size    => $self->{font_obj}->plot_size,
		$self->{mds_obj}->params,
		r_command    => $r_command,
		plotwin_name => 'cod_mds',
	);
	$wait_window->end(no_dialog => 1);
	
	# プロットWindowを開く
	if ($::main_gui->if_opened('w_cod_mds_plot')){
		$::main_gui->get('w_cod_mds_plot')->close;
	}
	return 0 unless $plot;

	gui_window::r_plot::cod_mds->open(
		plots       => $plot->{result_plots},
		msg         => $plot->{result_info},
		ax          => $self->{ax},
	);
	$plot = undef;
	
	
	$self->close;

}

sub win_title{
	return kh_msg->get('win_title'); # コーディング・多次元尺度法：調整
}

sub win_name{
	return 'w_cod_mds_plot_opt';
}

1;