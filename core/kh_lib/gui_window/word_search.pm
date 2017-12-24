package gui_window::word_search;
use base qw(gui_window);
use vars qw($method $kihon $katuyo $filter);
use strict;
use utf8;
use Tk;
use Tk::Tree;
use Tk::Balloon;

use mysql_words;
use gui_widget::optmenu;

#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};
	#$wmw->focus;
	$wmw->title($self->gui_jt( kh_msg->get('win_title') )); # '抽出語検索'

	my $fra4 = $wmw->LabFrame(
		-label => 'Filter Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');

	# エントリと検索ボタンのフレーム
	my $fra4e = $fra4->Frame()->pack(-expand => 'y', -fill => 'x');

	my $e1 = $fra4e->Entry(
		-font => "TKFN",
		-background => 'white',
		-width => 25,
	)->pack(-expand => 'y', -fill => 'x', -side => 'left');
	$wmw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e1]);
	$e1->bind("<Key-Return>",sub{$self->search;});
	$e1->bind("<KP_Enter>",sub{$self->search;});
	$self->config_entry_focusin($e1);

	my $sbutton = $fra4e->Button(
		-text => kh_msg->get('search'),#$self->gui_jchar('検索'),
		-font => "TKFN",
		-command => sub{$self->search;}
	)->pack(-side => 'right', -padx => '2');

	my $blhelp = $wmw->Balloon();
	$blhelp->attach(
		$sbutton,
		-balloonmsg => '"ENTER" key',
		-font => "TKFN"
	);

	# オプション・フレーム
	#my $fra4h = $fra4->Frame->pack(-expand => 'y', -fill => 'x');

	#$fra4h->Checkbutton(
	#	-text     => kh_msg->get('baseform'),#$self->gui_jchar('抽出語検索'),
	#	-variable => \$gui_window::word_search::kihon,
	#	-font     => "TKFN",
	#	-command  => sub{$self->refresh; $self->search;}
	#)->pack(-side => 'left');

	#$self->{the_check} = $fra4h->Checkbutton(
	#	-text     => kh_msg->get('view_conj'),#$self->gui_jchar('活用形を表示'),
	#	-variable => \$gui_window::word_search::katuyo,
	#	-font     => "TKFN",
	#	-command  => sub{$self->refresh; $self->search;}
	#)->pack(-side => 'left');

	unless (defined($gui_window::word_search::katuyo)){
		$gui_window::word_search::kihon = 1;
		$gui_window::word_search::katuyo = 1;
	}
	
	my $fra4i = $fra4->Frame->pack(-expand => 'y', -fill => 'x', -padx => 2, -pady => 2);

	$self->{optmenu_andor} = gui_widget::optmenu->open(
		parent  => $fra4i,
		pack    => {-anchor=>'e', -side => 'left', -padx => 2},
		#width   => 7,
		options =>
			[
				[kh_msg->get('or') , 'OR'], # $self->gui_jchar('OR検索')
				[kh_msg->get('and'), 'AND'], # $self->gui_jchar('AND検索')
			],
		variable => \$gui_window::word_search::method,
		command => sub{$self->search;},
	);

	$self->{optmenu_bk} = gui_widget::optmenu->open(
		parent  => $fra4i,
		pack    => {-anchor=>'e', -side => 'left', -padx => 12},
		#width   => 8,
		options =>
			[
				[kh_msg->get('part') => 'p'], # $self->gui_jchar('部分一致')
				[kh_msg->get('comp') => 'c'], # $self->gui_jchar('完全一致')
				[kh_msg->get('forw') => 'z'], # $self->gui_jchar('前方一致')
				[kh_msg->get('back') => 'k'] #$self->gui_jchar('後方一致')
			],
		variable => \$gui_window::word_search::s_mode,
		command => sub{$self->search;},
	);


	# 結果表示部分
	my $fra5 = $wmw->LabFrame(
		-label => 'List',
		-labelside => 'acrosstop',
		-borderwidth => 2
	)->pack(-expand=>'yes',-fill=>'both');

	my $hlist_fra = $fra5->Frame()->pack(-expand => 'y', -fill => 'both');

	my $lis = $hlist_fra->Scrolled(
			'Tree',
			-scrollbars       => 'osoe',
			-header           => 1,
			-itemtype         => 'text',
			-font             => 'TKFN',
			-columns          => 4,
			-indent           => 20,
			-padx             => 7,
			-background       => 'white',
			-highlightcolor   => 'white',
			#-selectforeground   => "",#$::config_obj->color_ListHL_fore,
			-selectbackground   => 'white',#$::config_obj->color_ListHL_back,
			-selectborderwidth  => 0,
			-highlightthickness => 0,
			-selectmode       => 'none',
			-command          => sub {$self->conc;},
			-height           => 20,
			-width            => 36,
			-browsecmd        => sub {$self->_unselect;},
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => '#');
	$lis->header('create',1,-text => kh_msg->get('word')); # $self->gui_jchar('抽出語')
	$lis->header('create',2,-text => kh_msg->get('pos_conj')); # $self->gui_jchar('品詞')
	$lis->header('create',3,-text => kh_msg->get('freq')); # $self->gui_jchar('頻度')

	$self->{copy_btn} = $fra5->Button(
		-text => kh_msg->gget('copy'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {gui_hlist->copy($self->list);}
	)->pack(-side => 'right');

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{copy_btn}->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$self->{copy_btn},
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);

	$self->{conc_button} = $fra5->Button(
		-text => kh_msg->get('kwic'),#$self->gui_jchar('コンコーダンス'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {$self->conc;}
	)->pack(-side => 'left');
	
	#---------------------------#
	#   initialise word filer   #

	$filter = undef;
	$filter->{limit}   = 100;                  # LIMIT number
	my $h = mysql_exec->select("
		SELECT name, khhinshi_id
		FROM   hselection
		WHERE  ifuse = 1
	",1)->hundle;
	while (my $i = $h->fetch){                 # Filter by POS
		if (
			   $i->[0] =~ /B$/
			|| $i->[0] eq '否定助動詞'
			|| $i->[0] eq '形容詞（非自立）'
		){
			$filter->{hinshi}{$i->[1]} = 0;
		} else {
			$filter->{hinshi}{$i->[1]} = 1;
		}
	}
	
	$self->{list_f} = $hlist_fra;
	$self->{list}  = $lis;
	#$self->{win_obj} = $wmw;
	$self->{entry}   = $e1;
	#$self->refresh;
	$self->search;
	return $self;
}

