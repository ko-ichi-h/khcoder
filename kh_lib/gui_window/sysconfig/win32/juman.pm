package gui_window::sysconfig::win32::juman;
use base qw(gui_window::sysconfig::win32);

sub gui_switch{
	my $self = shift;
	$self->entry1->configure(-state => 'disable');
	$self->entry1->configure(-background => 'gray');
	$self->btn1->configure(-state => 'disable');
#	$self->chk->configure(-state => 'disable');
#	$self->chk2->configure(-state => 'disable');
	$self->lb1->configure(-foreground => '#848284');
	
	$self->entry2->configure(-state => 'normal');
	$self->entry2->configure(-background => 'white');
	$self->btn2->configure(-state => 'normal');
	$self->lb2->configure(-foreground => 'black');
}

sub open_msg{
	return 'Juman.exeを開いてください';
}
sub entry{
	my $self = shift;
	return $self->entry2;
}

1;

__END__
