package gui_window::contxt_out::tab;
use base qw(gui_window::contxt_out);

use strict;

#--------------#
#   ロジック   #
#--------------#

sub go{
	print "go!";
	
	my $self = shift;
	my $file = shift;
	
	mysql_contxt::tab->new(
		tani     => $self->{tani_obj}->value,
		hinshi   => $self->hinshi,
		max      => $self->max,
		min      => $self->min,
		max_df   => $self->max_df,
		min_df   => $self->min_df,
		tani_df  => $self->tani_df,
		hinshi2  => $self->hinshi2,
		max2     => $self->max2,
		min2     => $self->min2,
		max_df2  => $self->max_df2,
		min_df2  => $self->min_df2,
		tani_df2 => $self->tani_df2,
	)->culc->save($file);
}

#-----------------#
#   保存先の参照  #

sub file_name{
	my $self = shift;
	my @types = (
		[ $self->gui_jchar("タブ区切り"),[qw/.txt/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.txt',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt('「抽出語ｘ文脈ベクトル」表：名前を付けて保存'),
		-initialdir       => $self->gui_jchar($::config_obj->cwd),
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);
	return $path;
}

# Windowラベル
sub label{
	return '「抽出語ｘ文脈ベクトル」表の出力： タブ区切り';
}

sub win_name{
	return 'w_cross_out_tab';
}

1;
