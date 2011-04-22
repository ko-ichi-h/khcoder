package kh_at::words;
use base qw(kh_at);
use strict;

sub _exec_test{
	my $self = shift;
	$self->{result} = '';
	
	# 抽出語検索
	$self->{result} .= "■抽出語検索\n";
	my $win_src = gui_window::word_search->open;
	
	$self->{result} .= "□形態素\n";
	$gui_window::word_search::kihon = 0;
	$win_src->refresh;
	$self->_ws_BK($win_src);
	
	$self->{result} .= "□抽出語\n";
	$gui_window::word_search::kihon = 1;
	$gui_window::word_search::katuyo = 0;
	$win_src->refresh;
	$self->_ws_BK($win_src);
	
	$self->{result} .= "□抽出語−活用形表示\n";
	$gui_window::word_search::katuyo = 1;
	$win_src->refresh;
	$self->_ws_BK($win_src);
	
	# コンコーダンス
	$self->{result} .= "■コンコーダンス\n";
	
	$self->{result} .= "□抽出語＋品詞\n";
	$win_src->{optmenu_bk}->set_value('p');
	$win_src->{entry}->delete(0,'end');
	$win_src->{entry}->insert( 0, gui_window->gui_jchar('死') );
	$win_src->search;
	$win_src->list->selectionSet(0);
	$win_src->conc;
	my $win_cnc = $::main_gui->get('w_word_conc');
	$self->_wc_sort($win_cnc);
	
	$self->{result} .= "□抽出語＋品詞＋活用形\n";
	$win_src->list->selectionClear(0);
	$win_src->list->selectionSet("0.4");
	$win_src->conc;
	$self->_wc_sort($win_cnc);
	
	$self->{result} .= "□抽出語＋品詞＋追加条件\n";
	$win_src->list->selectionClear("0.4");
	$win_src->list->selectionSet(0);
	$win_src->conc;
	my $win_cnc_opt = gui_window::word_conc_opt->open;
	$win_cnc_opt->{menu1}->set_value('l2');
	$win_cnc_opt->_menu_check;
	$win_cnc_opt->{entry}{'1a'}->insert( 0, gui_window->gui_jchar('父') );
	$win_cnc_opt->save;
	$self->_wc_sort($win_cnc);
	
	$self->{result} .= "□品詞\n";
	$win_cnc_opt = gui_window::word_conc_opt->open; # 追加条件の削除
	$win_cnc_opt->{menu1}->set_value(0);
	$win_cnc_opt->_menu_check;
	$win_cnc_opt->save;
	$win_cnc->{entry}->delete(0, 'end');            # 検索条件のセット
	$win_cnc->{entry4}->delete(0, 'end');
	$win_cnc->{entry4}->insert(0, gui_window->gui_jchar('名詞'));
	$self->_wc_sort($win_cnc);
	
	$self->{result} .= "□品詞＋追加条件（品詞）\n";
	my $win_cnc_opt = gui_window::word_conc_opt->open;
	$win_cnc_opt->{menu1}->set_value('l1');
	$win_cnc_opt->_menu_check;
	$win_cnc_opt->{entry}{'1b'}->insert( 0, gui_window->gui_jchar('形容詞') );
	$win_cnc_opt->save;
	$self->_wc_sort($win_cnc);
	
	# コロケーション統計
	$self->{result} .= "■コロケーション統計\n";
	
	$win_cnc_opt = gui_window::word_conc_opt->open; # 追加条件の削除
	$win_cnc_opt->{menu1}->set_value(0);
	$win_cnc_opt->_menu_check;
	$win_cnc_opt->save;
	
	$win_cnc->{entry}->delete(0,'end');
	$win_cnc->{entry4}->delete(0,'end');
	$win_cnc->{entry}->insert(0, gui_window->gui_jchar('先生') );
	$win_cnc->search;
	$win_cnc->coloc;
	
	my $win_coloc = $::main_gui->get('w_word_conc_coloc');
	$self->_wcl_filter($win_coloc);
	
	# 出現数 分布
	$self->{result} .= "■出現回数 分布\n";
	my $win_freq = gui_window::word_freq->open;
	$win_freq->count;
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win_freq->{list1} ) )
	)->euc;
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win_freq->{list2} ) )
	)->euc;
	
	# 文書数 分布
	$self->{result} .= "■文書数 分布\n";
	my $win_df = gui_window::word_df_freq->open;
	$win_df->{tani_obj}->{raw_opt} = 'h2';
	$win_df->{tani_obj}->mb_refresh;
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win_df->{list1} ) )
	)->euc;
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win_df->{list2} ) )
	)->euc;
	
	# 品詞別 出現数順 リスト
	$self->{result} .= "■品詞別 出現数順 リスト\n";
	my $target = $::project_obj->file_TempCSV;
	mysql_words->csv_list($target);
	open (RFILE,"$target") or die;
	while (<RFILE>){
		$self->{result} .= Jcode->new($_)->euc;
	}
	close (RFILE);

	return $self;
}

