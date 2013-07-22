package gui_window::r_plot_opt::cod_mat;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};


	#if ( $self->{command_f} =~ /std_radius <\- ([0-9]+)\n/ ){
	#	$chk_std_radius = $1;
	#}



	# 半透明の色
	#$self->{use_alpha} = 1;
	#if ( $self->{command_f} =~ /use_alpha <\- ([0-9]+)\n/ ){
	#	$self->{use_alpha} = $1;
	#}
	#$lf->Checkbutton(
	#	-variable => \$self->{use_alpha},
	#	-text     => kh_msg->get('gui_window::word_mds->r_alpha'), 
	#)->pack(-anchor => 'w');

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
			msg  => kh_msg->gget('r_net_msg_fail'),
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}
	$r_command .= "# END: DATA\n";

	my $wait_window = gui_wait->start;
	&gui_window::word_mds::make_plot(
		font_size    => $self->{font_obj}->font_size,
		font_bold    => $self->{font_obj}->check_bold_text,
		plot_size    => $self->{font_obj}->plot_size,
		method       => $self->{mds_obj}->method,
		method_dist  => $self->{mds_obj}->method_dist,
		dim_number   => $self->{mds_obj}->dim_number,
		r_command    => $r_command,
		plotwin_name => 'cod_mds',
		bubble       => $self->{bubble_obj}->check_bubble,
		std_radius   => $self->{bubble_obj}->chk_std_radius,
		bubble_size  => $self->{bubble_obj}->size,
		bubble_var   => $self->{bubble_obj}->var,
		n_cls        => $self->{cls_obj}->n,
		cls_raw      => $self->{cls_obj}->raw,
		use_alpha      => $self->gui_jg( $self->{use_alpha} ),
	);
	$wait_window->end(no_dialog => 1);
	$self->close;

}

sub win_title{
	return kh_msg->get('win_title'); # コーディング・多次元尺度法：調整
}

sub win_name{
	return 'w_cod_mat_plot_opt';
}

1;