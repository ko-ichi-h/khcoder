package gui_window::sysconfig::win32::chasen;
use strict;
use base qw(gui_window::sysconfig::win32);

sub gui_switch{
	return 1;
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
