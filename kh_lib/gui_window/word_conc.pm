package gui_window::word_conc;
use base qw(gui_window);
use strict;
use Tk;
use Tk::HList;
use NKF;
use mysql_conc;
use Jcode;

#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $wmw= $mw->Toplevel;
	$wmw->focus;
	$wmw->title(Jcode->new('コンコーダンス（KIWIC）')->sjis);

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
	$e1->bind("<Shift-Key-Return>",sub{$self->search;});

	$fra4e->Label(
		-text => Jcode->new('　品詞：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	my $e4 = $fra4e->Entry(
		-font => "TKFN",
		-width => 8
	)->pack(side => 'left');
	$e4->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e4]);
	$e4->bind("<Shift-Key-Return>",sub{$self->search;});

	$fra4e->Label(
		-text => Jcode->new('　活用形：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	my $e2 = $fra4e->Entry(
		-font => "TKFN",
		-width => 8
	)->pack(side => 'left');
	$e2->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e2]);
	$e2->bind("<Shift-Key-Return>",sub{$self->search;});

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
		-balloonmsg => '"Shift + ENTER" key',
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

	$fra4h->Optionmenu(
		-options=> \@methods,
		-font => "TKFN",
		-variable => \$self->{sort1},
		-width => 6,
	)->pack(-anchor=>'e', -side => 'left');

	$fra4h->Label(
		-text => Jcode->new('　ソート2：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	$fra4h->Optionmenu(
		-options=> \@methods,
		-font => "TKFN",
		-variable => \$self->{sort2},
		-width => 6,
	)->pack(-anchor=>'e', -side => 'left');

	$fra4h->Label(
		-text => Jcode->new('　ソート3：')->sjis,
		-font => "TKFN"
	)->pack(side => 'left');

	$fra4h->Optionmenu(
		-options=> \@methods,
		-font => "TKFN",
		-variable => \$self->{sort3},
		-width => 6,
	)->pack(-anchor=>'e', -side => 'left');




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
		-selectforeground => 'brown',
		-selectbackground => 'cyan',
		-selectmode       => 'extended',
	)->pack(-fill =>'both',-expand => 'yes');

	$fra5->Button(
		-text => Jcode->new('コピー')->sjis,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub {gui_hlist->copy($self->list);});} 
	)->pack(-side => 'left',-anchor => 'w');


	$fra5->Button(
		-text => Jcode->new('テスト')->sjis,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub {
			my ($e1, $e2) = $self->list->xview;
			print "xview: $e1, $e2\n";
			my $width = $self->list->cget('width');
			print "width: $width\n";
		});} 
	)->pack(-side => 'left',-anchor => 'w');


	my $status = $fra5->Label(
		-text => 'Ready.',
		-foreground => 'blue'
	)->pack(-side => 'right', -anchor => 'e');

	my $hits = $fra5->Label(
		-text => '  Hits: '
	)->pack(-side => 'left');

	MainLoop;

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
	
	print "test: ".$self->sort1."\n";

	# 検索実行
	$self->st_label->configure(
		-text => 'Searching...',
		-foreground => 'red',
	);
	$self->hit_label->configure(
		-text => "  Hits:"
	);
	$self->win_obj->update;

	my $result = mysql_conc->a_word(
		query  => $query,
		katuyo => $katuyo,
		hinshi => $hinshi,
		length => $length,
		sort1  => $sconv{Jcode->new($self->sort1)->euc},
		sort2  => $sconv{Jcode->new($self->sort2)->euc},
		sort3  => $sconv{Jcode->new($self->sort3)->euc},
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
	my $n = @{$result};
	$self->hit_label->configure(
		-text => "  Hits: $n"
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

}


#--------------#
#   アクセサ   #
#--------------#

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
sub st_label{
	my $self= shift;
	return $self->{st_label};
}
sub hit_label{
	my $self= shift;
	return $self->{hit_label};
}
sub sort1{
	my $self = shift;
	return $self->{sort1};
}
sub sort2{
	my $self = shift;
	return $self->{sort2};
}
sub sort3{
	my $self = shift;
	return $self->{sort3};
}
sub win_name{
	return 'w_word_conc';
}

1;
