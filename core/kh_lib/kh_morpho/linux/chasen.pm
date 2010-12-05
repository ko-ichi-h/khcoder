package kh_morpho::linux::chasen;
use strict;
use base qw( kh_morpho::linux );

#--------------------#
#   茶筌の実行関係   #
#--------------------#

sub _run_morpho{
	my $self = shift;

	unless (-e $::config_obj->chasenrc_path){
		my $msg = "事前にKH Coderの設定を行ってください";

		gui_errormsg->open(
			msg => $msg,
			type => 'msg'
		);
		exit;
	}

	my $cmdline = "chasen -r ".$::config_obj->chasenrc_path." -o ".$self->output." ".$self->target;
	#print "$cmdline\n";
	system "$cmdline";

	return(1);
}

sub exec_error_mes{
	return "KH Coder Error!!\n茶筌の起動に失敗しました！";
}


1;
