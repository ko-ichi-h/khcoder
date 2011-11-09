package gui_window::r_plot::cod_netg;
use base qw(gui_window::r_plot);

sub option1_options{
	return [
		'中心性（媒介）',
		'中心性（次数）',
		'中心性（固有ベクトル）',
		'サブグラフ検出（媒介）',
		'サブグラフ検出（modularity）',
		'なし',
	];
}

sub option1_name{
	return ' カラー：';
}

sub win_title{
	return 'コーディング・共起ネットワーク';
}

sub win_name{
	return 'w_cod_netg_plot';
}


sub base_name{
	return 'cod_netg';
}

1;