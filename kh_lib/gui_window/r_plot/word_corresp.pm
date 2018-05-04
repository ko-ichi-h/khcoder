package gui_window::r_plot::word_corresp;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;

	if (@{$self->{plots}} == 2){
		return [
			kh_msg->get('d_l'), # ドットとラベル
			kh_msg->get('d'), # ドットのみ
		] ;
	} else {
		return [
			kh_msg->get('col'), # カラー
			kh_msg->get('gray'), # グレースケール
			kh_msg->get('var'), # 変数のみ
			kh_msg->get('d'), # ドットのみ
		] ;
	}
}

sub option1_name{
	return kh_msg->get('view'); #  表示：
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・対応分析
}

sub win_name{
	return 'w_word_corresp_plot';
}

sub base_name{
	return 'word_corresp';
}

1;