package p1_sample3_exec_r;            # ←この行はファイル名にあわせて変更
use strict;
use utf8;

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

	my $t = '';
	
	if ($::config_obj->os eq 'win32') {
		# Rコマンドの実行 1
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
		
		# 実行結果の取得 1
		$t = $::config_obj->R->read();
		
		# 結果を少し整形 1
		$t =~ s/.+"(.+)"/$1/;
		$t =~ s/, / \t/g;
		$t = "Memory consumption of R (MB):\n\ncurrent	max	limit\n".$t;
	}

	# Rコマンドの実行 2
	$::config_obj->R->send('
		print( sessionInfo() )
	');

	# 実行結果の取得 2
	my $t2 = $::config_obj->R->read();
	$t .= "\n\nsessionInfo():\n\n$t2";

	# Rコマンドの実行 3
	$::config_obj->R->send('
		print( getwd() )
	');

	# 実行結果の取得 3
	use Encode;
	use Encode::Locale;
	my $t3 = $::config_obj->R->read();
	$t3 = Encode::decode('console_out', $t3);
	$t .= "\n\ngetwd():\n\n$t3";

	# Rコマンドの実行 4
	$::config_obj->R->send('
		print( .libPaths() )
	');

	# 実行結果の取得 4
	my $t4 = $::config_obj->R->read();
	$t4 = Encode::decode('console_out', $t4);
	$t .= "\n\n.libPaths():\n\n$t4";

	# Rコマンドの実行 5
	$::config_obj->R->send('
		print( tempdir() )
	');

	# 実行結果の取得 5
	my $t5 = $::config_obj->R->read();
	$t5 = Encode::decode('console_out', $t5);
	$t .= "\n\ntempdir():\n\n$t5";

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
