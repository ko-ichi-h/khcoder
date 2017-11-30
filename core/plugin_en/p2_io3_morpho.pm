package p2_io3_morpho;
use strict;

#----------------------#
#   Plug-in settings   #

sub plugin_config{
	return {
		name => 'Reload the result of POS Tagging',
		menu_cnf => 2,
	};
}

#------------------#
#   Main routine   #

sub exec{
	# Make backups
	*backup_morpho = \&kh_morpho::run;
	*backup_jchar  = \&kh_jchar::to_euc;
	
	# Change
	*kh_morpho::run = \&dummy;
	*kh_jchar::to_euc = \&dummy;
	
	# Exec
	$::main_gui->close_all;
	my $w = gui_wait->start;
	mysql_ready->first;
	$w->end;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;

	# Undo changes
	*kh_morpho::run = \&backup_morpho;
	*kh_jchar::to_euc = \&backup_jchar;
	
	return 1;
}

sub dummy{
	return 1;
}


1;