package gui_widget::url_lab;
use base qw(gui_widget);


sub _new{
	my $self = shift;
	
	my $l = $self->parent->Label(
		-text       => $self->{label},
		-font       => "TKFN",
		-foreground => 'blue',
		-cursor     => 'hand2',
	);
	
	$l->bind(
		"<Button-1>",
		sub {
			gui_OtherWin->open($self->{url});
		}
	);
	$l->bind(
		"<Enter>",
		sub {
			$l->configure(-foreground => 'red');
		}
	);
	$l->bind(
		"<Leave>",
		sub {
			$l->configure(-foreground => 'blue');
		}
	);
	
	
	
	$self->{win_obj} = $l;
	return $self;
}


1;