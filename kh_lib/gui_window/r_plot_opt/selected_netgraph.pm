package gui_window::r_plot_opt::selected_netgraph;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# 共起ネットワークのオプション
	$self->{net_obj} = gui_widget::r_net->open(
		parent  => $lf,
		command => sub{ $self->calc; },
		pack    => { -anchor   => 'w'},
		r_cmd   => $self->{command_f},
	);


	return $self;
}

sub calc{
	my $self = shift;
	$self->_configure_mother;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
		#print "chk: $r_command\n";
		$r_command = Jcode->new($r_command)->euc
			if $::config_obj->os eq 'win32';
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('r_net_msg_fail'), # 調整に失敗しましました。
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}

	$r_command .= "# END: DATA\n";

	my $wait_window = gui_wait->start;
	use plotR::network;
	my $plotR = plotR::network->new(
		$self->{net_obj}->params,
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		r_command         => $r_command,
		plotwin_name      => 'selected_netgraph',
	);
	# プロットWindowを開く
	$wait_window->end(no_dialog => 1);
	
	if ($::main_gui->if_opened('w_selected_netgraph_plot')){
		$::main_gui->get('w_selected_netgraph_plot')->close;
	}

	return 0 unless $plotR;

	gui_window::r_plot::selected_netgraph->open(
		plots       => $plotR->{result_plots},
		msg         => $plotR->{result_info},
		msg_long    => $plotR->{result_info_long},
		ax          => $self->{ax},
		#no_geometry => 1,
	);

	$plotR = undef;

	$self->close;

	return 1;
}

sub win_title{
	return kh_msg->get('win_title'); # 関連語・共起ネットワーク：調整
}

sub win_name{
	return 'w_selected_netgraph_plot_opt';
}

1;