#----------------------------------#
#   コロケーション統計のパターン   #

sub _wcl_filter{
	my $self = shift;
	my $win  = shift;
	my $t = '';
	
	# $self->{result} .= "●フィルタ無し\n";
	# $self->_wcl_sort($win);
	
	$self->{result} .= "●フィルタ有り\n";
	my $win_filter = gui_window::word_conc_coloc_opt->open;
	$win_filter->{ent_limit}->delete(0,'end');
	$win_filter->{ent_limit}->insert( 0, '50' );
	foreach my $i (%{$win_filter->{hinshi_obj}->{name}}){
		if (
			   $win_filter->{hinshi_obj}->{name}{$i} == 21
			|| $win_filter->{hinshi_obj}->{name}{$i} == 22
			|| $win_filter->{hinshi_obj}->{name}{$i} == 16
			|| $win_filter->{hinshi_obj}->{name}{$i} == 17
			|| $win_filter->{hinshi_obj}->{name}{$i} == 18
			|| $win_filter->{hinshi_obj}->{name}{$i} == 19
			|| $win_filter->{hinshi_obj}->{name}{$i} == 10
			|| $win_filter->{hinshi_obj}->{name}{$i} == 12
		){
			$win_filter->{hinshi_obj}->{check_wigets}->[$i]->deselect;
		}
	}
	$win_filter->save;
	$self->_wcl_sort($win);

	return $self;
}

sub _wcl_sort{
	my $self = shift;
	my $win  = shift;
	my $t = '';
	
	$t .= "○ソート：スコア\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{hlist} ) )
	)->euc;
	
	$win->{menu1}->set_value('r2');
	$win->view;
	$t .= "○ソート：右2\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{hlist} ) )
	)->euc;
	
	$win->{menu1}->set_value('suml');
	$win->view;
	$t .= "○ソート：左合計\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{hlist} ) )
	)->euc;
	
	$win->{menu1}->set_value('score');
	$win->view;
	
	$self->{result} .= $t;
	return $self;
}

#------------------------------#
#   コンコーダンスのパターン   #

sub _wc_sort{
	my $self = shift;
	my $win  = shift;
	my $t = '';
	
	#$win->{entry}->insert(0, gui_window->gui_jchar('死ぬ') );
	
	$win->{menu1}->set_value('l1');
	$win->_menu_check;
	$win->{menu2}->set_value('l2');
	$win->_menu_check;
	$win->{menu3}->set_value('l3');
	$win->_menu_check;
	$win->search;
	$t .= "○ソート：左\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	$win->{menu1}->set_value('r1');
	$win->_menu_check;
	$win->{menu2}->set_value('r2');
	$win->_menu_check;
	$win->{menu3}->set_value('r3');
	$win->_menu_check;
	$win->search;
	$t .= "○ソート：右\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	$win->{menu1}->set_value('l2');
	$win->_menu_check;
	$win->{menu2}->set_value('id');
	$win->_menu_check;
	$win->search;
	$t .= "○ソート：左2\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;


	$win->{menu1}->set_value('id');
	$win->_menu_check;
	$win->search;
	$t .= "○ソート：ID\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;
	
	$self->{result} .= $t;
	return $self;
}

#--------------------------#
#   抽出語検索のパターン   #

sub _ws_BK{
	my $self = shift;
	my $win  = shift;
	
	$self->{result} .= "●部分一致:\n";
	$win->{optmenu_bk}->set_value('p');
	$self->_ws_AndOr($win);
	
	$self->{result} .= "●完全一致:\n";
	$win->{optmenu_bk}->set_value('c');
	$self->_ws_AndOr($win);

	$self->{result} .= "●前方一致:\n";
	$win->{optmenu_bk}->set_value('z');
	$self->_ws_AndOr($win);

	$self->{result} .= "●後方一致:\n";
	$win->{optmenu_bk}->set_value('k');
	$self->_ws_AndOr($win);

	return $self;
}

sub _ws_AndOr{
	my $self = shift;
	my $win  = shift;
	my $t;
	
	# OR検索
	$win->{optmenu_andor}->set_value('OR');
	$win->{entry}->delete(0,'end');
	$win->{entry}->insert( 0, gui_window->gui_jchar('者') );
	$win->search;
	$t .= "○OR-1:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	$win->{entry}->delete(0,'end');
	$win->{entry}->insert( 0, gui_window->gui_jchar('死 殺　亡') );
	$win->search;
	$t .= "○OR-2:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	# AND検索
	$win->{optmenu_andor}->set_value('AND');
	$win->{entry}->delete(0,'end');
	$win->{entry}->insert( 0, gui_window->gui_jchar('死') );
	$win->search;
	$t .= "○AND-1:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	$win->{entry}->delete(0,'end');
	$win->{entry}->insert( 0, gui_window->gui_jchar('生　る') );
	$win->search;
	$t .= "○AND-2:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	$self->{result} .= $t;
	return $self;
}

sub test_name{
	return 'words...     ';
}

1;