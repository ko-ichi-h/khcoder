package gui_window::r_plot::word_netgraph;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;
	
	if (@{$self->{plots}} == 2){
		return [
			kh_msg->get('gui_window::r_plot::word_netgraph->col'), # カラー
			kh_msg->get('gui_window::r_plot::word_netgraph->gray'), # グレー
		] ;
	} else {
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

}

sub save{
	my $self = shift;

	# 保存先の参照
	my @types = (
		[ "Encapsulated PostScript",[qw/.eps/] ],
		[ "PDF",[qw/.pdf/] ],
		[ "SVG",[qw/.svg/] ],
		[ "PNG",[qw/.png/] ],
		[ "GraphML",[qw/.graphml/] ],
		[ "Pajek",[qw/.net/] ],
		[ "R Source",[qw/.r/] ],
	);
	@types = ([ "Enhanced Metafile",[qw/.emf/] ], @types)
		if $::config_obj->os eq 'win32';

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.pdf',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('gui_window::r_plot->saving')), # プロットを保存
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	$self->{plots}[$self->{ax}]->save($path) if $path;

	return 1;
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_netgraph->color'); #  カラー：
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・共起ネットワーク
}

sub win_name{
	return 'w_word_netgraph_plot';
}


sub base_name{
	return 'word_netgraph';
}

1;