package gui_window::word_conc;
use base qw(gui_window);
use strict;
use Tk;
use Tk::HList;
use NKF;
use mysql_conc;
use Jcode;
use gui_widget::tani;

#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $wmw= $mw->Toplevel;
	$wmw->focus;
	$wmw->title(Jcode->new('コンコーダンス [KWIC]')->sjis);

	my $fra4 = $wmw->LabFrame(
		-label => 'Search Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');

	# エントリと検索ボタンのフレーム
	my $fra4e = $fra4->Frame()->pack(-expand => 'y', -fill => 'x');

	$fra4e->Label(
		-text => Jcode->new('抽出語：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	my $e1 = $fra4e->Entry(
		-font => "TKFN",
		-width => 14
	)->pack(side => 'left');
	$wmw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e1]);
	$e1->bind("<Key-Return>",sub{$self->search;});

	$fra4e->Label(
		-text => Jcode->new('　品詞：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	my $e4 = $fra4e->Entry(
		-font => "TKFN",
		-width => 8
	)->pack(side => 'left');
	$e4->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e4]);
	$e4->bind("<Key-Return>",sub{$self->search;});

	$fra4e->Label(
		-text => Jcode->new('　活用形：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	my $e2 = $fra4e->Entry(
		-font => "TKFN",
		-width => 8
	)->pack(side => 'left');
	$e2->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e2]);
	$e2->bind("<Key-Return>",sub{$self->search;});

	$fra4e->Label(
		-text => Jcode->new('　（前後の')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	my $e3 = $fra4e->Entry(
		-width => 2
	)->pack(side => 'left');
	$e3->insert('end','20');

	$fra4e->Label(
		-text => Jcode->new('語を取り出す）')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	my $sbutton = $fra4e->Button(
		-text => Jcode->new('検索')->sjis,
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->search;});} 
	)->pack(-side => 'right', padx => '2');

	my $blhelp = $wmw->Balloon();
	$blhelp->attach(
		$sbutton,
		-balloonmsg => '"ENTER" key',
		-font => "TKFN"
	);

	# ソート・オプションのフレーム
	my $fra4h = $fra4->Frame->pack(-expand => 'y', -fill => 'x');

	my @methods = ('出現順', '左・5','左・4','左・3','左・2','左・1','活用形','右・1','右・2','右・3','右・4','右・5',);
	foreach my $i (@methods){
		$i = Jcode->new("$i")->sjis;
	}

	$fra4h->Label(
		-text => Jcode->new('ソート1：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	$self->{menu1} = $fra4h->Optionmenu(
		-options=> \@methods,
		-font => "TKFN",
		-variable => \$self->{sort1},
		-width => 6,
		-command => sub{ $mw->after(10,sub{$self->_menu_check;});} 
	)->pack(-anchor=>'e', -side => 'left');

	$fra4h->Label(
		-text => Jcode->new('　ソート2：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	$self->{menu2} = $fra4h->Optionmenu(
		-options=> \@methods,
		-font => "TKFN",
		-variable => \$self->{sort2},
		-width => 6,
		-command => sub{ $mw->after(10,sub{$self->_menu_check;});} 
	)->pack(-anchor=>'e', -side => 'left');

	$fra4h->Label(
		-text => Jcode->new('　ソート3：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	$self->{menu3} = $fra4h->Optionmenu(
		-options=> \@methods,
		-font => "TKFN",
		-variable => \$self->{sort3},
		-width => 6,
		-command => sub{ $mw->after(10,sub{$self->_menu_check;});} 
	)->pack(-anchor=>'e', -side => 'left');

	$fra4h->Label(
		-text => Jcode->new('　最大表示数：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	my $limit_e = $fra4h->Entry(
		-font  => "TKFN",
		-width => 5,
	)->pack(-side => 'left');
	$limit_e->insert(0,'1000');

	# 結果表示部分
	my $fra5 = $wmw->LabFrame(
		-label => 'Result',
		-labelside => 'acrosstop',
		-borderwidth => 2
	)->pack(-expand=>'yes',-fill=>'both');

	my $hlist_fra = $fra5->Frame()->pack(-expand => 'y', -fill => 'both');

	my $lis = $hlist_fra->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 0,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 3,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'black',
		-selectbackground => 'cyan',
		-selectmode       => 'extended',
		-height           => 20,
		-command          => sub {$mw->after(10,sub{$self->view_doc;});}
	)->pack(-fill =>'both',-expand => 'yes');



	$fra5->Button(
		-text => Jcode->new('文書表示')->sjis,
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {$self->view_doc;});} 
	)->pack(-side => 'left',-anchor => 'w',-padx =>1, -pady => 1);

	my $status = $fra5->Label(
		-text => Jcode->new(' 表示単位：')->sjis,
		-font => "TKFN"
	)->pack(-side => 'left');
	
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $fra5,
	);
	$self->{tani_obj}->win_obj->pack(-side => 'left',-padx => 1,-pady => 1);



	my $status = $fra5->Label(
		-text => Jcode->new('　　　')->sjis,
		-font => "TKFN"
	)->pack(-side => 'left');

	$fra5->Button(
		-text => Jcode->new('コピー')->sjis,
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {gui_hlist->copy($self->list);});} 
	)->pack(-side => 'left',-anchor => 'w', -pady => 1);

	my $status = $fra5->Label(
		-text => Jcode->new('　　　')->sjis,
		-font => "TKFN"
	)->pack(-side => 'left');

	my $status = $fra5->Label(
		-text => 'Ready.',
		-foreground => 'blue'
	)->pack(-side => 'right', -anchor => 'e');

	my $hits = $fra5->Label(
		-text => 'Hits: '
	)->pack(-side => 'left');

	MainLoop;

	$self->{entry_limit} = $limit_e;
	$self->{st_label} = $status;
	$self->{hit_label} = $hits;
	$self->{list}     = $lis;
	$self->{win_obj}  = $wmw;
	$self->{entry}    = $e1;
	$self->{entry2}    = $e2;
	$self->{entry3}    = $e3;
	$self->{entry4}    = $e4;
	return $self;
}

