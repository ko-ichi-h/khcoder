package gui_window::r_plot::cod_mds;
use base qw(gui_window::r_plot);

sub option1_options{
	return [
		'ドットとラベル',
		'ドットのみ',
	];
}

sub option1_name{
	return ' 表示：';
}

sub win_title{
	return 'コーディング・多次元尺度法';
}

sub win_name{
	return 'w_cod_mds_plot';
}


sub base_name{
	return 'cod_mds';
}

1;