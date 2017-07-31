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
		
		$self->{r_cmd} = undef;
	}

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
	gui_window->config_entry_focusin($self->{entry_d_y});


	my $fs  = $win->Frame()->pack(-fill => 'x', -pady => 1);

	$fs->Label(
		-text => kh_msg->get('scaling'),
		-font => "TKFN",
	)->pack(-side => 'left');

	gui_widget::optmenu->open(
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

	$self->{win_obj} = $win;
	return $self;
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
	);
}

sub x{
	my $self = shift;
	return gui_window->gui_jgn( $self->{entry_d_x}->get );
}

sub y{
	my $self = shift;
	return gui_window->gui_jgn( $self->{entry_d_y}->get );
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