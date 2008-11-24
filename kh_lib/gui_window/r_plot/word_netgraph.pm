package gui_window::r_plot::word_netgraph;
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
	return '抽出語・共起ネットワークグラフ';
}

sub win_name{
	return 'w_word_netgraph_plot';
}


sub base_name{
	return 'word_netgraph';
}

1;