package kh_at::pretreatment;
use base qw(kh_at);
use strict;

sub _exec_test{
	my $self = shift;
	my $t = '';
	
	# 「語の抽出結果を確認」
	gui_window::morpho_check->open;
	my $win_src = $::main_gui->get('w_morpho_check');
	$win_src->entry->insert(0,gui_window->gui_jchar('卒業証書'));
	$win_src->search;
	$t .= "■morpho-check:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win_src->list ) )
	)->euc;
	
	# 「語の抽出結果を確認：詳細」
	$win_src->list->selectionSet(0);
	$win_src->detail;
	my $win_dtl = $::main_gui->get('w_morpho_detail');
	$t .= "■morpho-detail:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win_dtl->list ) ),
		'sjis'
	)->euc;

	
	$self->{result} = $t;
	return $self;
}

sub test_name{
	return 'Pretreatment commands...';
}

1;