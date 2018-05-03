package gui_window::cod_out::csv;
use base qw(gui_window::cod_out);

use strict;

sub _save{
	my $self = shift;
	
	unless (-e $self->cfile){
		my $win = $self->win_obj;
		gui_errormsg->open(
			msg => kh_msg->get('gui_window::cod_count->error_cod_f'), #"コーディングルール・ファイルが選択されていません。",
			window => \$win,
			type => 'msg',
		);
		return;
	}
	
	# 保存先の参照
	my @types = (
		[ "csv file",[qw/.csv/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.csv',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('save_as')), # コーディング結果（CSV）：名前を付けて保存
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);
	
	# 保存を実行
	if ($path){
		$path = gui_window->gui_jg_filename_win98($path);
		$path = gui_window->gui_jg($path);
		$path = $::config_obj->os_path($path);
		my $result;
		unless ( $result = kh_cod::func->read_file($self->cfile) ){
			return 0;
		}
		$result->cod_out_csv($self->tani,$path);
	}
	
	$self->close;
}

sub win_label{
	return kh_msg->get('win_title'); # コーディング結果の出力：CSVファイル
}

sub win_name{
	return 'w_cod_save_csv';
}
1;