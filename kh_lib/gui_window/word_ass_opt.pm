package gui_window::word_ass_opt;
use base qw(gui_window);
use utf8;
use Tk;

#-------------#
#   GUI作製   #
#-------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	#$win->focus;
	#$win->grab;
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # 関連語探索・フィルタ設定
	#$self->{win_obj} = $win;
	
	my $left = $win->Frame()->pack(-fill => 'both', -expand => 1);

	# 品詞による単語の取捨選択
	$left->Label(
		-text => kh_msg->get('by_pos'), # ・品詞による語の取捨選択
		-font => "TKFN"
	)->pack(-anchor => 'w');
	my $l3 = $left->Frame()->pack(-fill => 'both',-expand => 1);
	$l3->Label(
		-text => '    ', # 　　
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
		-text => kh_msg->gget('all'), # すべて
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $self->{hinshi_obj}->select_all;}
	)->pack(-pady => 2);
	$l4->Button(
		-text => kh_msg->gget('default'), # 既定値
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->{hinshi_obj}->select_default;}
	)->pack(-pady => 2);
	$l4->Button(
		-text => kh_msg->gget('clear'), # クリア
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->{hinshi_obj}->select_none;}
	)->pack(-pady => 2);

	# 全体での出現数
	my $left2 = $win->Frame()->pack(-fill => 'x', -expand => 0);
	$left2->Label(
		-text => kh_msg->get('by_df'), # ・全体での出現数による語の取捨選択
		-font => "TKFN"
	)->pack(-anchor => 'w',-pady => 2);
	
	$left2->Label(
		-text => kh_msg->get('min_df'), # 　　　最低文書数：
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left', -pady => 5);
	
	$self->{ent_total} = $left2->Entry(
		-font  => "TKFN",
		-width => 6,
	)->pack(-anchor => 'w',-pady => 5);
	$self->config_entry_focusin($self->{ent_total});

	$self->{ent_total}->bind("<Key-Return>",sub{$self->save});
	$self->{ent_total}->bind("<KP_Enter>", sub{$self->save});

	# 表示数のLIMIT
	my $left3 = $win->Frame()->pack(-fill => 'x', -expand => 0);
	$left3->Label(
		-text => kh_msg->get('view'), # ・表示する語の数
		-font => "TKFN"
	)->pack(-anchor => 'w',-pady => 2);
	
	$left3->Label(
		-text => kh_msg->get('top'), # 　　　上位：
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left', -pady => 5);
	
	$self->{ent_limit} = $left3->Entry(
		-font  => "TKFN",
		-width => 6,
	)->pack(-anchor => 'w',-pady => 5);
	$self->config_entry_focusin($self->{ent_limit});
	
	$self->{ent_limit}->bind("<Key-Return>",sub{$self->save});
	$self->{ent_limit}->bind("<KP_Enter>", sub{$self->save});
	
	my $frame1 = $win->Frame()->pack(-fill => 'x', -expand => 1);
	$frame1->Checkbutton(
		-text     => kh_msg->get('show_lowc'), 
		-variable => \$gui_window::word_ass::filter->{show_lowc},
	)->pack(-anchor => 'w');
	
	# OK & Cancel
	$win->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2);

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->save;}
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

	$gui_window::word_ass::filter->{min_doc} = $self->gui_jgn( $self->{ent_total}->get );
	$gui_window::word_ass::filter->{limit}   = $self->gui_jgn( $self->{ent_limit}->get );

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