package gui_window::word_search;
use base qw(gui_window);
use vars qw($method);
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

	my $fra4h = $fra4->Frame->pack(-expand => 1, -fill => 'x');
	my $fra4hr = $fra4h->Frame->pack(-expand => 1, -fill => 'x',-side => 'right');
	my $fra4hl = $fra4h->Frame->pack(-expand => 1, -fill => 'x',-side => 'left');

	$fra4hl->Label(
		-text => Jcode->new('・検索対象文字列の入力')->sjis,
		-font => "TKFN"
	)->pack(-anchor=>'w');

	$fra4hl->Label(
		-text => Jcode->new('　(複数の場合はスペースで区切る)　')->sjis,
		-font => "TKFN"
	)->pack(-anchor=>'w');

	my @methods;
	push @methods, Jcode->new('AND検索')->sjis;
	push @methods, Jcode->new('OR検索')->sjis;
	my $method;
	$fra4hr->Optionmenu(
		-options=> \@methods,
		-font => "TKFN",
		-variable => \$gui_window::word_search::method,
	)->pack(-anchor=>'e', -side => 'right');

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
	)->pack(-side => 'right');

	my $blhelp = $wmw->Balloon();
	$blhelp->attach(
		$sbutton,
		-balloonmsg => '"Shift + ENTER" key',
		-font => "TKFN"
	);



	my $fra5 = $wmw->LabFrame(
		-label => 'Result',
		-labelside => 'acrosstop',
		-borderwidth => 2
	)->pack(-expand=>'yes',-fill=>'both');

	my $lis = $fra5->Scrolled(
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

	$self->{list}  = $lis;
	$self->{win_obj} = $wmw;
	$self->{entry}   = $e1;
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
	);

	# 結果表示
	
	my $numb_style = $self->list->ItemStyle(
		'text',
		-anchor => 'e',
		-background => 'white'
	);
	
	$self->list->delete('all');
	my $row = 0;
	foreach my $i (@{$result}){
		$self->list->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			if ($col == 2){
				$self->list->itemCreate(
					$row,
					$col,
					-text  => $h,
					-style => $numb_style
				);
			} else {
				$self->list->itemCreate($row,$col,-text => nkf('-s -E',$h));
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

1;