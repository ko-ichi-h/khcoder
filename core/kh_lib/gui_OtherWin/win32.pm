package gui_OtherWin::win32;
use base qw (gui_OtherWin);
use strict;
use Win32;

sub _open{
	my $self = shift;
	my $t = $self->target;
	if ( Win32::IsWinNT() ){
		my $cmd;
		if ($t =~ /^http/o){
			$cmd = "start /MIN cmd.exe /c start $t";
		} else {
			$cmd = "start /MIN cmd.exe /c \"$t\"";
		}
#		print "$cmd\n";
		system $cmd;
	} else {
		system "start command.com /c start \"$t\"";
	}
}


1;
