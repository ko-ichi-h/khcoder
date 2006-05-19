package sample_hello_world2_file;  # ←この行はファイル名にあわせて変更
use strict;                        # ※ファイルの文字コードはEUCを推奨

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	my $conf= {
		name     => 'サンプル：Hello World（ファイル）', # メニューに表示される
		                                                 #                 名前
		menu_cnf => 1,                                   # メニューの設定
				# 0: いつでも実行可能
				# 1: プロジェクトが開かれてさえいれば実行可能
				# 2: プロジェクトの前処理が終わっていれば実行可能
	};
	return $conf;
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{
	print "Hello World\n";
}




1;