package p2_io3_morpho;
use strict;

#----------------------#
#   プラグインの設定   #

sub plugin_config{
	return {
		name => '形態素解析の結果を再読み込み',
		menu_cnf => 2,
		menu_grp => '入出力',
	};
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{
	# バックアップ
	*backup_morpho = \&kh_morpho::run;
	*backup_jchar  = \&kh_jchar::to_euc;
	
	# 変更してから
	*kh_morpho::run = \&dummy;
	*kh_jchar::to_euc = \&dummy;
	
	# 実行
	$::main_gui->close_all;
	my $w = gui_wait->start;
	mysql_ready->first;
	$w->end;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;

	# バックアップから戻す
	*kh_morpho::run = \&backup_morpho;
	*kh_jchar::to_euc = \&backup_jchar;
	
	return 1;
}

sub dummy{
	return 1;
}


1;