#------------------------#
#   メニューの状態変更   #
#------------------------#
sub _menu_check{
	my $self = shift;
	my $flag = 0;
	for (my $n = 1; $n <= 3; ++$n){
		if ($flag){
			$self->menu($n)->configure(-state, 'disable');
		} else {
			$self->menu($n)->configure(-state, 'normal');
		}
		
		if (Jcode->new($self->sort($n))->euc eq '出現順'){
			$flag = 1;
		}
	}
}

#--------------#
#   文書表示   #
#--------------#
sub view_doc{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	unless (@selected){
		return;
	}
	my $selected = $selected[0];
	my $tani = $self->doc_view_tani;
	my @kyotyo = @{mysql_conc->last_words};
	my $hyosobun_id = $self->result->[$selected][3];

	my $view_win = gui_window::doc_view->open;
	$view_win->view(
		hyosobun_id => $hyosobun_id,
		kyotyo      => \@kyotyo,
		tani        => "$tani",
		parent      => $self
	);
}

sub next{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	unless (@selected){
		return -1;
	}
	my $selected = $selected[0] + 1;
	my $max = @{$self->result} - 1;
	if ($selected > $max){
		$selected = $max;
	}
	my $hyosobun_id = $self->result->[$selected][3];
	
	$self->list->selectionClear;
	$self->list->selectionSet($selected);
	$self->list->yview($selected);
	my $n = @{$self->result};
	if ($n - $selected > 7){
		$self->list->yview(scroll => -5, 'units');
	}
	
	return $hyosobun_id;
}

sub prev{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	unless (@selected){
		return -1;
	}
	my $selected = $selected[0] - 1;
	if ($selected < 0){
		$selected = 0;
	}
	my $hyosobun_id = $self->result->[$selected][3];
	
	$self->list->selectionClear;
	$self->list->selectionSet($selected);
	$self->list->yview($selected);
	my $n = @{$self->result};
	if ($n - $selected > 7){
		$self->list->yview(scroll => -5, 'units');
	}
	
	return $hyosobun_id;
}

sub if_next{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	unless (@selected){
		return 0;
	}
	my $selected = $selected[0] ;
	my $max = @{$self->result} - 1;
	if ($selected < $max){
		return 1;
	} else {
		return 0;
	}
}
sub if_prev{
	my $self = shift;
	my @selected = $self->list->infoSelection;
	unless (@selected){
		return 0;
	}
	my $selected = $selected[0] ;
	if ($selected > 0){
		return 1;
	} else {
		return 0;
	}
}
sub end{
	my $check = 0;
	if ($::main_gui){
		$check = $::main_gui->if_opened('w_doc_view');
	}
	if ( $check ){
		$::main_gui->get('w_doc_view')->close;
	}
}


#----------#
#   検索   #
#----------#

