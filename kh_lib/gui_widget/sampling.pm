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

	#$self->{entry}->insert(0,'500000');
	$self->{entry}->bind("<Return>", $self->{command})
		if defined( $self->{command} )
	;
	$self->{entry}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} )
	;
	gui_window->config_entry_focusin($self->{entry});
	
	$self->{target} = 500000;
	my $d = $self->sampling_target;
	$self->{target} = $d if $d;
	$self->{entry}->insert(0,$self->{target});
	
	$self->{win_obj} = $fr;
	$self->refresh;
	return $self;
}

sub sampling_target{
	my $self = shift;
	
	my $ram = $::config_obj->ram;
	return 0 unless $ram;
	
	print "RAM: $ram\n";
	
	my $target = 1250000;
	if ($ram < 1023){
		$target = 10000
	}
	elsif ($ram < 2047){
		$target = 25000;
	}
	elsif ($ram < 2800){
		$target = 50000;
	}
	elsif ($ram < 7000){
		$target = 100000;
	}
	elsif ($ram < 13000){
		$target = 250000;
	}
	elsif ($ram < 25000){
		$target = 500000;
	}
	elsif ($ram < 32767){
		$target = 1000000;
	}
	return $target;
}

sub onoff{
	my $self = shift;
	my $n = shift;
	
	if ($n > $self->{target}) {
		$self->{check_sampling} = 1;
	} else {
		$self->{check_sampling} = 0;
	}
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
