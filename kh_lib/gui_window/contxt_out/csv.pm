package gui_window::contxt_out::csv;
use base qw(gui_window::contxt_out);

use strict;

#--------------#
#   ロジック   #
#--------------#

sub go{
	print "go!";
	
	my $self = shift;
	my $file = shift;
	
	mysql_contxt->new(
		tani    => $self->{tani_obj}->value,
		hinshi2 => $self->hinshi2,
		max2    => $self->max2,
		min2    => $self->min2,
		hinshi  => $self->hinshi,
		max     => $self->max,
		min     => $self->min,
	)->culc->save($file);
	
}

#-----------------#
#   保存先の参照  #

sub file_name{
	my $self = shift;
	my @types = (
		[ "csv file",[qw/.csv/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.csv',
		-filetypes        => \@types,
		-title            =>
			Jcode->new('「抽出語ｘ文脈ベクトル」表：名前を付けて保存')->sjis,
		-initialdir       => $::config_obj->cwd
	);
	unless ($path){
		return 0;
	}
	return $path;
}

# Windowラベル
sub label{
	return '「抽出語ｘ文脈ベクトル」表の出力： CSV';
}

sub win_name{
	return 'w_cross_out_csv';
}

1;
