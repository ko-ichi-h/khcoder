package wm_output;
use strict;

#----------------------#
#   プラグインの設定   #

sub plugin_config{
	return {
		name => '「文書ｘ抽出語（表層語）」表の出力 - 不定長CSV（WordMiner）',
		menu_cnf => 0,
		menu_grp => '入出力',
	};
}

#----------------------------------------#
#   メニュー選択時に実行されるルーチン   #

sub exec{
	gui_window::morpho_crossout::wm_output->open; # GUIを起動
}

#-----------------------------------#
#   GUI操作のためのルーチン（群）   #

# KH Coderに既に含まれているモジュール「gui_window::morpho_crossout」を利用

package gui_window::morpho_crossout::wm_output;
use base qw(gui_window::morpho_crossout);
use strict;

sub save{
	my $self = shift;

	# 品詞選択のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}

	# 保存先の参照
	my @types = (
		['CSV Files',[qw/.csv/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.txt',
		-initialdir       => $::config_obj->cwd,
		-title            =>
			$self->gui_jchar('「文書ｘ抽出語」表（表層語）：名前を付けて保存'),
		-filetypes        =>
			[
				['CSV Files', [qw/.csv/] ],
				['All files', '*'        ]
			],
	);
	return 0 unless $path;

	# 実行確認
	my $ans = $self->win_obj->messageBox(
		-message => $self->gui_jchar
			(
			   "この処理には時間がかかることがあります。\n".
			   "続行してよろしいですか？"
			),
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	return 0 unless $ans =~ /ok/i;

	# 実行
	my $w = gui_wait->start;
	mysql_crossout::var::hyoso->new(
		tani   => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		file   => $path,
	)->run;
	$w->end;

	$self->close;
}

sub label{
	return '「文書ｘ抽出語」表の出力（表層語）： 不定長CSV';
}
sub win_name{
	return 'w_morpho_crossout_wm_output';
}

#------------------------------#
#   出力処理のためのルーチン   #

# KH Coderに既に含まれているモジュール「mysql_crossout::var」を利用

package mysql_crossout::var::hyoso;
use base qw(mysql_crossout::var);
use strict;

# SQL文の準備(1)
sub sql3{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;

	my $sql;
	$sql .= "SELECT $self->{tani}.id, hyoso.name, khhinshi.id\n";
	$sql .= "FROM   hyosobun, hyoso, genkei, khhinshi, $self->{tani}\n";
	$sql .= "WHERE\n";

	# テーブルの結合
	$sql .= "	hyosobun.hyoso_id = hyoso.id\n";
	$sql .= "	AND hyoso.genkei_id = genkei.id\n";
	$sql .= "	AND genkei.khhinshi_id = khhinshi.id\n";
	my $flag = 0;
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($i eq $self->{tani}){ $flag = 1; }
		if ($flag){
			$sql .= "	AND hyosobun.$i"."_id = $self->{tani}.$i"."_id\n";
		}
	}

	# 最小・最大・「使用しない語」のチェック
	$sql .= "	AND genkei.nouse = 0\n";
	$sql .= "	AND genkei.num >= $self->{min}\n";
	if ($self->{max}){
		$sql .= "	AND genkei.num <= $self->{max}\n";
	}

	# 品詞による選択
	$sql .= "	AND (\n";
	my $n = 0;
	foreach my $i ( @{$self->{hinshi}} ){
		if ($n){
			$sql .= '		OR ';
		} else {
			$sql .= "		";
		}
		$sql .= "khhinshi.id = $i\n";
		++$n;
	}
	$sql .= "	)\n";

	# 出力範囲
	$sql .= "	AND $self->{tani}.id >= $d1\n";
	$sql .= "	AND $self->{tani}.id <  $d2\n";

	# 出力順
	$sql .= "ORDER BY hyosobun.id";

	return $sql;
}

# SQL文の準備(2)
sub sql4{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;

	my $sql;
	$sql .= "SELECT $self->{tani}.id, hyoso.name, genkei.nouse\n";
	$sql .= "FROM   hyosobun, hyoso, genkei, $self->{tani}\n";
	$sql .= "WHERE\n";

	# テーブルの結合
	$sql .= "	hyosobun.hyoso_id = hyoso.id\n";
	$sql .= "	AND hyoso.genkei_id = genkei.id\n";
	my $flag = 0;
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($i eq $self->{tani}){ $flag = 1; }
		if ($flag){
			$sql .= "	AND hyosobun.$i"."_id = $self->{tani}.$i"."_id\n";
		}
	}

	# 出力範囲
	$sql .= "	AND $self->{tani}.id >= $d1\n";
	$sql .= "	AND $self->{tani}.id <  $d2\n";

	# 出力順
	$sql .= "ORDER BY hyosobun.id";
	return $sql;
}

1;