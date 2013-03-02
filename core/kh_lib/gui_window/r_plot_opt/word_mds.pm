package gui_window::r_plot_opt::word_mds;
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

	# バブルプロット用のパラメーター
	my ($check_bubble, $chk_std_radius, $num_size, $num_var)
		= (0,1,100,100);

	if ( $self->{command_f} =~ /b_size/ ){
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

	# クラスター化のパラメーター
	if ( $self->{command_f} =~ /n_cls <\- ([0-9]+)\n/ ){
		$self->{cls_if} = $1;
		if ( $self->{cls_if} ){
			$self->{cls_n} = $self->{cls_if};
			$self->{cls_if} = 1;
		} else {
			$self->{cls_n} = 7;
		}
	} else {
		$self->{cls_if} = 0;
		$self->{cls_n}  = 7;
	}
	if ( $self->{command_f} =~ /cls_raw <\- ([0-9]+)\n/ ){
		my $v = $1;
		if ($v == 1){
			$self->{cls_nei} = 0;
		} else {
			$self->{cls_nei} = 1;
		}
		print "cls_nei: $self->{cls_nei}, v: $v,\n";
	}
	$self->{cls_obj} = gui_widget::cls4mds->open(
		parent       => $lf,
		command      => sub{ $self->calc; },
		pack    => {
			-anchor  => 'w',
		},
		check_cls    => $self->{cls_if},
		cls_n        => $self->{cls_n},
		check_nei    => $self->{cls_nei},
	);

	# 半透明の色
	$self->{use_alpha} = 1;
	if ( $self->{command_f} =~ /use_alpha <\- ([0-9]+)\n/ ){
		$self->{use_alpha} = $1;
	}
	$lf->Checkbutton(
		-variable => \$self->{use_alpha},
		-text     => kh_msg->get('gui_window::word_mds->r_alpha'), 
	)->pack(-anchor => 'w');

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
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		method         => $self->{mds_obj}->method,
		method_dist    => $self->{mds_obj}->method_dist,
		dim_number     => $self->{mds_obj}->dim_number,
		r_command      => $r_command,
		plotwin_name   => 'word_mds',
		bubble       => $self->{bubble_obj}->check_bubble,
		std_radius   => $self->{bubble_obj}->chk_std_radius,
		bubble_size  => $self->{bubble_obj}->size,
		bubble_var   => $self->{bubble_obj}->var,
		n_cls          => $self->{cls_obj}->n,
		cls_raw        => $self->{cls_obj}->raw,
		use_alpha      => $self->gui_jg( $self->{use_alpha} ),
	);
	$wait_window->end(no_dialog => 1);
	$self->close;
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・多次元尺度法：調整
}

sub win_name{
	return 'w_word_mds_plot_opt';
}

1;