package kh_morpho;
use kh_morpho::win32;
use kh_morpho::linux;
use kh_project;
use kh_sysconfig;
use kh_dictio;
use strict;

#--------------------#
#   形態素解析実行   #
#--------------------#

sub run{
	my $class = shift;
	$class .= '::'.$::config_obj->os;
	my %args = @_;
	my $self = {
		t_obj  => $::project_obj,
		target => $::config_obj->os_path( $::project_obj->file_MorphoIn ),
		output => $::config_obj->os_path( $::project_obj->file_MorphoOut ),
		config => $::config_obj,
	};
	bless $self, $class;

	if (-s $self->target == 0 ) {
		gui_errormsg->open(
			msg  => kh_msg->get('error_empty'), # Error: the target file is empty.
			type => 'msg'
		);
		return 0;
	}

	$self->_run;

	return(1);
}


sub target{
	my $self = shift;
	return($self->{target});
}

sub output{
	my $self = shift;
	return($self->{output});
}

sub t_obj{
	my $self = shift;
	return($self->{t_obj});
}

sub config{
	my $self = shift;
	return($self->{config});
}

1;