package kh_at::words;
use base qw(kh_at);
use strict;

sub _exec_test{
	my $self = shift;
	$self->{result} = '';
	
	# Ãê½Ð¸ì¸¡º÷
	$self->{result} .= "¢£Ãê½Ð¸ì¸¡º÷\n";
	my $win_src = gui_window::word_search->open;
	
	$self->{result} .= "¢¢·ÁÂÖÁÇ\n";
	$gui_window::word_search::kihon = 0;
	$win_src->refresh;
	$self->_ws_BK($win_src);
	
	$self->{result} .= "¢¢Ãê½Ð¸ì\n";
	$gui_window::word_search::kihon = 1;
	$gui_window::word_search::katuyo = 0;
	$win_src->refresh;
	$self->_ws_BK($win_src);
	
	$self->{result} .= "¢¢Ãê½Ð¸ì¡Ý³èÍÑ·ÁÉ½¼¨\n";
	$gui_window::word_search::katuyo = 1;
	$win_src->refresh;
	$self->_ws_BK($win_src);
	
	# ¥³¥ó¥³¡¼¥À¥ó¥¹
	$self->{result} .= "¢£¥³¥ó¥³¡¼¥À¥ó¥¹\n";
	
	$self->{result} .= "¢¢Ãê½Ð¸ì¡ÜÉÊ»ì\n";
	$win_src->{optmenu_bk}->set_value('p');
	$win_src->{entry}->delete(0,'end');
	$win_src->{entry}->insert( 0, gui_window->gui_jchar('»à') );
	$win_src->search;
	$win_src->list->selectionSet(0);
	$win_src->conc;
	my $win_cnc = $::main_gui->get('w_word_conc');
	$self->_wc_sort($win_cnc);
	
	$self->{result} .= "¢¢Ãê½Ð¸ì¡ÜÉÊ»ì¡Ü³èÍÑ·Á\n";
	$win_src->list->selectionClear(0);
	$win_src->list->selectionSet("0.4");
	$win_src->conc;
	$self->_wc_sort($win_cnc);
	
	$self->{result} .= "¢¢Ãê½Ð¸ì¡ÜÉÊ»ì¡ÜÄÉ²Ã¾ò·ï\n";
	$win_src->list->selectionClear("0.4");
	$win_src->list->selectionSet(0);
	$win_src->conc;
	my $win_cnc_opt = gui_window::word_conc_opt->open;
	$win_cnc_opt->{menu1}->set_value('l2');
	$win_cnc_opt->_menu_check;
	$win_cnc_opt->{entry}{'1a'}->insert( 0, gui_window->gui_jchar('Éã') );
	$win_cnc_opt->save;
	$self->_wc_sort($win_cnc);
	
	# ¥³¥í¥±¡¼¥·¥ç¥óÅý·×
	$win_cnc_opt = gui_window::word_conc_opt->open; # ¸½¾õ(?)Éüµ¢
	$win_cnc_opt->{menu1}->set_value(0);
	$win_cnc_opt->_menu_check;
	$win_cnc_opt->save;
	$win_cnc->search;
	$win_cnc->coloc;
		# Ì¤´°¡ª
	
	# ½Ð¸½¿ô Ê¬ÉÛ
	$self->{result} .= "¢£½Ð¸½¿ô Ê¬ÉÛ\n";
	my $win_freq = gui_window::word_freq->open;
	$win_freq->count;
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win_freq->{list1} ) )
	)->euc;
	$self->{result} .= Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win_freq->{list2} ) )
	)->euc;
	
	# ÉÊ»ìÊÌ ½Ð¸½¿ô½ç ¥ê¥¹¥È
	$self->{result} .= "¢£ÉÊ»ìÊÌ ½Ð¸½¿ô½ç ¥ê¥¹¥È\n";
	my $target = $::project_obj->file_WordList;
	mysql_words->csv_list($target);
	open (RFILE,"$target") or die;
	while (<RFILE>){
		$self->{result} .= Jcode->new($_)->euc;
	}
	close (RFILE);

	return $self;
}

sub _wc_sort{
	my $self = shift;
	my $win  = shift;
	my $t = '';
	
	#$win->{entry}->insert(0, gui_window->gui_jchar('»à¤Ì') );
	
	$win->{menu1}->set_value('l1');
	$win->_menu_check;
	$win->{menu2}->set_value('l2');
	$win->_menu_check;
	$win->{menu3}->set_value('l3');
	$win->_menu_check;
	$win->search;
	$t .= "¡û¥½¡¼¥È¡§º¸\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	$win->{menu1}->set_value('r1');
	$win->_menu_check;
	$win->{menu2}->set_value('r2');
	$win->_menu_check;
	$win->{menu3}->set_value('r3');
	$win->_menu_check;
	$win->search;
	$t .= "¡û¥½¡¼¥È¡§±¦\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	$win->{menu1}->set_value('l2');
	$win->_menu_check;
	$win->{menu2}->set_value('id');
	$win->_menu_check;
	$win->search;
	$t .= "¡û¥½¡¼¥È¡§º¸2\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;


	$win->{menu1}->set_value('id');
	$win->_menu_check;
	$win->search;
	$t .= "¡û¥½¡¼¥È¡§ID\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;
	
	$self->{result} .= $t;
	return $self;
}

sub _ws_BK{
	my $self = shift;
	my $win  = shift;
	
	$self->{result} .= "¡üÉôÊ¬°ìÃ×:\n";
	$win->{optmenu_bk}->set_value('p');
	$self->_ws_AndOr($win);
	
	$self->{result} .= "¡ü´°Á´°ìÃ×:\n";
	$win->{optmenu_bk}->set_value('c');
	$self->_ws_AndOr($win);

	$self->{result} .= "¡üÁ°Êý°ìÃ×:\n";
	$win->{optmenu_bk}->set_value('z');
	$self->_ws_AndOr($win);

	$self->{result} .= "¡ü¸åÊý°ìÃ×:\n";
	$win->{optmenu_bk}->set_value('k');
	$self->_ws_AndOr($win);

	return $self;
}

sub _ws_AndOr{
	my $self = shift;
	my $win  = shift;
	my $t;
	
	# OR¸¡º÷
	$win->{optmenu_andor}->set_value('OR');
	$win->{entry}->delete(0,'end');
	$win->{entry}->insert( 0, gui_window->gui_jchar('¼Ô') );
	$win->search;
	$t .= "¡ûOR-1:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	$win->{entry}->delete(0,'end');
	$win->{entry}->insert( 0, gui_window->gui_jchar('»à »¦¡¡Ë´') );
	$win->search;
	$t .= "¡ûOR-2:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	# AND¸¡º÷
	$win->{optmenu_andor}->set_value('AND');
	$win->{entry}->delete(0,'end');
	$win->{entry}->insert( 0, gui_window->gui_jchar('»à') );
	$win->search;
	$t .= "¡ûAND-1:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	$win->{entry}->delete(0,'end');
	$win->{entry}->insert( 0, gui_window->gui_jchar('À¸¡¡¤ë') );
	$win->search;
	$t .= "¡ûAND-2:\n".Jcode->new(
		gui_window->gui_jg( gui_hlist->get_all( $win->{list} ) )
	)->euc;

	$self->{result} .= $t;
	return $self;
}

sub test_name{
	return 'Words-Menu commands...';
}

1;