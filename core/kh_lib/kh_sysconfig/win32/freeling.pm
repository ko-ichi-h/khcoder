package kh_sysconfig::win32::freeling;
use base qw(kh_sysconfig::win32);

sub config_morph{
	return 1;
}

sub path_check{
	unless ( 
		-d $::config_obj->os_path( $::config_obj->freeling_dir )
	){
		#gui_errormsg->open(
		#	type   => 'msg',
		#	window => \$gui_sysconfig::inis,
		#	msg    => kh_msg->get('path_error'),
		#);
		print "path error: freeling\n";
		return 0;
	}
	
	return 1;
}


1;
__END__
