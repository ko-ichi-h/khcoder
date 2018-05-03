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

	my $t = '';
	
	if ($::config_obj->os eq 'win32') {
		# execute R command 1
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
		
		# read output of R 1
		my $t = $::config_obj->R->read();
		
		# modify the output string for print
		$t =~ s/.+"(.+)"/$1/;
		$t =~ s/, / \t/g;
		$t = "Memory consumption of R (MB):\n\ncurrent	max	limit\n".$t;
	}

	# execute R command 2
	$::config_obj->R->send('
		print( sessionInfo() )
	');

	# read output of R 2
	my $t2 = $::config_obj->R->read();
	$t .= "\n\nsessionInfo():\n\n$t2";

	# execute R command 3
	$::config_obj->R->send('
		print( getwd() )
	');

	#  read output of R 3
	use Encode;
	use Encode::Locale;
	my $t3 = $::config_obj->R->read();
	$t3 = Encode::decode('console_out', $t3);
	$t .= "\n\ngetwd():\n\n$t3";

	# execute R command 4
	$::config_obj->R->send('
		print( .libPaths() )
	');

	# read output of R 4
	my $t4 = $::config_obj->R->read();
	$t4 = Encode::decode('console_out', $t4);
	$t .= "\n\n.libPaths():\n\n$t4";

	# execute R command 5
	$::config_obj->R->send('
		print( tempdir() )
	');

	# read output of R 5
	my $t5 = $::config_obj->R->read();
	$t5 = Encode::decode('console_out', $t5);
	$t .= "\n\ntempdir():\n\n$t5";

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
