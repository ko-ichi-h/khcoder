package gui_window::r_plot_opt::word_som;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# クラスター数
	$self->{som_obj} = gui_widget::r_som->open(
		parent  => $lf,
		command => sub{ $self->calc; },
		pack    => { -anchor   => 'w'},
		r_cmd   => $self->{command_f},
		reuse  => 1,
	);

	return $self;
}

sub calc{
	my $self = shift;
	$self->_configure_mother;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
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

	use plotR::som;
	my $plotR = plotR::som->new(
		$self->{som_obj}->params,
		reuse             => 1,
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		r_command      => $r_command,
		plotwin_name   => 'word_som',
	);

	# プロットWindowを開く
	if ($::main_gui->if_opened('w_word_som_plot')){
		$::main_gui->get('w_word_som_plot')->close;
	}

	return 0 unless $plotR;

	gui_window::r_plot::word_som->open(
		plots       => $plotR->{result_plots},
		msg         => $plotR->{result_info},
		msg_long    => $plotR->{result_info_long},
		ax          => $self->{ax},
		#no_geometry => 1,
	);

	$plotR = undef;

	$wait_window->end(no_dialog => 1);
	$self->close;
	return 1;
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・自己組織化マップ：調整
}

sub win_name{
	return 'w_word_som_plot_opt';
}

1;