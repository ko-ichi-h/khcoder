package gui_window::r_plot::cod_corresp;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;

	if (@{$self->{plots}} == 2){
		return [
			kh_msg->get('gui_window::r_plot::word_corresp->d_l'), # ドットとラベル
			kh_msg->get('gui_window::r_plot::word_corresp->d'), # ドットのみ
		] ;
	} else {
		return [
			kh_msg->get('gui_window::r_plot::word_corresp->col'), # カラー
			kh_msg->get('gui_window::r_plot::word_corresp->gray'), # グレースケール
			kh_msg->get('gui_window::r_plot::word_corresp->var'), # 変数のみ
			kh_msg->get('gui_window::r_plot::word_corresp->d'), # ドットのみ
		] ;
	}
}

sub extra_save_types{
	return (
		[ "CSV",[qw/.csv/] ],
	);
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_corresp->view'); #  表示：
}

sub win_title{
	return kh_msg->get('win_title'); # コーディング・対応分析
}

sub win_name{
	return 'w_cod_corresp_plot';
}

sub base_name{
	return 'cod_corresp';
}

1;