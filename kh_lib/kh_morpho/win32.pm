package kh_morpho::win32;
use base qw(kh_morpho);
use strict;

use kh_morpho::win32::mecab;
use kh_morpho::win32::chasen;

sub _run{
	my $self = shift;

	bless $self, 'kh_morpho::win32::'.$::config_obj->c_or_j;
	$self->_run_morpho;

	if (! -e $self->output){
		$self->Exec_Error("No output file.");
	} elsif (-z $self->output){
		$self->Exec_Error("Blank output file.");
	}

	return(1);
}

sub Exec_Error{
	my $self = shift;
	my $error_status = shift;

	my $msg = $self->exec_error_mes;
#	$msg = Jcode->new($msg,'euc')->sjis;
	open (EOUT,'>error_log.txt') or
		gui_errormsg->open(
			type    => 'file',
			thefile => '>error_log.txt'
		);
	print EOUT "$msg\n\n";
	print EOUT "status: $error_status\n";
	print EOUT "target: ".$self->target."\n";
	print EOUT "output: ".$self->output."\n";
	print EOUT "path: ".$self->config->chasen_path."\n";
	print EOUT "dir: $self->{dir}\n";
	print EOUT "cmd: $self->{cmdline}\n";
	
	if (-d $self->t_obj->dir_CoderData){
		print EOUT "datadir: ready\n";
	} else {
		print EOUT "datadir: not ready\n";
	}

	close (EOUT);
	gui_errormsg->open(
		msg => $msg,
		type => 'msg'
	);
	exit;
}


1;
