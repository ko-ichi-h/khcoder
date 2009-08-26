package gui_hlist::win32;
use base qw(gui_hlist);
use strict;

sub _copy{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	my $cols = pop @{$self->list->configure(-columns)}; --$cols;      # Îó¿ôÄ´¤Ù
	require Win32::Clipboard;
	my $CLIP = Win32::Clipboard();
	my $clip;

	foreach my $i (@selected){
		#print "row: $i\n";
		for (my $c = 0; $c <= $cols; ++$c){
			if ( $self->list->itemExists($i, $c) ){
				my $cell = $self->list->itemCget($i, $c, -text);
				$cell =  gui_window->gui_jg($cell);
				while ($cell =~ /\s$/o){
					chop $cell
				}
				$clip .= "$cell\t";
			} else {
				$clip .= "\t";
			}
		}
		chop $clip;
		$clip .= "\n";
	}

	if (defined($clip) && length($clip)){
		$CLIP->Empty();
		$CLIP->Set("$clip");
	}
}
1;

