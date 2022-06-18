package gui_widget::r_margin;
use base qw(gui_widget);
use strict;
use Tk;
use utf8;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	my $f4  = $win->Frame()->pack(-fill => 'x', -pady => 4);

	$self->{margin_left}   = 0;
	$self->{margin_right}  = 0;
	$self->{margin_top}    = 0;
	$self->{margin_bottom} = 0;

	if ( length($self->{r_cmd}) ){
		if ( $self->{r_cmd} =~ /margin_left <\- ([0-9]+)\n/ ){
			$self->{margin_left} = $1;
		}
		if ( $self->{r_cmd} =~ /margin_right <\- ([0-9]+)\n/ ){
			$self->{margin_right} = $1;
		}
		if ( $self->{r_cmd} =~ /margin_top <\- ([0-9]+)\n/ ){
			$self->{margin_top} = $1;
		}
		if ( $self->{r_cmd} =~ /margin_bottom <\- ([0-9]+)\n/ ){
			$self->{margin_bottom} = $1;
		}
		$self->{r_cmd} = undef;
	}

	# margin
	$f4->Label(
		-text => kh_msg->get('margin'),
		-font => "TKFN",
	)->pack(-side => 'left');

	# top
	$f4->Label(
		-text => kh_msg->get('top'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_top} = $f4->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_top}->insert(0,$self->{margin_top});
	$self->{entry_top}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_top}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_top});
	
	# bottom
	$f4->Label(
		-text => kh_msg->get('bottom'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_bottom} = $f4->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_bottom}->insert(0,$self->{margin_bottom});
	$self->{entry_bottom}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_bottom}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_bottom});

	# left
	$f4->Label(
		-text => kh_msg->get('left'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_left} = $f4->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_left}->insert(0,$self->{margin_left});
	$self->{entry_left}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_left}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_left});
	
	# right
	$f4->Label(
		-text => kh_msg->get('right'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_right} = $f4->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_right}->insert(0,$self->{margin_right});
	$self->{entry_right}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_right}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_right});
	
	$self->{win_obj} = $win;
	return $self;
}

#----------------------#
#   設定へのアクセサ   #

sub params{
	my $self = shift;

	return (
		margin_top    => gui_window->gui_jgn( $self->{entry_top}->get ),
		margin_bottom => gui_window->gui_jgn( $self->{entry_bottom}->get ),
		margin_left   => gui_window->gui_jgn( $self->{entry_left}->get ),
		margin_right  => gui_window->gui_jgn( $self->{entry_right}->get ),
	);
}

1;