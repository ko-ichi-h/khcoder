package gui_window::r_plot::cod_cls;
use base qw(gui_window::r_plot);

sub renew_command{
	my $self = shift;
	$self->{photo_pane}->yview(moveto => 0);

	if ($::main_gui->if_opened('w_cod_cls_height')){
		$::main_gui->get('w_cod_cls_height')->renew(
			$self->{ax}
		);
	}
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

sub start{
	my $self = shift;
	$self->{bottom_frame}->Button(
		-text => $self->gui_jchar('併合水準'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			if ($::main_gui->if_opened('w_cod_cls_height')){
				$::main_gui->get('w_cod_cls_height')->renew(
					$self->{ax}
				);
			} else {
				gui_window::cls_height::cod->open(
					plots => $self->{merges},
					type  => $self->{ax},
				);
			}
		}
	)->pack(-side => 'left',-padx => 2);
}

sub end{
	my $self = shift;
	
	if ($::main_gui->if_opened('w_cod_cls_height')){
		$::main_gui->get('w_cod_cls_height')->close;
	}
	
	&gui_window::r_plot::end($self);
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