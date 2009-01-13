package kh_morpho::win32::chasen;
# use strict;
use base qw( kh_morpho::win32 );

#--------------------#
#   茶筌の実行関係   #
#--------------------#

sub _run_morpho{
	my $self = shift;	
	my $path = $self->config->chasen_path;
	
	my $pos = rindex($path,"\\");
	$self->{dir} = substr($path,0,$pos);
	my $chasenrc = $self->{dir}."\\dic\\chasenrc";
	$self->{cmdline} = "chasen -r \"$chasenrc\" -o \"".$self->output."\" -j \"".$self->target."\"";

	require Win32::Process;
	# Win32::Process->import; # これではうまくいかない？

	my $ChasenObj;
	Win32::Process::Create(
		$ChasenObj,
		$path,
		$self->{cmdline},
		0,
		Win32::Process->CREATE_NO_WINDOW,
		$self->{dir},
	) || $self->Exec_Error("Wi32::Process can not start");
	$ChasenObj->Wait( Win32::Process->INFINITE )
		|| $self->Exec_Error("Wi32::Process can not wait");
	
	return(1);
}

sub exec_error_mes{
	return "KH Coder Error!!\n茶筌の起動に失敗しました！";
}


1;
