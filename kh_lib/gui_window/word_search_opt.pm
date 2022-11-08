package gui_window::word_search_opt;
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
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # 関連語探索・フィルタ設定
	
	my $left = $win->Frame()->pack(-fill => 'both', -expand => 1);

	# 品詞による単語の取捨選択
	$left->Label(
		-text => kh_msg->get('gui_window::word_ass_opt->by_pos'), # ・品詞による語の取捨選択
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
		selection => $gui_window::word_search::filter->{hinshi},
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

	# 表示数のLIMIT
	#my $left3 = $win->Frame()->pack(-fill => 'x', -expand => 0);
	#$left3->Label(
	#	-text => kh_msg->get('gui_window::word_ass_opt->view'), # ・表示する語の数
	#	-font => "TKFN"
	#)->pack(-anchor => 'w',-pady => 2);
	
	#$left3->Label(
	#	-text => kh_msg->get('gui_window::word_ass_opt->top'), # 　　　上位：
	#	-font => "TKFN"
	#)->pack(-anchor => 'w', -side => 'left', -pady => 5);
	
	#$self->{ent_limit} = $left3->Entry(
	#	-font  => "TKFN",
	#	-width => 6,
	#)->pack(-anchor => 'w',-pady => 5);
	#$self->config_entry_focusin($self->{ent_limit});
	
	#$self->{ent_limit}->bind("<Key-Return>",sub{$self->save});
	#$self->{ent_limit}->bind("<KP_Enter>", sub{$self->save});
	
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
	#$self->{ent_limit}->insert(
	#	"end",
	#	"$gui_window::word_search::filter->{limit}"
	#);
	
	return $self;
}


sub save{
	my $self = shift;

	#$gui_window::word_search::filter->{limit}   = $self->gui_jgn( $self->{ent_limit}->get );

	my %selected;
	my $count_pos = 0;
	foreach my $i (@{$self->{hinshi_obj}->selected}){
		$selected{$i} = 1;
		++$count_pos;
	}
	
	# fool proof
	unless ($count_pos){
		gui_errormsg->open(
			msg    => kh_msg->get('gui_window::dictionary->no_pos_selected'),
			type   => 'msg',
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	foreach my $i (keys %{$gui_window::word_search::filter->{hinshi}}){
			$gui_window::word_search::filter->{hinshi}{$i} = $selected{$i};
	}
	
	$::main_gui->get('w_word_search')->search;
	$self->close;
}


sub win_name{
	return 'w_doc_ass_opt';
}

1;