package gui_window::cod_out::tab;
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
		[ Jcode->new("タブ区切り")->sjis,[qw/.txt/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.txt',
		-filetypes        => \@types,
		-title            =>
			Jcode->new('コーディング結果：名前を付けて保存')->sjis,
		-initialdir       => $::config_obj->cwd
	);
	
	# 保存を実行
	if ($path){
		my $result;
		unless ( $result = kh_cod::func->read_file($self->cfile) ){
			return 0;
		}
		$result->cod_out_tab($self->tani,$path);
	}
	
	$self->close;
}

sub win_label{
	return 'コーディング結果の出力： タブ区切り';
}

sub win_name{
	return 'w_cod_save_tab';
}
1;