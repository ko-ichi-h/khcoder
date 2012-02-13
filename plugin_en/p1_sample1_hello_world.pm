package p1_sample1_hello_world; # same as the file name
use strict;

#---------------------------#
#   Setting of this plugin  #

sub plugin_config{
	return {
		name     => 'Hello World',                   # command name on the menu
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
	# print to console
	print "Hello World! This is a plugin of KH Coder\n";
	
	# print to Perl/Tk message box
	my $mw = $::main_gui->mw;           # main window object

	$mw->messageBox(                    # the message box
		-icon    => 'info',
		-type    => 'OK',
		-title   => 'KH Coder',
		-message => 'Hello World! This is a plugin of KH Coder.',
	);

	return 1;
}

1;