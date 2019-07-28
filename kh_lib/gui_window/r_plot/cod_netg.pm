package gui_window::r_plot::cod_netg;
use base qw(gui_window::r_plot);

sub start{
	my $self = shift;
	
	$self->{button_interactive} = $self->{bottom_frame}->Button(
		-text => kh_msg->get('gui_window::r_plot::word_netgraph->interactive'), # interactive html
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			my $html = $::project_obj->file_TempHTML;
			$self->{plots}[$self->{ax}]->save($html);
			gui_OtherWin->open($html);
		}
	)->pack(-side => 'right');
	
	$self->win_obj->bind(
		'<Key-h>',
		sub{
			$self->{button_interactive}->flash;
			$self->{button_interactive}->invoke;
		}
	);
}

sub option1_options{
	my $self = shift;

	if (@{$self->{plots}} == 2){
		return [
			kh_msg->get('gui_window::r_plot::word_netgraph->col'), # カラー
			kh_msg->get('gui_window::r_plot::word_netgraph->gray'), # グレー
		] ;
	}
	elsif (@{$self->{plots}} == 3){
		return [
			kh_msg->get('gui_window::r_plot::word_netgraph->com_r'),
			kh_msg->get('gui_window::r_plot::word_netgraph->com_m'), # サブグラフ検出（modularity）
			kh_msg->get('gui_window::r_plot::word_netgraph->none'),  # なし
		];
	}
	elsif (@{$self->{plots}} == 4){
		return [
			kh_msg->get('gui_window::r_plot::word_netgraph->com_r'),
			kh_msg->get('gui_window::r_plot::word_netgraph->com_m'), # サブグラフ検出（modularity）
			kh_msg->get('gui_window::r_plot::word_netgraph->cor'),  # 相関
			kh_msg->get('gui_window::r_plot::word_netgraph->none'),  # なし
		];
	}
	elsif (@{$self->{plots}} == 8){
		return [
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_b'), # 中心性（媒介）
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_d'), # 中心性（次数）
			kh_msg->get('gui_window::r_plot::word_netgraph->cnt_v'), # 中心性（固有ベクトル）
			kh_msg->get('gui_window::r_plot::word_netgraph->com_b'), # サブグラフ検出（媒介）
			kh_msg->get('gui_window::r_plot::word_netgraph->com_r'),
			kh_msg->get('gui_window::r_plot::word_netgraph->com_m'), # サブグラフ検出（modularity）
			kh_msg->get('gui_window::r_plot::word_netgraph->cor'),  # 相関
			kh_msg->get('gui_window::r_plot::word_netgraph->none'),  # なし
		];
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

sub extra_save_types{
	return (
		[ "GraphML",[qw/.graphml/] ],
		[ "Pajek",[qw/.net/] ],
		[ "Interactive HTML",[qw/.html/] ],
	);
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_netgraph->color'); #  カラー：
}

sub win_title{
	return kh_msg->get('win_title'); # コーディング・共起ネットワーク
}

sub win_name{
	return 'w_cod_netg_plot';
}


sub base_name{
	return 'cod_netg';
}

1;