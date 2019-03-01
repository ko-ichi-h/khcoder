package gui_widget::sampling;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

use kh_msg;

sub _new{
	my $self = shift;

	my $fr= $self->parent->Frame()->pack(-fill => 'both', -expand => 1);
	
	$fr->Label(-text => ' ')->pack(-side => 'left');
	
	$self->{check_w} = $fr->Checkbutton(
			-text     => kh_msg->get('sampling'),
			-variable => \$self->{check_sampling},
			-command => sub{$self->refresh},
			-anchor => 'w',
	)->pack(-anchor => 'w', -side => 'left');

	$self->{entry} = $fr->Entry(
		-width      => 7,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);

	$self->{entry}->insert(0,'500000');
	$self->{entry}->bind("<Return>", $self->{command})
		if defined( $self->{command} )
	;
	$self->{entry}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} )
	;
	gui_window->config_entry_focusin($self->{entry});
	
	
	$self->{win_obj} = $fr;
	$self->refresh;
	return $self;
}

sub refresh{
	my $self = shift;
	
	return 1 unless $self->{entry};
	
	if ( $self->{check_sampling} ){
		$self->{entry}->configure(-state => 'normal');
	} else {
		$self->{entry}->configure(-state => 'disabled');
	}
}

sub parameter{
	my $self = shift;
	if ($self->{check_sampling}) {
		return gui_window->gui_jgn( $self->{entry}->get );
	} else {
		return 0;
	}
	
}

1;
