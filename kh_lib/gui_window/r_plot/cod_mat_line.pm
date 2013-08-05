package gui_window::r_plot::cod_mat_line;
use base qw(gui_window::r_plot);


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
	return 'w_cod_mat_line';
}

sub base_name{
	return 'cod_mat_line';
}

1;