package sample1_hello_world_scr;   # ←この行はファイル名にあわせて変更
use strict;                        # ※ファイルの文字コードはEUCを推奨

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	return {
		name     => 'Hello World - 画面',            # メニューに表示される名前
		menu_cnf => 0,                               # メニューの設定(1)
			# 0: いつでも実行可能
			# 1: プロジェクトが開かれてさえいれば実行可能
			# 2: プロジェクトの前処理が終わっていれば実行可能
		menu_grp => 'サンプル',                      # メニューの設定(2)
			# メニューをグループ化したい場合にこの設定を行う。
			# 必要ない場合は「'',」または「undef,」としておけば良い。
	};
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{
	# コマンドプロンプトに表示
	print "Hello World!\n";
	
	# GUIでも表示（Perl/Tkを使用）
	my $mw = $::main_gui->mw;           # KH Coderのメイン・ウィンドウを取得

	$mw->messageBox(                    # Tkのメッセージボックスを表示
		-icon    => 'info',
		-type    => 'OK',
		-title   => 'KH Coder',
		-message => gui_window->gui_jchar('Hello World! / こんにちは世界！'),
		                                # gui_window->gui_jchar('文字列')で、
		                                # 文字コードをGUI用に変換
	);

		# Perl/Tkについては、こちらのページが大変参考になる
		# http://www.geocities.jp/m_hiroi/perl_tk/index.html

	return 1;
}

1;