package gui_OtherWin::win32;
use base qw (gui_OtherWin);
use strict;
use Win32;

sub _open{
	my $self = shift;
	my $t = $self->target;
	if ( Win32::IsWinNT() ){
		system "start cmd.exe /c start $t";
	} else {
		system "start command.com /c start $t";
	}
}


1;
