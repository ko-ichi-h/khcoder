package gui_widget::r_xy;
use base qw(gui_widget);
use strict;
use Tk;
use utf8;
use Jcode;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	
	$self->{x} = 1 unless defined $self->{x};
	$self->{y} = 2 unless defined $self->{y};
	$self->{check_origin} = 1 unless defined $self->{check_origin};
	$self->{scale_opt} = "none" unless defined $self->{scale_opt};
	$self->{check_zoom} = 0 unless defined $self->{check_zoom};

	if ( length($self->{r_cmd}) ){
		if ( $self->{r_cmd} =~ /\nd_x <\- ([0-9]+)\nd_y <\- ([0-9]+)\n/ ){
			$self->{x} = $1;
			$self->{y} = $2;
		}
		if ( $self->{r_cmd} =~ /\nshow_origin <\- ([0-9]+)\n/ ){
			$self->{check_origin} = $1;
		}
		if ( $self->{r_cmd} =~ /\nscaling <\- "([a-z]+)"\n/ ){
			$self->{scale_opt} = $1;
		}
		if ( $self->{r_cmd} =~ /\nzoom_factor <\- ([0-9\.]+)\n/ ){
			$self->{check_zoom} = $1;
		}
		
		$self->{r_cmd} = undef;
		$self->{config} = 1;
	} else {
		$self->{config} = 0;
	}

	if ( $self->{config} ){
		my $fz  = $win->Frame()->pack(-fill => 'x', -pady => 1);
	
		$fz->Checkbutton(
			-text     => kh_msg->get('zoom'),
			-variable => \$self->{check_zoom},
			-command  => sub{$self->refresh_zoom;}
		)->pack(
			-side => 'left'
		);
	
		$self->{label_zoom} = $fz->Label(
			-text => kh_msg->get('zoom_factor'),
			-font => "TKFN",
		)->pack(-side => 'left');
		
		$self->{entry_zoom} = $fz->Entry(
			-font       => "TKFN",
			-width      => 4,
			-background => 'white',
		)->pack(-side => 'left', -padx => 2);
		
		if ($self->{check_zoom}){
			$self->{entry_zoom}->insert(0,$self->{check_zoom});
			$self->{check_zoom} = 1;
		} else {
			$self->{entry_zoom}->insert(0,3);
		}
		$self->{entry_zoom}->bind("<Key-Return>",$self->{command})
			if defined( $self->{command} );
		$self->{entry_zoom}->bind("<KP_Enter>",  $self->{command})
			if defined( $self->{command} );
		gui_window->config_entry_focusin($self->{entry_zoom});
		gui_window->disabled_entry_configure($self->{entry_zoom});

	
		my $fd  = $win->Frame()->pack(-fill => 'x', -pady => 1);
		$fd->Label(
			-text => kh_msg->get('cmp_plot'), # プロットする成分：
			-font => "TKFN",
		)->pack(-side => 'left');
	
		#$self->{entry_d_n} = $fd->Entry(
		#	-font       => "TKFN",
		#	-width      => 2,
		#	-background => 'white',
		#)->pack(-side => 'left', -padx => 2);
		#$self->{entry_d_n}->insert(0,'2');
		#$self->{entry_d_n}->bind("<Key-Return>",sub{$self->calc;});
		#$self->config_entry_focusin($self->{entry_d_n});
	
		$fd->Label(
			-text => kh_msg->get('x'), #  X軸
			-font => "TKFN",
		)->pack(-side => 'left');
	
		$self->{entry_d_x} = $fd->Entry(
			-font       => "TKFN",
			-width      => 2,
			-background => 'white',
		)->pack(-side => 'left', -padx => 2);
		$self->{entry_d_x}->insert(0,$self->{x});
		$self->{entry_d_x}->bind("<Key-Return>",$self->{command})
			if defined( $self->{command} );
		$self->{entry_d_x}->bind("<KP_Enter>",  $self->{command})
			if defined( $self->{command} );
		gui_window->config_entry_focusin($self->{entry_d_x});
	
		$fd->Label(
			-text => kh_msg->get('y'), #  Y軸
			-font => "TKFN",
		)->pack(-side => 'left');
	
		$self->{entry_d_y} = $fd->Entry(
			-font       => "TKFN",
			-width      => 2,
			-background => 'white',
		)->pack(-side => 'left', -padx => 2);
		$self->{entry_d_y}->insert(0,$self->{y});
		$self->{entry_d_y}->bind("<Key-Return>",$self->{command})
			if defined( $self->{command} );
		$self->{entry_d_y}->bind("<KP_Enter>",  $self->{command})
			if defined( $self->{command} );
		gui_window->config_entry_focusin($self->{entry_d_y});
	}

	my $fs  = $win->Frame()->pack(-fill => 'x', -pady => 1);

	$fs->Label(
		-text => kh_msg->get('scaling'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{sc_obj} = gui_widget::optmenu->open(
		parent  => $fs,
		pack    => {-side => 'left'},
		options =>
			[
				[kh_msg->get('none'),  'none' ],
				[kh_msg->get('sym'),   'sym'  ],
				[kh_msg->get('symbi'), 'symbi'],
			],
		variable => \$self->{scale_opt},
	);

	$fs->Label(
		-text => '  ',
	)->pack(-side => 'left');

	$fs->Checkbutton(
		-text     => kh_msg->get('origin'),
		-variable => \$self->{check_origin},
	)->pack(
		-side => 'left'
	);
	
	$self->refresh_zoom;
	$self->{win_obj} = $win;
	return $self;
}

sub refresh_zoom{
	my $self = shift;
	return 0 unless $self->{config};
	if ($self->{check_zoom}) {
		$self->{label_zoom}->configure(-state, 'normal');
		$self->{entry_zoom}->configure(-state, 'normal');
		$self->{sc_obj}->{win_obj}->configure(-state, 'disable');
	} else {
		$self->{label_zoom}->configure(-state, 'disable');
		$self->{entry_zoom}->configure(-state, 'disable');
		$self->{sc_obj}->{win_obj}->configure(-state, 'normal');
	}
}

#----------------------#
#   設定へのアクセサ   #

sub params{
	my $self = shift;
	return (
		d_x         => $self->x,
		d_y         => $self->y,
		show_origin => $self->origin,
		scaling     => $self->scale,
		zoom        => $self->zoom,
	);
}

sub zoom{
	my $self = shift;
	if ( $self->{check_zoom} ){
		return gui_window->gui_jgn( $self->{entry_zoom}->get );
	} else {
		return 0;
	}
}

sub x{
	my $self = shift;
	if ($self->{config}) {
		$self->{x} = gui_window->gui_jgn( $self->{entry_d_x}->get );
	}
	return $self->{x};
}

sub y{
	my $self = shift;
	if ($self->{config}) {
		$self->{y} = gui_window->gui_jgn( $self->{entry_d_y}->get );
	}
	return $self->{y};
}

sub origin{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_origin} );
}

sub scale{
	my $self = shift;
	return gui_window->gui_jg( $self->{scale_opt} );
}

1;