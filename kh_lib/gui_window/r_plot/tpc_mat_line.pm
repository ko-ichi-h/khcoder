package gui_window::r_plot::tpc_mat_line;
use base qw(gui_window::r_plot);

sub start{
	my $self = shift;
	
	$self->{bottom_frame}->Label(
		-text => '  ',
		-font => "TKFN"
	)->pack(-side => 'left');
	
	$self->{bottom_frame}->Label(
		-text => kh_msg->get('gui_window::topic_stats->var'), # 集計：
		-font => "TKFN"
	)->pack(-side => 'left');
	
	$self->{var_obj} =  gui_widget::select_a_var->open(
		parent          => $self->{bottom_frame},
		tani            => $self->{tani},
		show_headings   => 1,
		higher_headings => 1,
		no_topics       => 1,
		add_position2   => 1,
		command         => sub {
			my $win = $::main_gui->get('w_topic_stats');
			
			$win->{var_obj}{var_id} = $self->{var_obj}->var_id;
			$win->{var_obj}{opt_body}->set_value( $self->{var_obj}->var_id );
			$win->_calc;
		},
	);
	
	$self->{var_obj}{var_id} = $self->{var};
	$self->{var_obj}{opt_body}->set_value( $self->{var} );
	
	print "tani: $self->{tani}, var: $self->{var}\n";
}

sub extra_param_4config{
	my $self = shift;
	return (
		tani => $self->{tani},
		var  => $self->{var_obj}->var_id,
	);
}

sub option1_options{
	return [
		'nothing'
	];
}

sub photo_pane_width{
	my $self = shift;
	return 640;
}

sub option1_name{
	return '';
}

sub win_title{
	return kh_msg->get('win_title');
}

sub win_name{
	return 'w_tpc_mat_line';
}

sub base_name{
	return 'tpc_mat_line';
}

1;