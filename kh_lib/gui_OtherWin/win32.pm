package gui_OtherWin::win32;
use base qw (gui_OtherWin);
use strict;

my $cmd_path = '';

sub _open{
	my $self = shift;
	my $t = $self->target;
	require Win32;
	if ( Win32::IsWinNT() ){
		# Win32::Process
		unless ($cmd_path){            # cmd.exeを探す
			if (-e $ENV{'WINDIR'}.'\system32\cmd.exe'){
				$cmd_path = $ENV{'WINDIR'}.'\system32\cmd.exe';
				print "cmd.exe: $cmd_path\n";
			} else {
				foreach my $i (split /;/, $ENV{'PATH'}){
					unless (
						   substr($i,length($i) - 1, 1) eq '\\'
						|| substr($i,length($i) - 1, 1) eq '/'
					) {
						$i .= '\\';
					}
					if (-e $i.'cmd.exe'){
						$cmd_path = $i.'cmd.exe';
						print "cmd.exe: found at $cmd_path\n";
						last;
					}
				}
			}
		}
		print "Opening $t\n";
		if (-e $cmd_path){
			require Win32::Process;
			my $cmd_process;
			Win32::Process::Create(
				$cmd_process,
				$cmd_path,
				"cmd /C start \"khcoder\" \"$t\"",
				0,
				Win32::Process->NORMAL_PRIORITY_CLASS,
				$ENV{'PWD'},
			) || die("Could not start cmd.exe\n");
		} else {
			print "Could not find cmd.exe\n";
		}

		### system関数（シンプル）
		#system("start \"khcoder\" \"$t\"");

		### system関数（古い）
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
