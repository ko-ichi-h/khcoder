package gui_window::r_plot_opt::cod_mat;
use base qw(gui_window::r_plot_opt);

use strict;

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};


	if ( $self->{command_f} =~ /dendro_c <\- ([0-9]+)\n/ ){
		$self->{heat_dendro_c} = $1;
	}

	if ( $self->{command_f} =~ /dendro_v <\- ([0-9]+)\n/ ){
		$self->{heat_dendro_v} = $1;
	}

	if ( $self->{command_f} =~ /cellnote <\- ([0-9]+)\n/ ){
		$self->{heat_cellnote} = $1;
	}

	$lf->Checkbutton(
		-variable => \$self->{heat_cellnote},
		-text     => kh_msg->get('cellnote'), 
	)->pack(-anchor => 'w');

	$lf->Checkbutton(
		-variable => \$self->{heat_dendro_c},
		-text     => kh_msg->get('dendro_c'), 
	)->pack(-anchor => 'w');

	$lf->Checkbutton(
		-variable => \$self->{heat_dendro_v},
		-text     => kh_msg->get('dendro_v'), 
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
	use plotR::code_mat;
	my $plot = plotR::code_mat->new(
		r_command      => $r_command,
		font_size      => $self->{font_obj}->font_size,
		font_bold      => $self->{font_obj}->check_bold_text,
		plot_size_heat => $self->{font_obj}->plot_size, # 変更？
		heat_dendro_c  => $self->gui_jg( $self->{heat_dendro_c} ),
		heat_dendro_v  => $self->gui_jg( $self->{heat_dendro_v} ),
		heat_cellnote  => $self->gui_jg( $self->{heat_cellnote} ),
		plotwin_name   => 'code_mat',
	);
	$wait_window->end(no_dialog => 1);

	if ($::main_gui->if_opened('w_cod_mat_plot')){
		$::main_gui->get('w_cod_mat_plot')->close;
	}

	return 0 unless $plot;

	use gui_window::r_plot::cod_mat;
	gui_window::r_plot::cod_mat->open(
		plots       => $plot->{result_plots},
		ax          => $self->{ax},
	);

	$plot = undef;

	$self->close;

	return 1;
}




sub win_title{
	return kh_msg->get('win_title'); # コーディング・多次元尺度法：調整
}

sub win_name{
	return 'w_cod_mat_plot_opt';
}

1;