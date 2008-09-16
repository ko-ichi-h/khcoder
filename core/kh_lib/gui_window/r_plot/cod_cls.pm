package gui_window::r_plot::cod_cls;
use base qw(gui_window::r_plot);

sub renew_command{
	my $self = shift;
	$self->{photo_pane}->yview(moveto => 0);
}

sub photo_pane_width{
	return 490;
}

sub option1_options{
	return [
		'Ward法',
		'群平均法',
		'最遠隣法'
	];
}

sub option1_name{
	return ' 方法：';
}

sub win_title{
	return 'コーディング・クラスター分析';
}

sub win_name{
	return 'w_cod_cls_plot';
}


sub base_name{
	return 'cod_cls';
}

1;