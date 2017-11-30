package kh_sysconfig::linux::stanford;
use base qw(kh_sysconfig::linux);

sub config_morph{
	# 設定事項無し
}

sub path_check{
	my $self = shift;

	if ( ! (-e $self->stanf_tagger_path && -e $self->stanf_jar_path)){
		gui_errormsg->open(
			type   => 'msg',
			window => \$gui_sysconfig::inis,
			msg    => kh_msg->get('path_error'),
		);
		return 0;
	}
	
	return 1;
}


1;
__END__
