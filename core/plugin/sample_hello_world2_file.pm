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

	#-----------------------------------#
	#   GUIで出力先のファイル名を取得   #

	my $mw = $::main_gui->mw;           # KH Coderのメイン・ウィンドウを取得

	my $path = $mw->getSaveFile(        # Tkのファイル選択ダイアログ
		-title            => gui_window->gui_jchar('メッセージの保存'),
		-initialdir       => $::config_obj->cwd,
		-defaultextension => '.txt',
		-filetypes        => [
			[ gui_window->gui_jchar("テキスト"),'.txt' ],
			["All files",'*']
		]
	);
		# gui_window->gui_jchar('文字列')で、文字コードをGUI用に変換
		# $::config_obj->cwdで、KH Coderが存在するディレクトリを選択

	return 0 unless length($path);

	#------------------------------#
	#   出力するメッセージを作成   #

	my $msg = '';
	$msg .= '分析対象ファイル：';
	$msg .= $::project_obj->file_target;
	$msg .= "\n";
	$msg .= 'メモ：';
	$msg .= $::project_obj->comment;
	$msg .= "\n";
	$msg .= '前処理：';

	if ( $::project_obj->status_morpho ){
		$msg .= '実行済み'
	} else {
		$msg .= '未実行'
	}

	$msg .= "\n\n";
	$msg .= '※KH Coderのサンプル・プラグインによるテスト出力';

	#----------------------#
	#   ファイルへの出力   #

	open (SMPLOUT,">$path") or          # ファイルをオープン
		gui_errormsg->open(             # オープン失敗時のエラー表示
			type => 'file',
			thefile => $path
		);

	print SMPLOUT $msg;                 # ファイルへ書き出し

	close (SMPLOUT);                    # ファイルのクローズ

	#--------------------#
	#   確認画面の表示   #
	
	
	return 1;
}




1;