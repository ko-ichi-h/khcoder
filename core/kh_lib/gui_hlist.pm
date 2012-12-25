package gui_hlist;
use Tk;
use Tk::HList;
use Clipboard;
#use gui_hlist::win32;
#use gui_hlist::linux;

# Usage:
# 	gui_hlist->copy(     $hlist_obj );
# 	gui_hlist->copy_all( $hlist_obj );

my $debug = 0;

sub copy{
	my $class = shift;
	my $self;
	$self->{list} = shift;
	bless $self, $class;

	my @selected = $self->list->infoSelection;
	my $cols = pop @{$self->list->configure(-columns)}; --$cols;      # —ñ”’²‚×
	my $clip;

	foreach my $i (@selected){
		#print "row: $i\n";
		for (my $c = 0; $c <= $cols; ++$c){
			if ( $self->list->itemExists($i, $c) ){
				my $cell = $self->list->itemCget($i, $c, -text);
				#$cell =  gui_window->gui_jg($cell);
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
		Clipboard->copy( Encode::encode($::config_obj->os_code,$clip) );
	}
}

sub copy_all{
	my $class = shift;
	my $self;
	$self->{list} = shift;
	bless $self, $class;

	my $clip = gui_hlist->get_all($self->list);

	if (defined($clip) && length($clip)){
		Clipboard->copy( Encode::encode($::config_obj->os_code,$clip) );
	}
}

sub update4scroll{
	my $class = shift;
	my $self;
	$self->{list} = shift;
	bless $self, "$class"."::".$::config_obj->os;
	
	$self->{list}->update;
	$self->{list}->yview(moveto => 0);
	$self->{list}->yview('scroll', 1,'units');
	$self->{list}->yview('scroll',-1,'units');
}

sub get_all{
	my $class = shift;
	my $self;
	$self->{list} = shift;
	bless $self, $class;
	
	# —ñ”
	my $cols = pop @{$self->list->configure(-columns)}; --$cols;
	print "gui_hlist / cols: $cols\n" if $debug;
	
	my $t = '';
	my $n = 0;
	while ($self->list->info('exists', $n)){
		# ’Êí‚Ìs
		print "n$n, " if $debug;
		for (my $c = 0; $c <= $cols; ++$c){
			if ( $self->list->itemExists($n, $c) ){
				$t .= $self->list->itemCget($n, $c, -text)."\t";
				print "c$c: ".$self->list->itemCget($n, $c, -text).", " if $debug;
			} else {
				$t .= "\t";
			}
		}
		print "line-end\n" if $debug;
		chop $t; $t .= "\n";
		
		# q‹Ÿ‚Ìs
		my @children = $self->list->info('children', $n);
		foreach my $i (@children){
			print "n$i, " if $debug;
			$t .= "[]";
			for (my $c = 0; $c <= $cols; ++$c){
				if ( $self->list->itemExists($i, $c) ){
					$t .= $self->list->itemCget($i, $c, -text)."\t";
					print "c$c: ".$self->list->itemCget($i, $c, -text).", " if $debug;
				} else {
					print "c$c: [none]," if $debug;
					$t .= "\t";
				}
			}
			print "line-end\n" if $debug;
			chop $t; $t .= "\n";
			++$n;
		}
		
		
		++$n;
	}
	return $t;
}

sub list{
	my $self = shift;
	return $self->{list};
}

1;
