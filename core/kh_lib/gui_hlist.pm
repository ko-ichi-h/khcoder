package gui_hlist;
use Tk;
use Tk::HList;
use Win32::Clipboard;
use Data::Dumper;

# Usage:
# 	gui_hlist->copy($hlist_obj);

sub copy{
	my $class = shift;
	my $hlist = shift;
	my @selected = $hlist->infoSelection;
	my $cols = pop @{$hlist->configure(-columns)}; --$cols;      # Îó¿ôÄ´¤Ù

	my $CLIP = Win32::Clipboard();
	my $clip;

	foreach my $i (@selected){
		for (my $c = 0; $c <= $cols; ++$c){
			$clip .= $hlist->itemCget($i, $c, -text)."\t";
		}
		chop $clip;
		$clip .= "\n";
	}

	$CLIP->Empty();
	$CLIP->Set("$clip");
}


1;