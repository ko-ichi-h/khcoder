package kh_at::out_var;
use base qw(kh_at);
use strict;

sub _exec_test{
	my $self = shift;
	
	# 外部変数の読み込み (1)
	my $win = gui_window::outvar_read::csv->open;
	$win->{entry}->insert(0, $self->file_outvar );
	$win->{tani_obj}->{raw_opt} = 'dan';
	$win->{tani_obj}->mb_refresh;
	$win->_read;

	# 読み込み結果のチェック
	$self->{result} .= "■読み込み結果\n";
	$win = gui_window::outvar_list->open;
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	# 外部変数を1つ削除
	$win->{list}->selectionSet(1);
	$win->_delete(
		no_conf => 1,
	);
	$self->{result} .= "■変数削除の結果\n";
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	# ラベル編集(1)
	$win->{list}->selectionSet(1);
	$win->_open_var;
	my $win_edit = $::main_gui->get('w_outvar_detail');
	$win_edit->{entry}{0}->insert(0, gui_window->gui_jchar('なし') );
	$win_edit->{entry}{1}->insert(0, gui_window->gui_jchar('あり') );
	$win_edit->_save;

	# ラベル編集(2)
	$win->{list}->selectionSet(0);
	$win->_open_var;
	my $win_edit = $::main_gui->get('w_outvar_detail');
	$win_edit->{entry}{1}->insert(0, gui_window->gui_jchar('上') );
	$win_edit->{entry}{2}->insert(0, gui_window->gui_jchar('中') );
	$win_edit->{entry}{3}->insert(0, gui_window->gui_jchar('下') );
	$win_edit->_save;
	# ラベル編集の結果は、コーディング結果からチェックする…。

	# 外部変数の読み込み (2)
	my $win = gui_window::outvar_read::csv->open;
	$win->{entry}->insert(0, $self->file_outvar2 );
	$win->{tani_obj}->{raw_opt} = 'h1';
	$win->{tani_obj}->mb_refresh;
	$win->_read;

	return $self;
}

sub test_name{
	return 'Read & Edit Variables...';
}


1;