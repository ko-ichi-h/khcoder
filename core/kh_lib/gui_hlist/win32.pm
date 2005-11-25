package gui_hlist::win32;
use base qw(gui_hlist);
use Win32::Clipboard;
use strict;

sub _copy{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	my $cols = pop @{$self->list->configure(-columns)}; --$cols;      # Îó¿ôÄ´¤Ù

	my $CLIP = Win32::Clipboard();
	my $clip;

	foreach my $i (@selected){
		for (my $c = 0; $c <= $cols; ++$c){
			if ( $self->list->itemExists($i, $c) ){
				$clip .= $self->list->itemCget($i, $c, -text)."\t";
			} else {
				$clip .= "\t";
			}
		}
		chop $clip;
		$clip .= "\n";
	}

	$clip = gui_window->gui_jg($clip);

	$CLIP->Empty();
	$CLIP->Set("$clip");
}
1;

