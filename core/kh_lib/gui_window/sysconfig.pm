package gui_window::sysconfig;
use base qw(gui_window);
use strict;

use gui_window::sysconfig::win32;
use gui_window::sysconfig::linux;

#------------------#
#   Window¤ò³«¤¯   #
#------------------#

sub _new{
	my $self = shift;
	my $class = "gui_window::sysconfig::".$::config_obj->os;
	bless $self, $class;
	
	$self = $self->__new;

	return $self;
}

sub win_name{
	return 'w_sysconfig';
}

1;
