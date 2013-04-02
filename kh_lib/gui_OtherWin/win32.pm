package gui_OtherWin::win32;
use base qw (gui_OtherWin);
use strict;

sub _open{
	my $self = shift;
	my $t = $self->target;
	require Win32;
	if ( Win32::IsWinNT() ){
		my $cmd;
		if ($t =~ /^http/o){
			$cmd = "start /MIN cmd.exe /c start $t";
		} else {
			$cmd = "start /MIN cmd.exe /c \"\"$t\"\"";
		}
		system $cmd;
		
		#use IPC::Run qw( start pump );
		#my ($in, $out,$err);
		#my $h = start ["cmd.exe"], \$in , \$out, \$err;
		#if ($t =~ /^http/o){
		#	$in = "start $t & exit\n";
		#} else {
		#	$in = "\"\"$t\"\" & exit\n";
		#}
		#pump $h while length $in;

	} else {
		system "start command.com /c start \"$t\"";
	}
}


1;
