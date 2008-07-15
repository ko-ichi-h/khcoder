package gui_window::outvar_read::csv;
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
		[ $self->gui_jchar("CSVファイル"),[qw/.csv/] ],
		["All files",'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt('外部変数ファイルを選択してください'),
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);
	
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$self->{entry}->delete(0, 'end');
		$self->{entry}->insert('0',$self->gui_jchar("$path"));
	}
}

#--------------#
#   読み込み   #
#--------------#

sub __read{
	my $self = shift;
	
	print "csv: ", $self->gui_jg( $self->{entry}->get ), "\n";
	
	return mysql_outvar::read::csv->new(
		file => $self->gui_jg( $self->{entry}->get ),
		tani => $self->{tani_obj}->tani,
	)->read;
}

#--------------#
#   アクセサ   #
#--------------#

sub file_label{
	my $self = shift;
	$self->gui_jchar('CSVファイル');
}

sub win_title{
	my $self = shift;
	return $self->gui_jt('外部変数の読み込み： CSVファイル');
}

sub win_name{
	return 'w_outvar_read_csv';
}

1;