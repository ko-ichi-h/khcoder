package gui_window::doc_search;
use base qw(gui_window);

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $mw->Toplevel;
	$win->focus;
	$win->title(Jcode->new('文書検索')->sjis);
	$self->{win_obj} = $win;



	return $self;
}

#--------------#
#   アクセサ   #
#--------------#

sub win_name{
	return 'w_doc_search';
}

1;