package kh_plugin;

sub read{
	use File::Find;
	find(\&read_each, $::config_obj->cwd.'/plugin');
	
	sub read_each{
		return if(-d $File::Find::name);
		return unless $_ =~ /.+\.pm/;
		substr($_, length($_) - 3, length($_)) = '';
		print "$_\n";
		
		unless (eval "use $_; 1"){
			my $err = $@;
			gui_errormsg->open(
				type => 'msg',
				msg  => "プラグイン「".$_.".pm」の読み込みを中止しました。\nエラー：\n$err"
			);
			print "$err\n";
			return 0;
		}
		
	}
}




1;