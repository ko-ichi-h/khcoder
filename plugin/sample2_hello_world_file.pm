package sample2_hello_world_file;  # ←この行はファイル名にあわせて変更
use strict;                        # ※ファイルの文字コードはEUCを推奨

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	return {
		name     => 'Hello World - ファイル',        # メニューに表示される名前
		menu_cnf => 1,                               # メニューの設定(1)
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
	$msg .= '分析対象ファイル： ';
	$msg .= $::project_obj->file_target;
	$msg .= "\n";
	$msg .= 'メモ： ';
	$msg .= $::project_obj->comment;
	$msg .= "\n";
	$msg .= '前処理： ';

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
	
	gui_window::sample_hello_world2_file->open(
		msg  => $msg,
		path => $path,
	);
	
	return 1;
}

#------------------------------#
#   確認画面表示用のルーチン   #

package gui_window::sample_hello_world2_file; # ←この行は「gui_window::」で始
use base qw(gui_window);                      #           まる適当な名称に変更
use strict;
use Tk;

## Windowの作成
sub _new{
	# 変数の取得
	my $self = shift;
	my %args = @_;
	my $mw = $self->win_obj; # Window（Tkオブジェクト）を取得して$mwに格納

	# Windowのタイトルを設定
	$mw->title( gui_window->gui_jchar('サンプル：Hello World（ファイル）') );

	# ラベルの表示(0)
	$mw->Label(
		-text => gui_window->gui_jchar(' ※ファイルへの出力が完了しました'),
	)->pack(
		-anchor => 'w',
		-pady => 5
	);

	# ラベルの表示(1)
	$mw->Label(
		-text => gui_window->gui_jchar(' 出力ファイル： '.$args{path},'euc'),
	)->pack(-anchor => 'w');

	# ラベルの表示(2)
	$mw->Label(
		-text => gui_window->gui_jchar(' 出力内容：'),
	)->pack(
		-anchor => 'w'
	);

	# テキストフィールド（Read Only）の表示
	my $text_widget = $mw->Scrolled(
		"ROText",
		-scrollbars => 'osoe',
		-height     => 5,
		-width      => 64,
	)->pack(
		-padx   => 2,
		-fill   => 'both',
		-expand => 'yes'
	);
	$text_widget->bind("<Key>",[\&gui_jchar::check_key,Ev('K'),\$text_widget]);

	# テキストフィールドにメッセージを挿入
	$text_widget->insert(
		'end',
		gui_window->gui_jchar( $args{msg} )
	);

	# 「閉じる」ボタンの表示
	$mw->Button(
		-text    => gui_window->gui_jchar('閉じる'),
		-command => sub{ $self->close; }
	)->pack(
		-pady => 2
	)->focus;

	return $self;
}

## Windowの名称を設定
sub win_name{                 
	return 'w_sample_hello_world2_file'; # ←この行は「w_」で始まる適当な名称
}	                                     #                             に変更

1;