sub search{
	my $self = shift;

	# 変数取得
	my $query = Jcode->new($self->entry->get)->euc;
	unless ($query){
		return;
	}
	my $katuyo = Jcode->new($self->entry2->get)->euc;
	my $hinshi = Jcode->new($self->entry4->get)->euc;
	my $length = $self->entry3->get;
	if ($length > 30){
		my $win = $self->win_obj;
		gui_errormsg->open(
			msg => "検索時に取り出せるのは前後29語までです。\n検索完了後に、より広い範囲を取り出すことができます。",
			window => \$win,
			type => 'msg',
		);
		return;
	}
	my $limit = $self->entry_limit->get;

	my %sconv = (
		'出現順' => 'id',
		'左・5'  => 'l5',
		'左・4'  => 'l4',
		'左・3'  => 'l3',
		'左・2'  => 'l2',
		'左・1'  => 'l1',
		'活用形' => 'center',
		'右・1'  => 'r1',
		'右・2'  => 'r2',
		'右・3'  => 'r3',
		'右・4'  => 'r4',
		'右・5'  => 'r5'
	);
	
	#print "test: ".$self->sort1."\n";

	# 検索実行
	$self->st_label->configure(
		-text => 'Searching...',
		-foreground => 'red',
	);
	$self->hit_label->configure(
		-text => "Hits:"
	);
	$self->win_obj->update;

	my ($result, $r_num) = mysql_conc->a_word(
		query  => $query,
		katuyo => $katuyo,
		hinshi => $hinshi,
		length => $length,
		sort1  => $sconv{Jcode->new($self->sort1)->euc},
		sort2  => $sconv{Jcode->new($self->sort2)->euc},
		sort3  => $sconv{Jcode->new($self->sort3)->euc},
		limit  => $limit,
	);


	# 結果表示
	$self->list->delete('all');
	unless ($result){
		$self->st_label->configure(
			-text => 'Ready.',
			-foreground => 'blue',
		);
		$self->win_obj->update;
		return 0;
	}
	
	my $right_style = $self->list->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'e',
		-background => 'white'
	);
	my $center_style = $self->list->ItemStyle(
		'text',
		-anchor => 'c',
		-font => "TKFN",
		-background => 'white',
		-foreground => 'red'
	);

	my $row = 0;
	foreach my $i (@{$result}){
		$self->list->add($row,-at => "$row");
		$self->list->itemCreate(
			$row,
			0,
			-text  => nkf('-s -E',$i->[0]),
			-style => $right_style
		);
		my $center = $self->list->itemCreate(
			$row,
			1,
			-text  => nkf('-s -E',$i->[1]),
			-style => $center_style
		);
		$self->list->itemCreate(
			$row,
			2,
			-text  => nkf('-s -E',$i->[2])
		);
		++$row;
	}

	$self->st_label->configure(
		-text => 'Ready.',
		-foreground => 'blue',
	);
	$self->hit_label->configure(
		-text => "Hits: $r_num"
	);
	$self->win_obj->update;
	
	# 表示のセンタリング
	$self->list->xview(moveto => 1);
	$self->list->yview(0);
	$self->win_obj->update;

	my $w_col0 = $self->list->columnWidth(0);
	my $w_col1 = $self->list->columnWidth(1);
	my $w_col2 = $self->list->columnWidth(2);

	my $visible = ($w_col0 + $w_col1 + $w_col2 - $self->list->xview);
	my $v_center = int( $visible / 2);
	my $s_center = $w_col0 + ( $w_col1 / 2 );
	my $s_scroll = $s_center - $v_center;
	if ($s_scroll < 0){
		$self->list->xview(moveto => 0);
	} else {
		my $fragment = $s_scroll / ($w_col0 + $w_col1 + $w_col2);
		$self->list->xview(moveto => $fragment);
	}
	$self->list->yview(0);
	
	$self->{result} = $result;
}

#------------#
#   初期化   #
#------------#

sub start{
	mysql_conc->initialize;
}


#--------------#
#   アクセサ   #
#--------------#

sub result{
	my $self = shift;
	return $self->{result};
}
sub list{
	my $self = shift;
	return $self->{list};
}
sub entry{
	my $self = shift;
	return $self->{entry};
}
sub entry2{
	my $self = shift;
	return $self->{entry2};
}
sub entry3{
	my $self = shift;
	return $self->{entry3};
}
sub entry4{
	my $self = shift;
	return $self->{entry4};
}
sub entry_limit{
	my $self = shift;
	return $self->{entry_limit};
}
sub st_label{
	my $self= shift;
	return $self->{st_label};
}
sub hit_label{
	my $self= shift;
	return $self->{hit_label};
}
sub sort1{ my $self = shift; return $self->{sort1};}
sub sort2{ my $self = shift; return $self->{sort2};}
sub sort3{ my $self = shift; return $self->{sort3};}
sub sort{  my $self = shift; return $self->{"sort$_[0]"};}
sub doc_view_tani{ my $self = shift; return $self->{tani_obj}->tani;}
sub menu{
	my $self = shift;
	my $key = "menu"."$_[0]";
	return $self->{"$key"};
}
sub win_name{
	return 'w_word_conc';
}

1;
