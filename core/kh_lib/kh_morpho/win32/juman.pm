package kh_morpho::win32::juman;
use strict;
use base qw(kh_morpho::win32);

#---------------------#
#   JUMANの実行関係   #
#---------------------#

sub _run_morpho{
	my $self = shift;
	my $cmd;
	require Win32;
	if ( Win32::IsWinNT() ){
		$cmd = $ENV{'WINDIR'};
		$cmd .= '\system32\cmd.exe';
	} else {
		$cmd = $ENV{WINDIR};
		$cmd .= '\command.com';
	}

	my $cudir     = $main::config_obj->cwd;
	my $run_juman = "$cudir".'\run_juman.exe';
	
	# ダブルクォートで括る
	my $juman  = '"'.$self->config->juman_path.'"';
	my $target = '"'.$self->target.'"';
	my $output = '"'.$self->output.'"';
	my $dir    = '"'.$main::config_obj->cwd.'"';
	$cmd       = '"'."$cmd".'"';

	my $cmdline = "run_juman $juman $target $output $dir $cmd";
#	print "$run_juman\n";
#	print "$cmdline\n";

	require Win32::Process;
	my $ChasenObj;
	Win32::Process::Create(
		$ChasenObj,
		$run_juman,
		$cmdline,
		0,
		Win32::Process->NORMAL_PRIORITY_CLASS,
		$cudir,
	) || $self->Exec_Error("Wi32::Process can not start");
	$ChasenObj->Wait(Win32::Process->INFINITE)
		|| $self->Exec_Error("Wi32::Process can not wait");

	return(1);
}
sub exec_error_mes{
	return "KH Coder Error!!\nJUMANの起動に失敗しました！";
}


1;
