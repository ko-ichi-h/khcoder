package gui_window::doc_search::win32;
use base qw(gui_window::doc_search);

use strict;
use mysql_getdoc;

sub _copy{
	my $self = shift;
	my @selected = $self->{rlist}->infoSelection;
	unless (@selected){
		return;
	}
	
	my $t;
	foreach my $i (@selected){
		
		my $doc = mysql_getdoc->get(
			doc_id => $self->{result}[$i][0],
			tani   => $self->tani,
		);
		
		$t .= $doc->header;
		foreach my $i (@{$doc->body}){
			$t .= $i->[0];
		}
		$t .= "\n";
	}
	
	use Win32::Clipboard;
	my $CLIP = Win32::Clipboard();
	$CLIP->Empty();
	$CLIP->Set("$t");
	return 1;
}

1;