package gui_window::contxt_out::spss;
use base qw(gui_window::contxt_out);

use strict;

#--------------#
#   ロジック   #
#--------------#

sub go{
	print "go!";
	
	my $self = shift;
	my $file = shift;
	
	mysql_contxt::spss->new(
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
		[ "spss syntax file",[qw/.sps/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.sps',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jchar('「抽出語ｘ文脈ベクトル」表：名前を付けて保存'),
		-initialdir       => $::config_obj->cwd
	);
	unless ($path){
		return 0;
	}
	return $path;
}

# Windowラベル
sub label{
	return '「抽出語ｘ文脈ベクトル」表の出力： SPSS';
}

sub win_name{
	return 'w_cross_out_spss';
}

1;
