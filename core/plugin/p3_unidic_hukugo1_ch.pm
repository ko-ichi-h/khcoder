package p3_unidic_hukugo1_ch;  # ←この行はファイル名にあわせて変更
use strict;                    # ※ファイルの文字コードはEUCを推奨

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	return {
		                                             # メニューに表示される名前
		name     => '茶筌による連結',
		menu_cnf => 2,                               # メニューの設定(1)
			# 0: いつでも実行可能
			# 1: プロジェクトが開かれてさえいれば実行可能
			# 2: プロジェクトの前処理が終わっていれば実行可能
		menu_grp => '複合語の検出（UniDic）',        # メニューの設定(2)
			# メニューをグループ化したい場合にこの設定を行う。
			# 必要ない場合は「'',」または「undef,」としておけば良い。
	};
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{
	my $self = shift;
	my $mw = $::main_gui->{win_obj};

	my $if_exec = 1;
	if (
		   ( -e $::project_obj->file_HukugoList )
		&& ( mysql_exec->table_exists('hukugo') )
	){
		my $t0 = (stat $::project_obj->file_target)[9];
		my $t1 = (stat $::project_obj->file_HukugoList)[9];
		#print "$t0\n$t1\n";
		if ($t0 < $t1){
			$if_exec = 0; # この場合だけ解析しない
		}
	}

	if ($if_exec){
		my $ans = $mw->messageBox(
			-message => gui_window->gui_jchar
				(
				   "時間のかかる処理を実行しようとしています。"
				   ."（前処理よりは短時間で終了します）\n".
				   "続行してよろしいですか？"
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }

		my $w = gui_wait->start;

		my $t = '';
		$t .= '(連結品詞'."\n";
		$t .= "\t".'((複合名詞)'."\n";
		$t .= "\t\t".'(名詞)'."\n";
		$t .= "\t\t".'(接頭辞)'."\n";
		$t .= "\t\t".'(接尾辞 名詞的)'."\n";
		$t .= "\t\t".'(記号 一般)'."\n";
		$t .= "\t\t".'(補助記号 一般)'."\n";
		$t .= "\t".')'."\n";
		$t .= ')'."\n";
		$::config_obj->hukugo_chasenrc($t);
		
		use mysql_hukugo;
		mysql_hukugo->run_from_morpho;
		
		$::config_obj->hukugo_chasenrc('');
		
		print Jcode->new( $::config_obj->hukugo_chasenrc )->sjis;
		
		$w->end;
	}

	gui_window::hukugo->open;


	return 1;
}

1;
