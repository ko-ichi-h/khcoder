package gui_window::r_plot::cod_corresp;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;

	if (@{$self->{plots}} == 2){
		return [
			'ドットとラベル',
			'ドットのみ',
		] ;
	} else {
		return [
			'カラー',
			'グレースケール',
			'変数のみ',
			'ドットのみ',
		] ;
	}
}

sub option1_name{
	return ' 表示：';
}

sub win_title{
	return 'コーディング・対応分析';
}

sub win_name{
	return 'w_cod_corresp_plot';
}

sub base_name{
	return 'cod_corresp';
}

1;