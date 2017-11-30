package gui_window::sysconfig;
use base qw(gui_window);
use strict;

use gui_window::sysconfig::win32;
use gui_window::sysconfig::linux;

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	my $self = shift;
	my $class = "gui_window::sysconfig::".$::config_obj->os;
	bless $self, $class;
	
	$self = $self->__new;

	return $self;
}

sub browse_freeling{
	my $self = shift;
	
	my $path = $self->{win_obj}->chooseDirectory;

	use Encode;
	$path = Encode::decode($::config_obj->os_code, "$path");
	$path = Encode::encode($::config_obj->os_code, $path);

	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$path = $::config_obj->uni_path($path);
		$self->{entry_freeling}->delete('0','end');
		$self->{entry_freeling}->insert(0,$path);
	}
	
	return $self;
}

# .jarの参照
sub browse_stanford_jar{
	my $self  = shift;

	my @types =
		(["jar files",           [qw/.jar/]],
		["All files",		'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt( kh_msg->get('browse_stanford_jar') ),
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);
	
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		#$path = $::config_obj->os_path($path);
		$self->{entry_stan1}->delete('0','end');
		$self->{entry_stan1}->insert(0,$self->gui_jchar($path));
	}
}

# *.taggerの参照
sub browse_stanford_tag{
	my $self  = shift;

	my @types =
		(["Tagger files",           [qw/.tagger/]],
		["All files",		'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt( kh_msg->get('browse_stanford_tag') ),
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);
	
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		#$path = $::config_obj->os_path($path);
		$self->{entry_stan2}->delete('0','end');
		$self->{entry_stan2}->insert(0,$self->gui_jchar($path));
	}
}


sub win_name{
	return 'w_sysconfig';
}

1;
