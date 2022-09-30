package screen_code::plugin_path;
use strict;

use File::Path;
use File::Spec;
use Encode qw/encode decode/;

my $rde_name = File::Spec->catfile('screen', 'MonkinCleanser', 'MonkinCleanser.exe');
my $assistant_name = File::Spec->catfile('screen', 'MonkinReport', 'MonkinReport.exe');
my $negationchecker_name = File::Spec->catfile('screen', 'MonkinNegationChecker', 'MonkinNegationChecker.exe');
my $synonym_name = File::Spec->catfile('screen', 'MonkinSynonym', 'MonkinSynonym.exe');
my $KWIC_main_name = File::Spec->catfile('screen', 'MonkinKWIC', 'MonkinKWIC.exe');
my $KWIC_sub_name = File::Spec->catfile('screen', 'MonkinKWIC', 'MonkinSendClient.exe');
my $KWIC_pl_name = File::Spec->catfile('screen', 'MonkinKWIC', 'do_plugin.bat');
my $WC_name = File::Spec->catfile('screen', 'MonkinWordCloud', 'MonkinWordCloud.exe');
my $batch_name = File::Spec->catfile('screen', 'MonkinBatch', 'MonkinBatch.exe');
my $batch_HTML_name = File::Spec->catfile('screen', 'MonkinBatch');
my $batch_dummy_name = File::Spec->catfile('screen', 'MonkinBatch', 'dummy.png');
my $batch_js_name = File::Spec->catfile('screen', 'MonkinBatch', 'js');
my $inifile_name = File::Spec->catfile('screen', 'plugin.ini');

sub rde_path{
	return encoding($rde_name);
}

sub assistant_path{
	return encoding($assistant_name);
}


sub negationchecker_path{
	return encoding($negationchecker_name);
}

sub synonym_path{
	return encoding($synonym_name);
}

sub KWIC_main_path{
	return encoding($KWIC_main_name);
}

sub KWIC_sub_path{
	return encoding($KWIC_sub_name);
}

sub KWIC_pl_path{
	return encoding($KWIC_pl_name);
}

sub WC_path{
	return encoding($WC_name);
}

sub batch_path{
	return encoding($batch_name);
}
sub batch_HTML_path{
	return encoding($batch_HTML_name);
}

sub batch_dummy_path{
	return encoding($batch_dummy_name);
}

sub batch_js_path{
	return encoding($batch_js_name);
}

#System関数に渡す時にOSによって文字コードを変える必要がある
sub encoding{
	my $plugin_name = shift;
	my $encode;
	if ($::config_obj->os eq 'win32') {
		$encode = 'cp932';
	} else {
		$encode = 'utf8';
	}
	return encode($encode, $plugin_name);
}

#オプションファイルを出力するフォルダのパス=プラグインのパス
sub assistant_option_folder{
	return $::config_obj->cwd."/screen/temp/";
}

sub read_inifile{
	my $item = shift;
	my $default = shift;
	my $ret = $default;
	
	my $INI;
	if (-f $inifile_name) {
		open($INI, "<:encoding(utf8)", $inifile_name);
		while (my $line = <$INI>) {
			my @splited = split(/\t/, $line);
			my $temp = $splited[1];
			chomp($temp);
			if ($splited[0] eq $item) {
				$ret = $temp;
				last;
			}
		}
		close($INI);
	}
	
	return $ret;
}

sub save_inifile{
	my $item = shift;
	my $para = shift;
	
	my $INI;
	my @ini_data;
	if (-f $inifile_name) {
		open($INI, "<:encoding(utf8)", $inifile_name);
		while (my $line = <$INI>) {
			my @splited = split(/\t/, $line);
			if ($splited[0] ne $item) {
				push @ini_data, $line;
			}
		}
		close($INI);
	}
	
	open($INI, ">:encoding(utf8)", $inifile_name);
	foreach my $line (@ini_data) {
		print $INI $line;
	}
	print $INI "$item\t$para\n";
	close($INI);
}

1;