package p3_xls1_word_list;  # ←この行はファイル名にあわせて変更
use strict;                # ※ファイルの文字コードはEUCを推奨

#--------------------------#
#   このプラグインの設定   #

sub plugin_config{
	return {
		                                             # メニューに表示される名前
		name     => '抽出語リスト（品詞別・出現回数順・xls）',
		menu_cnf => 2,                               # メニューの設定(1)
			# 0: いつでも実行可能
			# 1: プロジェクトが開かれてさえいれば実行可能
			# 2: プロジェクトの前処理が終わっていれば実行可能
		menu_grp => '国外版Excel対応',               # メニューの設定(2)
			# メニューをグループ化したい場合にこの設定を行う。
			# 必要ない場合は「'',」または「undef,」としておけば良い。
	};
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{

	#----------------#
	#   出力の準備   #

	use Spreadsheet::WriteExcel;
	use Unicode::String qw(utf8 utf16);

	my $f    = $::project_obj->file_TempExcel;
	my $workbook  = Spreadsheet::WriteExcel->new($f);
	my $worksheet = $workbook->add_worksheet(
		utf8( Jcode->new('シート1')->utf8 )->utf16,
		1
	);

	my $font = '';
	if ($] > 5.008){
		$font = gui_window->gui_jchar('ＭＳ Ｐゴシック', 'euc');
	} else {
		$font = 'MS PGothic';
	}
	$workbook->{_formats}->[15]->set_properties(
		font       => $font,
		size       => 10,
		valign     => 'vcenter',
		align      => 'center',
	);
	my $format_n = $workbook->add_format(         # 数値
		num_format => '0',
		size       => 10,
		font       => $font,
		align      => 'right',
	);
	my $format_c = $workbook->add_format(         # 文字列
		font       => $font,
		size       => 10,
		align      => 'left',
		num_format => '@'
	);

	#----------#
	#   出力   #

	my $list = &mysql_words::_make_list;

	my $line = '';
	my $col = 0;
	foreach my $i (@{$list}){
		# 品詞名
		$worksheet->write_unicode(
			0,
			$col,
			utf8( Jcode->new($i->[0],'euc')->utf8 )->utf16,
			$format_c
		);
		# 語・出現数
		my $row = 1;
		foreach my $h (@{$i->[1]}){
			$worksheet->write_unicode(
				$row,
				$col,
				utf8( Jcode->new($h->[0],'euc')->utf8 )->utf16,
				$format_c
			);
			$worksheet->write_number(
				$row,
				$col + 1,
				$h->[1],
				$format_n
			);
			++$row;
		}
		$col += 2;
	}

	$workbook->close;
	gui_OtherWin->open($f);

	return 1;
}

1;
