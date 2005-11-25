package gui_hlist;
use Tk;
use Tk::HList;
use gui_hlist::win32;
use gui_hlist::linux;

# Usage:
# 	gui_hlist->copy($hlist_obj);
# 	gui_hlist->copy($get_all);

sub copy{
	my $class = shift;
	my $self;
	$self->{list} = shift;
	bless $self, "$class"."::".$::config_obj->os;
	$self->_copy;
}

sub get_all{
	my $class = shift;
	my $self;
	$self->{list} = shift;
	bless $self, "$class"."::".$::config_obj->os;
	
	# —ñ”
	my $cols = pop @{$self->list->configure(-columns)}; --$cols;
	
	my $t = '';
	my $n = 0;
	while ($self->list->info('exists', $n)){
		#print "n$n, ";
		for (my $c = 0; $c <= $cols; ++$c){
			if ( $self->list->itemExists($n, $c) ){
				$t .= $self->list->itemCget($n, $c, -text)."\t";
				#print "c$c: ".$self->list->itemCget($n, $c, -text).", ";
			} else {
				$t .= "\t";
			}
		}
		#print "line-end\n";
		chop $t; $t .= "\n";
		++$n;
	}
	return $t;
}

sub list{
	my $self = shift;
	return $self->{list};
}

1;
