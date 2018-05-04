package screen_code::check_package;

use strict;
use utf8;
use File::Path;
use File::Spec;
use Encode qw/encode decode/;

my $isInstalled = 0;
my $pack1_name = File::Spec->catfile('screen', 'package', 'ggplot2_2.1.0.zip');
my $pack2_name = File::Spec->catfile('screen', 'package', 'scales_0.4.0.zip');

sub check_install{
	if ($isInstalled) {return 1};
	
	my $cmd = 'ver <- packageVersion("ggplot2")
	print(ver)';
	$::config_obj->R->send($cmd);
	my $rtn = $::config_obj->R->read();
	if ($rtn =~ /2\.[1-9]\.\d/) {
		$isInstalled = 1;
		return 1;
	} else {
		return 0;
	}
}

sub install_package{
	if (-f $pack1_name && -f $pack2_name) {
		my $cmd = 'install.packages(c("'.$pack1_name.'","'.$pack2_name.'"), repos = NULL, conrib.url="win.binary", type = "win.binary")';
		$::config_obj->R->send($cmd);
		if (&check_install) {return 1;}
	} else {
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('screen_code::assistant->package_file_not_exist'),
		);
	}
	return 0;
}

1;