package gui_window::word_search;
use base qw(gui_window);
use vars qw($method,$kihon,$katuyo);
use strict;
use Tk;
use Tk::HList;
use Tk::Balloon;
use NKF;
use mysql_words;

#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $wmw= $mw->Toplevel;
	$wmw->focus;
	$wmw->title(Jcode->new('抽出語検索')->sjis);

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
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 3,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'brown',
		-selectbackground => 'cyan',
		-selectmode       => 'extended',
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => Jcode->new('単語')->sjis);
	$lis->header('create',1,-text => Jcode->new('品詞')->sjis);
	$lis->header('create',2,-text => Jcode->new('頻度')->sjis);

	$fra5->Button(
		-text => Jcode->new('コピー')->sjis,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub {gui_hlist->copy($self->list);});} 
	)->pack(-anchor => 'e');

	MainLoop;
	
	$self->{list_f} = $hlist_fra;
	$self->{list}  = $lis;
	$self->{win_obj} = $wmw;
	$self->{entry}   = $e1;
	$self->refresh;
	return $self;
}

#--------------------#
#   表示の切り替え   #
#--------------------#

sub refresh{
	my $self = shift;
	
	# チェックボックスの切り替え
	if ($gui_window::word_search::kihon){
		$self->the_check->configure(-state,'normal');
	} else {
		$self->the_check->configure(-state,'disable');
	}
	
	# リストの切り替え
	if ($gui_window::word_search::kihon){
		$self->list->destroy;
		
		$self->{list} = $self->list_f->Scrolled(
			'HList',
			-scrollbars       => 'osoe',
			-header           => 1,
			-itemtype         => 'text',
			-font             => 'TKFN',
			-columns          => 3,
			-indent           => 20,
			-padx             => 2,
			-background       => 'white',
			-selectforeground => 'brown',
			-selectbackground => 'cyan',
			-selectmode       => 'extended',
		)->pack(-fill =>'both',-expand => 'yes');
		$self->list->header('create',0,-text => Jcode->new('単語')->sjis);
		if ( $gui_window::word_search::katuyo ){
			$self->list->header('create',1,-text => Jcode->new('品詞/活用')->sjis);
		} else {
			$self->list->header('create',1,-text => Jcode->new('品詞')->sjis);
		}
		$self->list->header('create',2,-text => Jcode->new('頻度')->sjis);
	} else {
		$self->list->destroy;
		$self->{list} = $self->list_f->Scrolled(
			'HList',
			-scrollbars       => 'osoe',
			-header           => 1,
			-itemtype         => 'text',
			-font             => 'TKFN',
			-columns          => 4,
			-padx             => 2,
			-background       => 'white',
			-selectforeground => 'brown',
			-selectbackground => 'cyan',
			-selectmode       => 'extended',
		)->pack(-fill =>'both',-expand => 'yes');
		$self->list->header('create',0,-text => Jcode->new('単語')->sjis);
		$self->list->header('create',1,-text => Jcode->new('品詞（茶筌）')->sjis);
		$self->list->header('create',2,-text => Jcode->new('活用')->sjis);
		$self->list->header('create',3,-text => Jcode->new('頻度')->sjis);
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
	my $method;
	if ($gui_window::word_search::method =~ /^AND/){
		$method = 'AND';
	} else {
		$method = 'OR';
	}

	# 検索実行
	my $result = mysql_words->search(
		query  => $query,
		method => $method,
		kihon  => $gui_window::word_search::kihon,
		katuyo => $gui_window::word_search::katuyo
	);

	# 結果表示
	
	my $numb_style = $self->list->ItemStyle(
		'text',
		-anchor => 'e',
		-background => 'white'
	);
	
	$self->list->delete('all');
	my $row = 0;
	my $last;
	foreach my $i (@{$result}){
		my $cu;
		if ( $i->[0] eq 'katuyo' ){
			$cu = $self->list->addchild($last);
			shift @{$i};
		} else {
			$cu = $self->list->add($row,-at => "$row");
			$last = $cu;
		}
		my $col = 0;
		foreach my $h (@{$i}){
			if ($h =~ /[0-9]+/o){
				$self->list->itemCreate(
					$cu,
					$col,
					-text  => $h,
					-style => $numb_style
				);
			} else {
				$self->list->itemCreate($cu,$col,-text => nkf('-s -E',$h));
			}
			++$col;
		}
		++$row;
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
sub win_name{
	return 'w_word_search';
}
sub the_check{
	my $self = shift;
	return $self->{the_check};
}
sub list_f{
	my $self = shift;
	return $self->{list_f};
}

1;