package gui_window::word_ass_opt;
use base qw(gui_window);

use Tk;

#-------------#
#   GUI作製   #
#-------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $win = $mw->Toplevel;
	$win->focus;
	$win->grab;
	$win->title(Jcode->new('連関規則 フィルタ設定')->sjis);
	$self->{win_obj} = $win;
	
	my $left = $win->Frame()->pack(-fill => 'both', -expand => 1);

	# 品詞による単語の取捨選択
	$left->Label(
		-text => Jcode->new('・品詞による語の取捨選択')->sjis,
		-font => "TKFN"
	)->pack(-anchor => 'w');
	my $l3 = $left->Frame()->pack(-fill => 'both',-expand => 1);
	$l3->Label(
		-text => Jcode->new('　　')->sjis,
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left',-fill => 'y',-expand => 1);
	%pack = (
			-anchor => 'w',
			-side   => 'left',
			-pady   => 5,
			-fill   => 'y',
			-expand => 1
	);
	$self->{hinshi_obj} = gui_widget::hinshi->open(
		parent    => $l3,
		pack      => \%pack,
		selection => $gui_window::word_ass::filter->{hinshi},
	);
	my $l4 = $l3->Frame()->pack(-fill => 'x', -expand => 'y',-side => 'left');
	$l4->Button(
		-text => Jcode->new('全て選択')->sjis,
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->{hinshi_obj}->select_all;});}
	)->pack(-pady => 3);
	$l4->Button(
		-text => Jcode->new('クリア')->sjis,
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->{hinshi_obj}->select_none;});}
	)->pack();

	# 全体での出現数
	my $left2 = $win->Frame()->pack(-fill => 'x', -expand => 0);
	$left2->Label(
		-text => Jcode->new('・全体での出現数による語の取捨選択')->sjis,
		-font => "TKFN"
	)->pack(-anchor => 'w',-pady => 2);
	
	$left2->Label(
		-text => Jcode->new('　　　最低文書数：')->sjis,
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left', -pady => 5);
	
	$self->{ent_total} = $left2->Entry(
		-font  => "TKFN",
		-width => 6,
	)->pack(-anchor => 'w',-pady => 5);

	# 表示数のLIMIT
	my $left3 = $win->Frame()->pack(-fill => 'x', -expand => 0);
	$left3->Label(
		-text => Jcode->new('・表示する語の数')->sjis,
		-font => "TKFN"
	)->pack(-anchor => 'w',-pady => 2);
	
	$left3->Label(
		-text => Jcode->new('　　　上位：')->sjis,
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left', -pady => 5);
	
	$self->{ent_limit} = $left3->Entry(
		-font  => "TKFN",
		-width => 6,
	)->pack(-anchor => 'w',-pady => 5);
	
	# OK & Cancel
	$win->Button(
		-text => Jcode->new('キャンセル')->sjis,
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$win->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->save;});}
	)->pack(-side => 'right');
	
	# 値の入力
	$self->{ent_total}->insert(
		"end",
		"$gui_window::word_ass::filter->{min_doc}"
	);
	$self->{ent_limit}->insert(
		"end",
		"$gui_window::word_ass::filter->{limit}"
	);
	
	return $self;
}


sub save{
	my $self = shift;
	
	$gui_window::word_ass::filter->{min_doc} = $self->{ent_total}->get;
	$gui_window::word_ass::filter->{limit}   = $self->{ent_limit}->get;
	
	my %selected;
	foreach my $i (@{$self->{hinshi_obj}->selected}){
		$selected{$i} = 1;
	}
	foreach my $i (keys %{$gui_window::word_ass::filter->{hinshi}}){
			$gui_window::word_ass::filter->{hinshi}{$i} = $selected{$i};
	}
	
	$::main_gui->get('w_doc_ass')->display;
	$self->close;
}


sub win_name{
	return 'w_doc_ass_opt';
}

1;