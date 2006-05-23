package sample_sql;                # ←この行はファイル名にあわせて変更
use strict;                        # ※ファイルの文字コードはEUCを推奨

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	my $conf= {
		name     => 'サンプル - SQL文の実行',      # メニューに表示される名前
		menu_cnf => 2,                            # メニューの設定
				# 0: いつでも実行可能
				# 1: プロジェクトが開かれてさえいれば実行可能
				# 2: プロジェクトの前処理が終わっていれば実行可能
	};
	return $conf;
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{

	#-------------------------#
	#   実行するSQL文を準備   #
	
	# 頻出語（名詞）
	my $sql1 .= "
		SELECT genkei.name, genkei.num
		FROM genkei, khhinshi
		WHERE
		  genkei.khhinshi_id = khhinshi.id
		  AND khhinshi.name = '名詞'
		ORDER BY genkei.num DESC
		LIMIT 10
	";

	# 頻出した品詞（KH Coder）
	my $sql2 = "
		SELECT khhinshi.name, count(*) as kotonari, sum(genkei.num) as sousu
		FROM khhinshi, genkei
		WHERE
		  genkei.khhinshi_id = khhinshi.id
		GROUP BY khhinshi.id
		ORDER BY kotonari DESC
		LIMIT 10
	";

	# 頻出した品詞（茶筌）
	my $sql3 = "
		SELECT hinshi.name, count(*) as kotonari, sum(genkei.num) as sousu
		FROM hinshi, genkei
		WHERE
		  genkei.hinshi_id = hinshi.id
		GROUP BY hinshi.id
		ORDER BY kotonari DESC
		LIMIT 10
	";

	#-----------------#
	#   SQL文の実行   #

	my ($result1, $result2, $result3);

	my $h = mysql_exec->select($sql1)->hundle;
	while (my $i = $h->fetch){
		$result1 .= "\t$i->[0] ($i->[1])\n";
	}

	$h = mysql_exec->select($sql2)->hundle;
	while (my $i = $h->fetch){
		$result2 .= "\t$i->[0] ($i->[1], $i->[2])\n";
	}

	$h = mysql_exec->select($sql3)->hundle;
	while (my $i = $h->fetch){
		$result3 .= "\t$i->[0] ($i->[1], $i->[2])\n";
	}

		# $h = mysql_exec->select("SQL文")->hundle; で、SQL文を実行。
		# $i = $h->fetch; で、一行づつ結果を取得。


	#------------------------------#
	#   表示するメッセージを作成   #

	chop $sql1; chop $sql1; substr($sql1,0,1) = '';
	chop $sql2; chop $sql2; substr($sql2,0,1) = '';
	chop $sql3; chop $sql3; substr($sql3,0,1) = '';

	my $msg;
	
	$msg .= "※テーブル名・カラム名については、マニュアルの4.1節をご覧下さい。\n\n";
	$msg .= "■頻出した名詞トップ10\n";
	$msg .= "□SQL文\n$sql1\n";
	$msg .= "□結果 / カッコ内は出現数\n$result1\n";
	$msg .= "■頻出した品詞トップ10（KH Coderの品詞分類で、異なり語数の順）\n";
	$msg .= "□SQL文\n$sql2\n";
	$msg .= "□結果 / カッコ内は異なり語数（種類数）と総出現数\n$result2\n";
	$msg .= "■頻出した品詞トップ10（茶筌の品詞分類で、異なり語数の順）\n";
	$msg .= "□SQL文\n$sql3\n";
	$msg .= "□結果 / カッコ内は異なり語数（種類数）と総出現数\n$result3\n";

	$msg =~ s/\t\t/\t/g;

	#--------------------#
	#   確認画面の表示   #

	gui_window::sample_sql->open(
		msg  => $msg
	);
	return 1;
}

#------------------------------#
#   確認画面表示用のルーチン   #

package gui_window::sample_sql;               # ←この行は「gui_window::」で始
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
	$mw->title( gui_window->gui_jchar('実行したSQL文とその結果') );

	# ラベルの表示(0)
	$mw->Label(
		-text => gui_window->gui_jchar(' 以下のSQL文を実行しました：'),
	)->pack(
		-anchor => 'w',
		-pady => 5
	);

	# テキストフィールド（Read Only）の表示
	my $text_widget = $mw->Scrolled(
		"ROText",
		-scrollbars => 'osoe',
		-height     => 20,
		-width      => 46,
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
	return 'w_sample_sql';               # ←この行は「w_」で始まる適当な名称
}	                                     #                             に変更

1;
