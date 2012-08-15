package gui_window::r_plot::word_som;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;
	if (@{$self->{plots}} == 2){
		return [
			kh_msg->get('gui_window::r_plot::word_corresp->col'),  # カラー
			kh_msg->get('gui_window::r_plot::word_corresp->gray'), # グレー
		];
	} else {
		return [
			kh_msg->get('gui_window::r_plot::word_corresp->gray'), # グレー
		];
	}
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_corresp->view'); # ' 表示：';
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・自己組織化マップ
}

sub win_name{
	return 'w_word_som_plot';
}


sub base_name{
	return 'word_som';
}

1;