package gui_window::r_plot_opt::word_netgraph;
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

		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		edge_type           => $self->{net_obj}->edge_type,
		n_or_j              => $self->{net_obj}->n_or_j,
		edges_num           => $self->{net_obj}->edges_num,
		edges_jac           => $self->{net_obj}->edges_jac,
		use_freq_as_size    => $self->{net_obj}->use_freq_as_size,
		use_freq_as_fsize   => $self->{net_obj}->use_freq_as_fsize,
		smaller_nodes       => $self->{net_obj}->smaller_nodes,
		use_weight_as_width => $self->{net_obj}->use_weight_as_width,
		min_sp_tree         => $self->{net_obj}->min_sp_tree,
		r_command         => $r_command,
		plotwin_name      => 'word_netgraph',
	);

	# プロットWindowを開く
	$wait_window->end(no_dialog => 1);
	
	if ($::main_gui->if_opened('w_word_netgraph_plot')){
		$::main_gui->get('w_word_netgraph_plot')->close;
	}

	return 0 unless $plotR;

	gui_window::r_plot::word_netgraph->open(
		plots       => $plotR->{result_plots},
		msg         => $plotR->{result_info},
		msg_long    => $plotR->{result_info_long},
		#no_geometry => 1,
	);

	$plotR = undef;

	$self->close;

	return 1;
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・共起ネットワーク：調整
}

sub win_name{
	return 'w_word_netgraph_plot_opt';
}

1;