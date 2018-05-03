package gui_window::r_plot_opt::cod_cls;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# クラスター分析のオプション
	$self->{cls_obj} = gui_widget::r_cls->open(
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

	if (
		   $self->{cls_obj}->cluster_number =~ /Auto/i
		|| $self->{font_obj}->plot_size     =~ /Auto/i
	) {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::r_plot_opt::word_cls->err_no_auto'),
		);
		return 0;
	}

	$r_command .= "# END: DATA\n";

	my $wait_window = gui_wait->start;
	&gui_window::word_cls::make_plot(
		$self->{cls_obj}->params,
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		r_command      => $r_command,
		plotwin_name   => 'cod_cls',
	);
	$wait_window->end(no_dialog => 1);
	$self->close;
	return 1;
}

sub win_title{
	return kh_msg->get('win_title'); # コーディング・クラスター分析：調整
}

sub win_name{
	return 'w_cod_cls_plot_opt';
}

1;