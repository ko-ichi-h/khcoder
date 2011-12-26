package gui_window::r_plot::cod_mds;
use base qw(gui_window::r_plot);

sub option1_options{
	return [
		kh_msg->get('gui_window::r_plot::word_corresp->d_l'), # 'ドットとラベル',
		kh_msg->get('gui_window::r_plot::word_corresp->d'), # 'ドットのみ',
	];
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_corresp->view'); # ' 表示：';
}

sub win_title{
	return kh_msg->get('win_title'); # コーディング・多次元尺度法
}

sub win_name{
	return 'w_cod_mds_plot';
}


sub base_name{
	return 'cod_mds';
}

1;