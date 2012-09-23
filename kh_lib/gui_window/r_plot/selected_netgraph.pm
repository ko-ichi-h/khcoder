package gui_window::r_plot::selected_netgraph;
use base qw(gui_window::r_plot);

sub option1_options{
	return [
		kh_msg->get('gui_window::r_plot::word_netgraph->cnt_b'), # 中心性（媒介）
		kh_msg->get('gui_window::r_plot::word_netgraph->cnt_d'), # 中心性（次数）
		kh_msg->get('gui_window::r_plot::word_netgraph->cnt_v'), # 中心性（固有ベクトル）
		kh_msg->get('gui_window::r_plot::word_netgraph->com_b'), # サブグラフ検出（媒介）
		kh_msg->get('gui_window::r_plot::word_netgraph->com_r'),
		kh_msg->get('gui_window::r_plot::word_netgraph->com_m'), # サブグラフ検出（modularity）
		kh_msg->get('gui_window::r_plot::word_netgraph->none'),  # なし
	];
}

sub option1_name{
	return kh_msg->get('color'); #  カラー：
}

sub win_title{
	return kh_msg->get('win_title'); # 関連語・共起ネットワーク
}

sub win_name{
	return 'w_selected_netgraph_plot';
}


sub base_name{
	return 'selected_netgraph';
}

1;