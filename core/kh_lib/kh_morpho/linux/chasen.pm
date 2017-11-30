package kh_morpho::linux::chasen;
use strict;
use base qw( kh_morpho::linux );

#--------------------#
#   Ããä¥¤Î¼Â¹Ô´Ø·¸   #
#--------------------#

sub _run_morpho{
	my $self = shift;

	unless (-e $::config_obj->chasenrc_path){
		gui_errormsg->open(
			msg  => kh_msg->get('error_confg'),
			type => 'msg'
		);
		exit;
	}

	#print "ENV: $::ENV{DYLD_FALLBACK_LIBRARY_PATH}\n\n";
	#system "printenv";
	#print "\n\n";
	
	my $chasen_exe = 'chasen';
	if ($::config_obj->all_in_one_pack) {
		$chasen_exe = './deps/chasen/bin/chasen';
	}

	my $cmdline = "$chasen_exe -r \"".$::config_obj->chasenrc_path.'" -o "'.$self->output.'" "'.$self->target.'"';
	
	if ($::config_obj->all_in_one_pack){
		$cmdline = "DYLD_FALLBACK_LIBRARY_PATH=\"$::ENV{DYLD_FALLBACK_LIBRARY_PATH}\" $cmdline";
	}
	
	print "command line: $cmdline\n";

	system "$cmdline";

	return(1);
}

sub exec_error_mes{
	return kh_msg->get('error');
}


1;
