package gui_window::sysconfig::linux::chasen;
use strict;
use base qw(gui_window::sysconfig::linux);

sub gui_switch{
	my $self = shift;
	$self->entry1->configure(-state => 'normal');
	#$self->entry1->configure(-background => 'white');
	$self->btn1->configure(-state => 'normal');
#	$self->chk->configure(-state => 'normal');
#	$self->chk2->configure(-state => 'normal');
	$self->lb1->configure(-state => 'normal');

	$self->entry2->configure(-state => 'normal');
	#$self->entry2->configure(-background => 'gray');
	$self->btn2->configure(-state => 'normal');
	$self->lb2->configure(-state => 'normal');
}

1;

__END__
