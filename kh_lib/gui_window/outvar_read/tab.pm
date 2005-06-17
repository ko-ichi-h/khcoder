package gui_window::outvar_read::tab;
use base qw(gui_window::outvar_read);
use strict;
use Jcode;

use mysql_outvar::read;

#------------------#
#   ファイル参照   #
#------------------#

sub file{
	my $self = shift;

	my @types = (
		[ $self->gui_jchar("タブ区切りファイル"),[qw/.dat .txt/] ],
		["All files",'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jchar('外部変数ファイルを選択してください'),
		-initialdir => $::config_obj->cwd
	);
	
	if ($path){
		$self->{entry}->delete(0, 'end');
		$self->{entry}->insert('0',$self->gui_jchar("$path"));
	}
}

#--------------#
#   読み込み   #
#--------------#

sub __read{
	my $self = shift;

	return mysql_outvar::read::tab->new(
		file => $self->{entry}->get,
		tani => $self->{tani_obj}->tani,
	)->read;
}

#--------------#
#   アクセサ   #
#--------------#

sub file_label{
	my $self = shift;
	return $self->gui_jchar('タブ区切りファイル');
}

sub win_title{
	my $self = shift;
	return $self->gui_jchar('外部変数の読み込み： タブ区切り');
}

sub win_name{
	return 'w_outvar_read_tab';
}

1;