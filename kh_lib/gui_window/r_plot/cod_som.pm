package gui_window::r_plot::cod_som;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;
	if (@{$self->{plots}} == 4){
		return [
			kh_msg->get('gui_window::r_plot::word_som->cls'),  # クラスター
			kh_msg->get('gui_window::r_plot::word_som->gray'), # グレースケール
			kh_msg->get('gui_window::r_plot::word_som->freq'), # 度数
			kh_msg->get('gui_window::r_plot::word_som->umat'), # U行列
		];
	} else {
		return [
			kh_msg->get('gui_window::r_plot::word_som->gray'), # グレースケール
			kh_msg->get('gui_window::r_plot::word_som->freq'), # 度数
			kh_msg->get('gui_window::r_plot::word_som->umat'), # U行列
		];
	}
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_som->views'); # ' カラー：';
}

sub win_title{
	return kh_msg->get('win_title'); # コード・自己組織化マップ
}

sub win_name{
	return 'w_cod_som_plot';
}


sub base_name{
	return 'cod_som';
}

1;