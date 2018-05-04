package gui_window::r_plot::word_som;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;
	if (@{$self->{plots}} == 4){
		return [
			kh_msg->get('cls'),  # クラスター
			kh_msg->get('gray'), # グレースケール
			kh_msg->get('freq'), # 度数
			kh_msg->get('umat'), # U行列
		];
	} else {
		return [
			kh_msg->get('gray'), # グレースケール
			kh_msg->get('freq'), # 度数
			kh_msg->get('umat'), # U行列
		];
	}
}

sub option1_name{
	return kh_msg->get('views'); # ' カラー：';
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