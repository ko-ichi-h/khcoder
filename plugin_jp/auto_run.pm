# コマンドラインから「kh_coder.exe -auto_run ファイル名」のように起動すると、
# 指定されたファイルをもとに共起ネットワークを作成するプラグイン。ただし指定
# したファイルがすでにプロジェクトとして登録されていると、実行に失敗する。

# 共立出版の「Useful R」シリーズ第10巻『Rのパッケージおよびツールの作成と応用』
# に本プラグインの解説があります。

# プラグインの設定
package auto_run;

sub plugin_config{

	# 自動処理を行うかどうか判断
	if ( $ARGV[0] eq '-auto_run' && -e $ARGV[1] ){
		
		# ファイル名指定
		my $file_target = $ARGV[1];
		my $file_save   = 'C:\khcoder\net.png';

		# プロジェクト新規作成
		my $new = kh_project->new(
		    target => $file_target,
		    comment => 'auto',
		) or die("could not create a project\n");
		kh_projects->read->add_new($new) or die("could not save the project\n");

		# 新規作成したプロジェクトを開く
		$new->open or die("could not open the project\n");

		# 前処理実行
		my $wait_window = gui_wait->start;
		&gui_window::main::menu::mc_morpho_exec;
		$wait_window->end(no_dialog => 1);

		# 共起ネットワーク作成
		my $win = gui_window::word_netgraph->open;
		$win->{net_obj}->{entry_edges_number}->delete('0','end'); # 描画数を120に
		$win->{net_obj}->{entry_edges_number}->insert('end','120');
		$win->{net_obj}->{check_use_freq_as_size} = 1; # 出現数が多いほど大きく
		$win->calc;

		# 共起ネットワーク保存
		my $win_result = $::main_gui->get('w_word_netgraph_plot');
		$win_result->{plots}[5]->save($file_save); # 6つ目のプロットを保存

		# プロジェクトを閉じる
		$::main_gui->close_all;
		undef $::project_obj;

		# プロジェクトを削除
		#（最後に追加したプロジェクトの削除）
		my $win_opn = gui_window::project_open->open;
		my $n = @{$win_opn->projects->list} - 1;
		$win_opn->{g_list}->selectionClear(0);
		$win_opn->{g_list}->selectionSet($n);
		$win_opn->delete;
		$win_opn->close;

		# KH Coderを終了
		exit;
	
	}

	return undef;
}

1;
