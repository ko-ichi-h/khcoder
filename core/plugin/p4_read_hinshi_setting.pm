package p4_read_hinshi_setting;
use strict;

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	return {
		name     => '品詞設定をプロジェクトに読み込む',
		menu_cnf => 1,
		menu_grp => '',
	};
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{

	my $ans = $::main_gui->mw->messageBox(
		-message => gui_window->gui_jchar
			(
				 "KH Coderの品詞設定を、現在開いているプロジェクトに読み込みます。\n\n"
				."※KH Coderの品詞設定を変更しても、この操作を行わないかぎり、\n"
				."既存のプロジェクトの品詞設定は更新されません。\n\n"
				."続行してよろしいですか？"
			),
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	return 0 unless $ans =~ /ok/i;

	$::project_obj->read_hinshi_setting;

	gui_errormsg->open(
		msg  => 
			 '現在開いているプロジェクトの品詞設定を更新しました。'
			."\n"
			.'品詞設定の変更を反映するには（再度）前処理を実行して下さい。',
		type => 'msg',
		icon => 'info',
	);
}
1;
