package kh_morpho::win32::stemming;
use base qw(kh_morpho::win32);
use strict;

use kh_morpho::perl::stemming;

#-----------------------#
#   Stemmerの実行関係   #
#-----------------------#

sub _run_morpho{
	my $self = shift;	

	my $class = "kh_morpho::perl::stemming::".$::project_obj->morpho_analyzer_lang;

	$class->run(
		'output' => $self->output,
		'target' => $self->target,
	);
}


sub exec_error_mes{
	return kh_msg->get('error');
	#return "KH Coder Error!!\nStemmerによる処理に失敗しました。";
}


1;
