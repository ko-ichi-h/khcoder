# Rのveganパッケージに含まれるmetaMDS関数を使って多次元尺度構成法を実行する
# プラグインです。

# 共立出版の「Useful R」シリーズ第10巻『Rのパッケージおよびツールの作成と応用』
# に本プラグインの解説があります。ただしC:\khcoder以外にKH Coderをインストール
# しても問題が出ないように、書籍掲載のコードに、若干付け足しています。

# プラグインの設定
package p1_sample5_mds;
use utf8;

sub plugin_config{
	return {
		name     => '抽出語の多次元尺度構成法（metaMDS）',
		menu_grp => 'サンプル',
		menu_cnf => 2,
	};
}

# メニュー選択時に実行されるルーチン
sub exec{
	gui_window::mds->open;                        # 操作画面を開く
}

# 操作画面の準備
package gui_window::mds;
use base qw(gui_window);
my $selection;

sub _new{
	my $self = shift;
	
	$selection = gui_widget::words->open(         # 集計単位・語の選択
		parent => $self->win_obj,
		verb   => 'plot'
	);

	$self->win_obj->Button(                       # OKボタン作成
		-text => 'OK',
		-command => sub{ $self->make_mds; }
	)->pack;

	return $self;
}

sub win_name{
	return 'w_plugin_mds';                        # 画面の識別用に任意の名前を
}

# metaMDS関数を使ってMDSを実行
sub make_mds{
	my $self = shift;
	                                              # ↓フォルダ区切はスラッシュ
	my $file_r   = 'plugin_jp/mds.r';             # *.rファイルの名前
	my $file_pdf = 'mds.pdf';                     # 保存するファイルの名前

	use Cwd;                                      # ファイル名をフルパスに
	$file_r   = cwd.'/'.$file_r;
	$file_pdf = cwd.'/'.$file_pdf;

	my $r_command = mysql_crossout::r_com->new(   # データ取り出し
		$selection->params,
		rownames => 0,
	)->run;

	$r_command .= "\n";                           # Rコマンドの準備
	$file_r = $::config_obj->uni_path( $file_r );
	$r_command .= "source(\"$file_r\")";

	my $plot = kh_r_plot->new(                    # 分析の実行
	  name      => 'plugin_mds',                  # （識別用の任意の名前）
	  command_f => $r_command
	);

	$plot->save( $file_pdf );                     # PDFファイルにプロットを保存
	system("cmd /c start \"title\" \"$file_pdf\""); # 保存したPDFファイルを開く

	$self->close;                                 # 選択画面を閉じる
}

1;