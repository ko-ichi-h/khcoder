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