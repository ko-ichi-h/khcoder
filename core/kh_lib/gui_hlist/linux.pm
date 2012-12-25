package gui_hlist::linux;
use base qw(gui_hlist);
use strict;

sub _copy{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	my $cols = pop @{$self->list->configure(-columns)}; --$cols;      # 列数調べ

	require Clipboard;
	Clipboard->import();

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
		Clipboard->copy( $self->_clip_code($clip) );
		#print "$clip\n";
		#$CLIP->Empty();
		#$CLIP->Set("$clip");
	}
}

sub _copy_all{
	my $self = shift;
	my $clip = gui_hlist->get_all($self->list);

	$clip = gui_window->gui_jg($clip);

	require Clipboard;
	Clipboard->import();

	if (defined($clip) && length($clip)){
		Clipboard->copy( $self->_clip_code($clip) );
	}
}

sub _clip_code{
	my $self = shift;
	my $t    = shift;

	if ($^O eq 'darwin'){
		Encode::from_to($t, 'cp932', 'MacJapanese');
	} else {
		Encode::from_to($t, 'cp932', 'UTF8');
	}

	print "t: $t\n";
	return $t;
}


1;

__END__

sub _copy{
	gui_errormsg->open(
		msg => 'Sorry, currently cannot copy on Unix systems.',
		type => 'msg',
	);
}

sub _copy_all{
	gui_errormsg->open(
		msg => 'Sorry, currently cannot copy on Unix systems.',
		type => 'msg',
	);
}