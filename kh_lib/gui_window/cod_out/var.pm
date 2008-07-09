package gui_window::cod_out::var;
use base qw(gui_window::cod_out);

use strict;

sub _save{
	my $self = shift;
	
	unless (-e $self->cfile){
		my $win = $self->win_obj;
		gui_errormsg->open(
			msg => "コーディング・ルール・ファイルが選択されていません。",
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
			$self->gui_jt('コーディング結果：不定長CSV：名前を付けて保存'),
		-initialdir       => $self->gui_jchar($::config_obj->cwd),
	);
	
	# 保存を実行
	if ($path){
		$path = gui_window->gui_jg($path);
		$path = $::config_obj->os_path($path);
		my $result;
		unless ( $result = kh_cod::func->read_file($self->cfile) ){
			return 0;
		}
		$result->cod_out_var($self->tani,$path);
	}
	
	$self->close;
}

sub win_label{
	return 'コーディング結果の出力：不定長CSV';
}

sub win_name{
	return 'w_cod_save_csv';
}
1;