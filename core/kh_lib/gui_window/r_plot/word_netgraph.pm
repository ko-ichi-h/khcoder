package gui_window::r_plot::word_netgraph;
use base qw(gui_window::r_plot);

sub option1_options{
	return [
		'カラー',
	];
}

sub option1_name{
	return ' 表示：';
}

sub win_title{
	return '抽出語・共起ネットワーク';
}

sub win_name{
	return 'w_word_netgraph_plot';
}


sub base_name{
	return 'word_netgraph';
}

1;