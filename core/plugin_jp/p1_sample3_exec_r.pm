package p1_sample3_exec_r;            # ←この行はファイル名にあわせて変更
use strict;                           # ※ファイルの文字コードはEUCを推奨

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	return {
		name     => 'Rコマンドの実行',               # メニューに表示される名前
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
	my $mw = $::main_gui->mw;           # KH Coderのメイン・ウィンドウ

	# Rが使えるかどうか確認
	unless ( $::config_obj->R ){
		$mw->messageBox(                # Tkのメッセージボックスを表示
			-icon    => 'info',
			-type    => 'OK',
			-title   => 'KH Coder',
			-message => 'Cannot use R!',
		);
		return 0;
	}

	# Rコマンドの実行
	$::config_obj->R->send('
		print(
			paste(
				memory.size(),
				memory.size(max=T),
				memory.limit(),
				sep=", "
			) 
		)
	');
	
	# 実行結果の取得
	my $t = $::config_obj->R->read();
	
	# 結果を少し整形
	$t =~ s/.+"(.+)"/$1/;
	$t =~ s/, / \t/g;
	$t = "Memory consumption of R (MB):\n\ncurrent	max	limit\n".$t;

	# Rコマンドの実行
	$::config_obj->R->send('
		print( Sys.getlocale() )
	');

	# 実行結果の取得
	my $t1 = $::config_obj->R->read();

	# 結果を少し整形
	$t1 =~ s/\[[0-9+]\]//;
	$t1 =~ s/^\s//;
	$t1 =~ s/;/\n/g;
	$t1 =~ s/=/ =\t/g;
	$t1 =~ s/"//g;
	$t .= "\n\n$t1";

	# 画面表示
	$mw->messageBox(
		-icon    => 'info',
		-type    => 'OK',
		-title   => 'KH Coder',
		-message => $t,
	);
	
	return 1;
}


1;
