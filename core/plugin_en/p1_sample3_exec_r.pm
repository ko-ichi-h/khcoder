package p1_sample3_exec_r; # same as the file name
use strict;

#---------------------------#
#   Setting of this plugin  #

sub plugin_config{
	return {
		name     => 'Execute R Command',             # command name on the menu
		menu_grp => 'Sample',                        # group name on the menu
		menu_cnf => 0,                               # menu setting
			# 0: whenever executable
			# 1: executable if a project is opened
			# 2: executable if pre-processing of the project is complete
	};
}

#-------------#
#   command   #

sub exec{
	my $mw = $::main_gui->mw;           # main window object

	# check availability of R
	unless ( $::config_obj->R ){
		$mw->messageBox(                # message box
			-icon    => 'info',
			-type    => 'OK',
			-title   => 'KH Coder',
			-message => 'Cannot use R!',
		);
		return 0;
	}

	# execute R command
	$::config_obj->R->send('
		print(
			paste(
				memory.size(),
				memory.size(max=T),
				memory.limit(),
				sep=", "
			) 
		)
	');
	
	# read output of R
	my $t = $::config_obj->R->read();
	
	# modify the output string for print
	$t =~ s/.+"(.+)"/$1/;
	$t =~ s/, / \t/g;
	$t = "Memory consumption of R (MB):\n\ncurrent	max	limit\n".$t;
	
	# print
	$mw->messageBox(
		-icon    => 'info',
		-type    => 'OK',
		-title   => 'KH Coder',
		-message => $t,
	);
	
	return 1;
}


1;
