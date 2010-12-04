package gui_window::sysconfig::win32::chasen;
use strict;
use base qw(gui_window::sysconfig::win32);

sub gui_switch{
	my $self = shift;
	$self->entry1->configure(-state => 'normal');
	$self->btn1->configure(-state => 'normal');
	$self->lb1->configure(-state => 'normal');
	
	$self->entry2->configure(-state => 'disable');
	$self->btn2->configure(-state => 'disable');
	$self->lb2->configure(-state => 'disable');
}

sub open_msg{
	return 'Chasen.exeを開いてください';
}
sub entry{
	my $self = shift;
	return $self->entry1;
}

1;

__END__
