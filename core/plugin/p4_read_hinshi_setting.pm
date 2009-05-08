package p4_read_hinshi_setting;
use strict;

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	return {
		name     => '品詞設定の読み込み',
		menu_cnf => 1,
		menu_grp => '',
	};
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{
	$::project_obj->read_hinshi_setting;
	
	gui_errormsg->open(
		msg  => '品詞設定の変更を反映するには（再度）前処理を実行して下さい。',
		type => 'msg',
		icon => 'info',
	);
}
1;
