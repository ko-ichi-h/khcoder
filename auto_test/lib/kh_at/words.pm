package kh_at::words;
use base qw(kh_at);
use strict;

# ¥Æ¥¹¥È½ĞÎÏ¿ô: 48 + 

sub _exec_test{
	my $self = shift;
	$self->{result} = '';
	
	# Ãê½Ğ¸ì¸¡º÷
	$self->{result} .= "¢£Ãê½Ğ¸ì¸¡º÷\n";
	my $win_src = gui_window::word_search->open;
	
	$self->{result} .= "¢¢·ÁÂÖÁÇ\n";
	$gui_window::word_search::kihon = 0;
	$win_src->refresh;
	$self->_ws_BK($win_src);
	
	$self->{result} .= "¢¢Ãê½Ğ¸ì\n";
	$gui_window::word_search::kihon = 1;
	$gui_window::word_search::katuyo = 0;
	$win_src->refresh;
	$self->_ws_BK($win_src);
	
	$self->{result} .= "¢¢Ãê½Ğ¸ì¡İ³èÍÑ·ÁÉ½¼¨\n";
	$gui_window::word_search::katuyo = 1;
	$win_src->refresh;
	$self->_ws_BK($win_src);
	
	# ¥³¥ó¥³¡¼¥À¥ó¥¹
	$self->{result} .= "¢£¥³¥ó¥³¡¼¥À¥ó¥¹\n";
	
	$self->{result} .= "¢¢¥Î¡¼¥Ş¥ë\n";
	$win_src->{optmenu_bk}->set_value('p');
	$win_src->{entry}->delete(0,'end');
	$win_src->{entry}->insert( 0, gui_window->gui_jchar('»à') );
	$win_src->search;
	$win_src->list->selectionSet(0);
	$win_src->conc;
	my $win_cnc = $::main_gui->get('w_word_conc');
	$self->_wc_sort($win_cnc);
	
	$self->{result} .= "¢¢³èÍÑ·Á»ØÄê\n";
	$win_src->list->selectionClear(0);
	$win_src->list->selectionSet("0.4");
	$win_src->conc;
	$self->_wc_sort($win_cnc);
	
	$self->{result} .= "¢¢ÉÊ»ì»ØÄê\n";
	
	
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

	$self->{result} .= "¡üÁ°Êı°ìÃ×:\n";
	$win->{optmenu_bk}->set_value('z');
	$self->_ws_AndOr($win);

	$self->{result} .= "¡ü¸åÊı°ìÃ×:\n";
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
	$win->{entry}->insert( 0, gui_window->gui_jchar('»à') );
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