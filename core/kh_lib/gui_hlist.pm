package gui_hlist;
use Tk;
use Tk::HList;
use gui_hlist::win32;
use gui_hlist::linux;

# Usage:
# 	gui_hlist->copy($hlist_obj);

sub copy{
	my $class = shift;
	my $self;
	$self->{list} = shift;
	bless $self, "$class"."::".$::config_obj->os;
	$self->_copy;
}

sub list{
	my $self = shift;
	return $self->{list};
}

1;
