package gui_window::main::menu::underline;
use strict;

sub conv{
	my $num = shift;
	if ($::config_obj->os eq 'linux'){
		$num = ( ($num - 1) / 2 ) + 1;
	}
	return $num;
}


1;
