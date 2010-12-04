package kh_morpho::win32::mecab;
# use strict;
use base qw( kh_morpho::win32 );

#--------------------#
#   茶筌の実行関係   #
#--------------------#

sub _run_morpho{
	my $self = shift;	
	my $path = $self->config->mecab_path;
	
	unless (-e $path){
		gui_errormsg->open(
			msg => '事前にKH Coderの設定（形態素解析）を行ってください',
			type => 'msg'
		);
		exit;
	}
	
	my $pos = rindex($path,"\\bin\\");
	$self->{dir} = substr($path,0,$pos);
	my $chasenrc = $self->{dir}."\\etc\\mecabrc";
	$self->{cmdline} = "mecab -Ochasen -r \"$chasenrc\" -o \"".$self->output."\" \"".$self->target."\"";

	print "morpho: $self->{cmdline}\n";

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
	return "KH Coder Error!!\nMeCabの起動に失敗しました！";
}


1;