sub _unselect{
	my $self = shift;

	$self->list->anchorClear;
	return 1;

}


#----------#
#   検索   #
#----------#

sub search{
	my $self = shift;
	
	# 変数取得
	my $query = $self->gui_jg( $self->entry->get );

	#unless ($query){
	#	return;
	#}

	# 検索実行
	my $result = mysql_words->search(
		query  => $query,
		method => $gui_window::word_search::method,
		kihon  => $gui_window::word_search::kihon,
		katuyo => $gui_window::word_search::katuyo,
		mode   => $gui_window::word_search::s_mode,
		filter => $filter
	);

	# check the result
	my %have_child;
	my $row = 0;
	my $last_parent = -1;
	foreach my $i ( @{$result} ){
		if ( $i->[0] eq 'katuyo' ){
			$have_child{$last_parent} = 1;
			#print "have_child: $last_parent\n";
		} else {
			$last_parent = $row;
		}
		++$row;
	}
	
	# display the result
	my $numb_style = $self->list->ItemStyle(
		'text',
		-anchor => 'e',
		-background => 'white',
		-font => "TKFN"
	);
	
	my $numb_style_g = $self->list->ItemStyle(
		'text',
		-anchor => 'e',
		-background => 'white',
		-foreground => '#696969',
		-selectforeground => '#696969',
		-font => "TKFN"
	);
	
	my $left = $self->list->ItemStyle(
		'window',
		-anchor => 'w',
		-pady => 0,
		-padx => 5,
	);
	
	$self->list->delete('all');
	$row = 0;
	my $num = 1;
	my $last;
	my $child_flag = 0;
	foreach my $i (@{$result}){
		my $cu;
		my $col = 0;
		
		# children (conjugated)
		if ( $i->[0] eq 'katuyo' ){
			$cu = $self->list->addchild($last);
			shift @{$i};
			++$child_flag;
			$self->list->itemCreate(
				$cu,
				$col,
				-text  => ' ',
				#-style => $numb_style
			);
		
		# parents (base form)
		} else {
			$cu = $self->list->add($row,-at => "$row");
			$last = $cu;
			$child_flag = 0;
			
			if ($have_child{$row}) {
				my $color = "#007b43";
				my $c = $self->list->Label(
					-text => $num,
					-font       => "TKFN",
					-foreground => $color,
					-activeforeground => $color,
					-anchor     => 'w',
					-background => 'white',
					-pady       => 0,
					-activebackground => $::config_obj->color_ListHL_back,
				);
				my $r = $row;
				$c->bind(
					"<Button-1>",
					sub {
						$self->show_children($r);
					}
				);
				$c->bind(
					"<Enter>",
					sub {
						$c->configure(-foreground => 'red',-activeforeground => 'red');
					}
				);
				$c->bind(
					"<Leave>",
					sub {
						$c->configure(-foreground => $color,-activeforeground => $color);
					}
				);
				$self->list->itemCreate(
					$cu,
					$col,
					-itemtype => 'window',
					-widget => $c,
					-style => $left,
				);
			} else {
				
				my $c = $self->list->Label(
					-text => $num,
					-font       => "TKFN",
					-foreground => "black",
					-activeforeground => "black",
					-anchor     => 'w',
					-background => 'white',
					-pady       => 0,
					-activebackground => $::config_obj->color_ListHL_back,
				);
				
				$self->list->itemCreate(
					$cu,
					$col,
					-itemtype => 'window',
					-widget => $c,
					-style => $left,
				);
			}
			
			++$num;
		}
		++$col;
		
		foreach my $h (@{$i}){
			# numbers
			if ($h =~ /^[0-9]+$/o && $col > 0){
				my $s;
				if ($child_flag){
					$s = $numb_style_g;
				} else {
					$s = $numb_style;
				}
				
				$self->list->itemCreate(
					$cu,
					$col,
					-text  => $h,
					-style => $s
				);
			# text
			} else {
				# clickable text (KWIC)
				if (
					   ( $col == 1 && $child_flag == 0 )
					|| ( $col == 2 && $child_flag )
				){
					my $c = $self->list->Label(
						-text => $h,
						-font       => "TKFN",
						-foreground => 'blue',
						-activeforeground => 'blue',
						#-cursor     => 'hand2',
						-anchor     => 'w',
						-background => 'white',
						-pady       => 0,
						-activebackground => $::config_obj->color_ListHL_back,
					);
					my $r;
					if ($child_flag == 0){
						$r = $row;
					} else {
						my $c = $child_flag - 1;
						$r = "$last.$c";
					}
					$c->bind(
						"<Button-1>",
						sub {
							$self->conc($r);
						}
					);
					$c->bind(
						"<Enter>",
						sub {
							$c->configure(-foreground => 'red',-activeforeground => 'red');
						}
					);
					$c->bind(
						"<Leave>",
						sub {
							$c->configure(-foreground => 'blue',-activeforeground => 'blue');
						}
					);
					$self->list->itemCreate(
						$cu,
						$col,
						-itemtype => 'window',
						-widget => $c,
						-style => $left,
					);
				# normal text
				} else {
					my $t = '';
					$t .= '   ' if $child_flag;
					$t .= $h;
					$self->list->itemCreate($cu,$col,-text => $t);
				}
			}
			++$col;
		}
		$self->list->hide('entry', $cu) if $child_flag;
		++$row;
	}
	$self->{last_search} = $result;
	$self->{list_entry_mode} = undef;
	$self->list->autosetmode();
	
	gui_hlist->update4scroll($self->list);
}

