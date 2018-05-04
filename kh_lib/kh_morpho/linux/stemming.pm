package kh_morpho::linux::stemming;
use base qw(kh_morpho::linux);
use strict;

use kh_morpho::perl::stemming;

#-----------------------#
#   Stemmerの実行関係   #
#-----------------------#

sub _run_morpho{
	my $self = shift;	

	my $class = "kh_morpho::perl::stemming::".$::config_obj->stemming_lang;

	$class->run(
		'output' => $self->output,
		'target' => $self->target,
	);
}


sub exec_error_mes{
	return kh_msg->get('error');
}


1;
