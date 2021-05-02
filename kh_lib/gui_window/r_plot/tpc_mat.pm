package gui_window::r_plot::tpc_mat;
use base qw(gui_window::r_plot);

sub start{
	my $self = shift;
	
	$self->{bottom_frame}->Label(
		-text => '  ',
		-font => "TKFN"
	)->pack(-side => 'left');
	
	$self->{bottom_frame}->Label(
		-text => kh_msg->get('gui_window::topic_stats->var'), # 集計：
		-font => "TKFN"
	)->pack(-side => 'left');
	
	$self->{var_obj} =  gui_widget::select_a_var->open(
		parent          => $self->{bottom_frame},
		tani            => $self->{tani},
		show_headings   => 1,
		higher_headings => 1,
		no_topics       => 1,
		command         => sub {
			my $win = $::main_gui->get('w_topic_stats');
			
			$win->{var_obj}{var_id} = $self->{var_obj}->var_id;
			$win->{var_obj}{opt_body}->set_value( $self->{var_obj}->var_id );
			$win->_calc;
		},
	);
	
	$self->{var_obj}{var_id} = $self->{var};
	$self->{var_obj}{opt_body}->set_value( $self->{var} );
	
	print "tani: $self->{tani}, var: $self->{var}\n";
}

sub option1_options{
	return [
		kh_msg->get('heat'), # 'ヒートマップ',
		#kh_msg->get('fluc'), # 'バブルプロット',
	];
}

sub option1_name{
	return ''; # kh_msg->get('gui_window::r_plot::word_corresp->view'); # ' 表示：';
}

sub photo_pane_width{
	my $self = shift;
	return $::config_obj->plot_size_words;
}

# 調整用のWindowを開く
sub open_config{
	my $self = shift;
	
	# 画像サイズの取得
	my $ax = $self->{ax};
	$self->{ax} = 0;
	$self->renew(1);
	my $plot_size_heat = $self->img_height;
	
	$self->{ax} = 1;
	$self->renew(1);
	my $plot_size_maph = $self->img_height;
	my $plot_size_mapw = $self->img_width;
	
	$self->{ax} = $ax;
	$self->renew(1);
	print "size: $plot_size_heat, $plot_size_maph, $plot_size_mapw\n";

	my $base_name = 'gui_window::r_plot_opt::'.$self->base_name;
	$self->{child} = $base_name->open(
		command_f      => $self->{plots}[$self->{ax}]->command_f,
		font_size      => $self->{plots}[$self->{ax}]->{font_size} * 100,
		ax             => $self->{ax},
		plot_size_heat => $plot_size_heat,
		plot_size_maph => $plot_size_maph,
		plot_size_mapw => $plot_size_mapw,
		$self->extra_param_4config,
	);
	
	return $self;
}

sub extra_param_4config{
	my $self = shift;
	return (
		tani => $self->{tani},
		var  => $self->{var_obj}->var_id,
	);
}

sub img_height{
	my $self = shift;
	return $gui_window::r_plot::imgs->{$self->win_name}->height;
}
sub img_width{
	my $self = shift;
	return $gui_window::r_plot::imgs->{$self->win_name}->width;
}

# 画像表示用オブジェクトを再作成（スクロールバーをリセットするため）
sub renew{
	my $self = shift;
	my $opt  = shift;
	
	return 0 unless $self->{optmenu};

	$self->{photo_pane}->xview(moveto => 0) unless $opt;
	$self->{photo_pane}->yview(moveto => 0) unless $opt;

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
	return 'w_tpc_mat_plot';
}


sub base_name{
	return 'tpc_mat';
}

sub child_windows{
	return ('');
}

1;