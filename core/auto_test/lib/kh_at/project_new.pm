package kh_at::project_new;
use base qw(kh_at);
use strict;

sub _exec_test{
	my $self = shift;
	
	# プロジェクトの作成
	gui_window::project_new->open;
	my $win_np = $::main_gui->get('w_new_pro');
	$win_np->{e1}->insert(0,gui_window->gui_jchar($self->file_testdata));
	$win_np->{e2}->insert(0,gui_window->gui_jchar('自動テスト用Project'));
	$win_np->_make_new;
	
	# 語の取捨選択
	gui_window::dictionary->open;
	my $win_dic = $::main_gui->get('w_dictionary');
	$win_dic->{t1}->insert('end',gui_window->gui_jchar("Ｋ\n西洋人\n好奇心"));
	$win_dic->{t2}->insert('end',gui_window->gui_jchar("１つ\n考え"));
	$win_dic->save;
	
	# 前処理の実行
	$::main_gui->{menu}->mc_morpho_exec;
	
	# いったんプロジェクトを閉じる
	$::main_gui->{menu}->mc_close_project;
	
	# プロジェクトの編集
	gui_window::project_open->open;
	my $win_opn = $::main_gui->get('w_open_pro');
	my $n = @{$win_opn->projects->list} - 1;
	$win_opn->{g_list}->selectionClear(0);
	$win_opn->{g_list}->selectionSet($n);

	$win_opn->edit;
	my $win_edt;
	$win_edt = $::main_gui->get('w_edit_pro');
	$win_edt->{e2}->insert('end',gui_window->gui_jchar('［編］'));
	$win_edt->_edit;

	# プロジェクトを開き直す
	$win_opn->{g_list}->selectionClear(0);
	$win_opn->{g_list}->selectionSet($n);
	$win_opn->_open;

	# テスト結果の取得
	my $t = '';
	$t .= "■project_name:\t".Jcode->new(
		gui_window->gui_jg( $::main_gui->inner->{e_curent_project}->get )
	)->euc."\n";
	$t .= "■project_comment:\t".Jcode->new(
		gui_window->gui_jg( $::main_gui->inner->{e_project_memo}->get )
	)->euc."\n";
	$t .= "■words_all:\t".Jcode->new(
		gui_window->gui_jg( $::main_gui->inner->{ent_num1}->get )
	)->euc."\n";
	$t .= "■project_kinds:\t".Jcode->new(
		gui_window->gui_jg( $::main_gui->inner->{ent_num2}->get )
	)->euc."\n";
	$t .= "■doc num:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $::main_gui->inner->hlist ) )
	)->euc;

	$self->{result} = $t;

	return $self;
}

sub test_name{
	return 'Create / Close / Edit / Open project...';
}


1;