sub show_children{
	my $self = shift;
	my $n = shift;
	
	my @children = $self->list->info('children', $n);
	
	if ($self->{list_entry_mode}{$n}) {
		foreach my $i (@children){
			$self->list->hide('entry', $i);
		}
		$self->{list_entry_mode}{$n} = 0;
	} else {
		foreach my $i (@children){
			$self->list->show('entry', $i);
		}
		$self->{list_entry_mode}{$n} = 1;
	}

	$self->list->autosetmode();
}


#----------------------------#
#   コンコーダンス呼び出し   #
#----------------------------#
sub conc{
	use gui_window::word_conc;
	my $self = shift;
	unless ($gui_window::word_search::kihon){
		return 0;
	}
	
	# 変数取得
	my $selected = shift;
	unless ( defined($selected) ){
		my @selected = $self->list->infoSelection;
		unless(@selected){
			return;
		}
		$selected = $selected[0];
	}

	my $result = $self->last_search;
	my ($query, $hinshi, $katuyo);
	if (index($selected,'.') > 0){
		my ($parent, $child) = split /\./, $selected;
		$query = $self->gui_jchar($result->[$parent][0]);
		$hinshi = $self->gui_jchar($result->[$parent][1]);
		$katuyo = $self->gui_jchar($result->[$parent + $child + 1][1]);
		#substr($katuyo,0,3) = '';
	} else {
		$query = $self->gui_jchar($result->[$selected][0]);
		$hinshi = $self->gui_jchar($result->[$selected][1]);
	}

	# コンコーダンスの呼び出し
	my $conc = gui_window::word_conc->open;
	$conc->entry->delete(0,'end');
	$conc->entry4->delete(0,'end');
	$conc->entry2->delete(0,'end');
	$conc->entry->insert('end',$query);
	$conc->entry4->insert('end',$hinshi);
	$conc->entry2->insert('end',$katuyo);
	$conc->search;
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
sub last_search{
	my $self = shift;
	return $self->{last_search};
}
sub conc_button{
	my $self = shift;
	return $self->{conc_button};
}
sub start{
	my $self = shift;
	$self->entry->focus;
}

1;
