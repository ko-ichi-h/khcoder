package gui_window::r_plot::selected_netgraph;
use base qw(gui_window::r_plot);

sub option1_options{
	return [
		'中心性（媒介）',
		'中心性（次数）',
		'サブグラフ検出（媒介）',
		'サブグラフ検出（modularity）',
		'なし',
	];
}

sub option1_name{
	return ' カラー：';
}

sub win_title{
	return '関連語・共起ネットワーク';
}

sub win_name{
	return 'w_selected_netgraph_plot';
}


sub base_name{
	return 'selected_netgraph';
}

1;