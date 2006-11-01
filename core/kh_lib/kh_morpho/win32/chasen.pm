package kh_morpho::win32::chasen;
# use strict;
use base qw( kh_morpho::win32 );

#--------------------#
#   茶筌の実行関係   #
#--------------------#

sub _run_morpho{
	my $self = shift;	
	my $path = $self->config->chasen_path;
	my $cmdline = "chasen -o \"".$self->output."\" \"".$self->target."\"";
	my $pos = rindex($path,"\\");
	my $dir = substr($path,0,$pos);
	#print "$cmdline\n";
	
	use Win32;
	use Win32::Process;
	my $ChasenObj;
	Win32::Process::Create(
		$ChasenObj,
		$path,
		$cmdline,
		0,
		CREATE_NO_WINDOW,
		$dir,
	) || $self->Exec_Error("Wi32::Process can not start");
	$ChasenObj->Wait(INFINITE)
		|| $self->Exec_Error("Wi32::Process can not wait");
	
	return(1);
}

sub exec_error_mes{
	return "KH Coder Error!!\n茶筌の起動に失敗しました！";
}


1;
