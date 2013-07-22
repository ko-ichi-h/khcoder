package gui_window::r_plot::cod_mat;
use base qw(gui_window::r_plot);


sub option1_options{
	return [ 'nothing' ];
}

sub option1_name{
	return '';
}

sub win_title{
	return kh_msg->get('win_title');
}

sub win_name{
	return 'w_cod_mat_plot';
}


sub base_name{
	return 'cod_mat';
}


1;