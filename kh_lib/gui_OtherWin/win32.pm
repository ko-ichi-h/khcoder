package gui_OtherWin::win32;
use base qw (gui_OtherWin);
use strict;

sub _open{
	my $self = shift;
	my $t = $self->target;
	require Win32;
	if ( Win32::IsWinNT() ){
	
		### system関数（シンプル）
		system("start \"khcoder\" \"$t\"");

		### system関数
		#my $cmd;
		#if ($t =~ /^http/o){
		#	$cmd = "start /MIN cmd.exe /c start $t";
		#} else {
		#	$cmd = "start /MIN cmd.exe /c \"\"$t\"\"";
		#}
		#system $cmd;
		
		### IPC::Run →perlappとの相性×
		#if(defined(&PerlApp::extract_bound_file)){
		#	my $path = $ENV{'PWD'}.'/'.PerlApp::extract_bound_file('perl.exe');
		#	$path = Jcode->new($path,'sjis')->euc;
		#	$path =~ s/\\/\//g;
		#	$path = Jcode->new($path,'euc')->sjis;
		#	$^X = $path;
		#	print "perlapp: $path\n";
		#}
		#use IPC::Run qw( start pump );
		#my ($in, $out,$err);
		#my $h = start ["cmd.exe"], \$in , \$out, \$err;
		#if ($t =~ /^http/o){
		#	$in = "start $t & exit\n";
		#} else {
		#	$in = "\"\"$t\"\" & exit\n";
		#}
		#pump $h while length $in;

		### IPC::System::Symple
		#require IPC::System::Simple;
		#IPC::System::Simple::system("start \"khcoder\" \"$t\"");

	} else {
		system "start command.com /c start \"$t\"";
	}
}


1;
