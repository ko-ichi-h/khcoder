package kh_morpho::win32::chasen;
use strict;
use base qw( kh_morpho::win32 );

#--------------------#
#   茶筌の実行関係   #
#--------------------#

sub _run_morpho{
	my $self = shift;
	my $path = $::config_obj->os_path( $self->config->chasen_path );
	
	unless (-e $path){
		gui_errormsg->open(
			msg => kh_msg->get('error_config'),
			type => 'msg'
		);
		exit;
	}
	
	my $pos = rindex($path,"\\");
	my $char;
	if ($pos > -1) {
		$char = '\\';
	} else {
		$char = '/';
	}
	
	$pos = rindex($path,$char);
	$self->{dir} = substr($path,0,$pos);
	my $chasenrc = $self->{dir}.$char."dic".$char."chasenrc";
	$self->{cmdline} = "chasen -r \"$chasenrc\" -o \"".$self->output."\" \"".$self->target."\"";

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
	return kh_msg->get('error');
}


1;
