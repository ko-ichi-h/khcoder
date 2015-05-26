package kh_at::pretreatment;
use base qw(kh_at);
use strict;

# テスト出力数: 7

sub _exec_test{
	my $self = shift;
	my $t = '';
	
	# 「語の抽出結果を確認」
	gui_window::morpho_check->open;
	my $win_src = $::main_gui->get('w_morpho_check');
	$win_src->entry->insert(0,gui_window->gui_jchar('卒業証書'));
	$win_src->search;
	$t .= "■語の抽出結果を確認:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win_src->list ),'reserve_rn'  )
	)->euc;
	
	# 「語の抽出結果を確認：詳細」
	$win_src->list->selectionSet(0);
	$win_src->detail;
	my $win_dtl = $::main_gui->get('w_morpho_detail');
	$t .= "■語の抽出結果を確認（詳細）:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win_dtl->list ),'reserve_rn'  ),
		'sjis'
	)->euc;

	# 「語の取捨選択」（品詞選択）
	gui_window::dictionary->open;
	my $win_dic1 = $::main_gui->get('w_dictionary');
	$win_dic1->{checks}[3] = 0;
	$win_dic1->{checks}[4] = 0;
	$win_dic1->hlist->update;
	$win_dic1->save;
	$t .= "■品詞選択（変更）:\n";
	$t .= "words_all:\t".Jcode->new(
		gui_window->gui_jg( $::main_gui->inner->{ent_num1}->get,'reserve_rn'  )
	)->euc."\n";
	$t .= "project_kinds:\t".Jcode->new(
		gui_window->gui_jg( $::main_gui->inner->{ent_num2}->get,'reserve_rn'  )
	)->euc."\n";

	gui_window::dictionary->open;
	my $win_dic2 = $::main_gui->get('w_dictionary');
	$win_dic2->{checks}[3] = 1;
	$win_dic2->{checks}[4] = 1;
	$win_dic2->hlist->update;
	$win_dic2->save;
	$t .= "■品詞選択（再変更）:\n";
	$t .= "words_all:\t".Jcode->new(
		gui_window->gui_jg( $::main_gui->inner->{ent_num1}->get,'reserve_rn'  )
	)->euc."\n";
	$t .= "project_kinds:\t".Jcode->new(
		gui_window->gui_jg( $::main_gui->inner->{ent_num2}->get,'reserve_rn'  )
	)->euc."\n";

	# 「複合語の検出」→「TermExtract」
	use mysql_hukugo_te;
	mysql_hukugo_te->run_from_morpho;
	my $win_hukugo_te = gui_window::use_te_g->open;
	$t .= "■複合語の検出（TermExtract）\n";
	$t .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all($win_hukugo_te->{list}),'reserve_rn','reserve_rn'   )
	)->euc;
	
	# 「複合語の検出」→「茶筌」
	use mysql_hukugo;
	mysql_hukugo->run_from_morpho;
	my $win_hukugo_ch = gui_window::hukugo->open;
	$t .= "■複合語の検出（茶筌）\n";
	$t .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all($win_hukugo_ch->{list}),'reserve_rn'  )
	)->euc;
	
	$self->{result} = $t;
	return $self;
}

sub test_name{
	return 'pre-processing...';
}

1;