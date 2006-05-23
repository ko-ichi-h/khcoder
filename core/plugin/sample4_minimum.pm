# 最小限（に近い構成）プラグイン構成

package sample4_minimum;

sub plugin_config{
	return {
		name     => '最小限の構成',
		menu_grp => 'サンプル',         # この行は（本来は）省略可
	};
}

sub exec{
	print "short sample\n";             # ここに必要な処理内容を記述
}

1;
