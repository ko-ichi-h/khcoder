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

	my $e1 = $fra4e->Entry(
		-font => "TKFN"
	)->pack(expand => 'y', fill => 'x', side => 'left');
	$wmw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e1]);
	$e1->bind("<Shift-Key-Return>",sub{$self->search;});

	my $sbutton = $fra4e->Button(
		-text => Jcode->new('検索')->sjis,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->search;});} 
	)->pack(-side => 'right', padx => '2');

	my $blhelp = $wmw->Balloon();
	$blhelp->attach(
		$sbutton,
		-balloonmsg => '"Shift + ENTER" key',
		-font => "TKFN"
	);

	# オプション・フレーム
	my $fra4h = $fra4->Frame->pack(-expand => 'y', -fill => 'x');

	my @methods;
	push @methods, Jcode->new('AND検索')->sjis;
	push @methods, Jcode->new('OR検索')->sjis;
	my $method;
	$fra4h->Optionmenu(
		-options=> \@methods,
		-font => "TKFN",
		-variable => \$gui_window::word_search::method,
	)->pack(-anchor=>'e', -side => 'left');

	$fra4h->Checkbutton(
		-text     => Jcode->new('基本形を検索')->sjis,
		-variable => \$gui_window::word_search::kihon,
		-font     => "TKFN",
		-command  => sub { $mw->after(10,sub{$self->refresh}); }
	)->pack(-side => 'left');

	$self->{the_check} = $fra4h->Checkbutton(
		-text     => Jcode->new('活用語表示')->sjis,
		-variable => \$gui_window::word_search::katuyo,
		-font     => "TKFN",
		-command  => sub { $mw->after(10,sub{$self->refresh}); }
	)->pack(-side => 'left');
	
	unless (defined($gui_window::word_search::katuyo)){
		$gui_window::word_search::kihon = 1;
		$gui_window::word_search::katuyo = 0;
	}



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

	MainLoop;

	$self->{st_label} = $status;
	$self->{list}     = $lis;
	$self->{win_obj}  = $wmw;
	$self->{entry}    = $e1;
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
	$self->st_label->configure(
		-text => 'Searching...',
		-foreground => 'red',
	);
	$self->win_obj->update;

	# 検索実行
	my $result = mysql_conc->a_word(
		query  => $query,
		length => 20,
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
	$self->win_obj->update;
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
		return 1;
	}
	my $fragment = $s_scroll / ($w_col0 + $w_col1 + $w_col2);
	$self->list->xview(moveto => $fragment);

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
sub st_label{
	my $self= shift;
	return $self->{st_label};
}
sub win_name{
	return 'w_word_conc';
}

1;