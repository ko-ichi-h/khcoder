package kh_plugin;

sub read{
	use File::Find;
	find(\&read_each, $::config_obj->cwd.'/plugin');
	
	sub read_each{
		return if(-d $File::Find::name);
		return unless $_ =~ /.+\.pm/;
		substr($_, length($_) - 3, length($_)) = '';
		print "$_\n";
	}
}




1;