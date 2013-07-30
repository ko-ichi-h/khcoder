package gui_window::r_plot::cod_mat;
use base qw(gui_window::r_plot);


sub option1_options{
	return [
		kh_msg->get('heat'), # 'ヒートマップ',
		kh_msg->get('fluc'), # 'バブルプロット',
	];
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_corresp->view'); # ' 表示：';
}

sub photo_pane_width{
	my $self = shift;
	return 640;
}

# 画像表示用オブジェクトを再作成（スクロールバーをリセットするため）
sub renew{
	my $self = shift;
	return 0 unless $self->{optmenu};

	$gui_window::r_plot::imgs->{$self->win_name}->delete;
	$gui_window::r_plot::imgs->{$self->win_name}->destroy;
	$gui_window::r_plot::imgs->{$self->win_name} = undef;

	$gui_window::r_plot::imgs->{$self->win_name} = 
		$self->{win_obj}->Photo('photo_'.$self->win_name,
			-file => $self->{plots}[$self->{ax}]->path,
		)
	;

	$self->renew_command;
}

sub win_title{
	return kh_msg->get('win_title');
}

sub win_name{
	return 'w_cod_mat_plot';
}


sub base_name{
	return 'cod_mat';
}


1;