package gui_window::word_conc;
use base qw(gui_window);
use vars qw($additional);
use strict;
use Tk;
use Tk::HList;
use mysql_conc;
use utf8;
use gui_widget::tani;
use gui_widget::optmenu;

#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	
	#my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};
	#$wmw->focus;
	$wmw->title($self->gui_jt( kh_msg->get('win_title') )); # 'KWICコンコーダンス'

	my $fra4 = $wmw->LabFrame(
		-label => 'Search Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');

	# エントリと検索ボタンのフレーム
	my $fra4e = $fra4->Frame()->pack(-expand => 'y', -fill => 'x');

	$fra4e->Label(
		-text => kh_msg->get('word'), #$self->gui_jchar('抽出語：'),
		-font => "TKFN"
	)->pack(-side => 'left');

#	my $e1 = $fra4e->Entry(
#		-font => "TKFN",
#		-background => 'white',
#		-width => 14
#	)->pack(-side => 'left');
#	$wmw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
#	$e1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e1]);
#	$e1->bind("<Key-Return>",sub{$self->search;});
#	$e1->bind("<KP_Enter>",sub{$self->search;});
#	$self->config_entry_focusin($e1);

	my @choices = ('');

	use Tk::MatchEntry_kh;

	$self->{match_entry} = $fra4e->MatchEntry(
		-textvariable => \$self->{entry_word},
		-width        => 14,
		-choices        => \@choices,
		-fixedwidth     => 0,
		-autosort       => 0,
		-complete       => 0,
		-ignorecase     => 1,
		-maxheight      => 20,
		   -entercmd       => sub { print "callback: -entercmd  \n"; }, 
		   -onecmd         => sub { $wmw->after(100, sub{$self->update_choices;}) },
		   -invcmd         => sub { $self->match_invoke; },
	)->pack(-side => 'left');

	my $e1 = $self->{match_entry}->Subwidget('entry');
	$e1->configure(
		-background => 'white',
		-font       => "TKFN",
	);

	sub match_invoke{
		my $self = shift;
		
		my $word;
		my $pos;
		if ( $self->{match_entry}{invoke} =~ /(.+)   <(.+)> [0-9]+/ ){
			$word = $1;
			$pos  = $2;
			
			$self->entry->delete(0,'end');
			$self->entry4->delete(0,'end');
			$self->entry2->delete(0,'end');
			$self->entry->insert('end', $word);
			$self->entry4->insert('end',$pos);
			
			$self->search;
		}
	}
	
	sub update_choices{
		my $self = shift;
		
		# get input char
		my $t = $self->check_entry_input( $self->entry->get );
		#print "update_choices: input: $t\n";
		
		if ( $self->{last_input} eq $t ){
			return;
		}
		if ( length($t) == 0 ){
			return;
		}
		$self->{last_input} = $t;
		
		# search for choices
		print "update_choices Searching... $t\n";
		my $sql = "
			SELECT genkei.name, hselection.name, genkei.num
			FROM genkei, hselection
			WHERE
				genkei.name like \"$t%\"
				AND genkei.nouse = 0
				AND genkei.khhinshi_id = hselection.khhinshi_id
				AND hselection.ifuse = 1
			ORDER BY
				genkei.num DESC
			LIMIT 100
		";
		
		my $h = mysql_exec->select($sql)->hundle;
		my @choices = ();
		while (my $i = $h->fetch){
			my $w = "$i->[0]   <$i->[1]> $i->[2]";
			#print "update_choices choice: $w\n";
			push @choices, $w;
		}
		
		# update choices
		$self->{match_entry}->close_listbox;
		$self->{match_entry}->choices(\@choices);
		$self->{match_entry}->popup;
		
		return $self;
	}



	$fra4e->Label(
		-text => kh_msg->get('pos'), #self->gui_jchar('　品詞：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	my $e4 = $fra4e->Entry(
		-font => "TKFN",
		-background => 'white',
		-width => 8
	)->pack(-side => 'left');
	$e4->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e4]);
	$e4->bind("<Key-Return>",sub{$self->search;});
	$e4->bind("<KP_Enter>",sub{$self->search;});
	$self->config_entry_focusin($e4);

	$fra4e->Label(
		-text => kh_msg->get('conj'),#$self->gui_jchar('　活用形：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	my $e2 = $fra4e->Entry(
		-font => "TKFN",
		-width => 8,
		-background => 'white'
	)->pack(-side => 'left');
	$e2->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e2]);
	$e2->bind("<Key-Return>",sub{$self->search;});
	$e2->bind("<KP_Enter>",sub{$self->search;});
	$self->config_entry_focusin($e2);

	$fra4e->Label(
		-text => $self->gui_jchar('    '),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{btn_tuika} = $fra4e->Button(
		-text => kh_msg->get('additional'), #$self->gui_jchar('追加条件'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ gui_window::word_conc_opt->open;}
	)->pack(-side => 'left');

	my $sbutton = $fra4e->Button(
		-text => kh_msg->get('search'), #$self->gui_jchar('検索'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->search;}
	)->pack(-side => 'right', -padx => '2');

	my $blhelp = $wmw->Balloon();
	$blhelp->attach(
		$sbutton,
		-balloonmsg => 'ENTER',
		-font => "TKFN"
	);

	# ソート・オプションのフレーム
	my $fra4h = $fra4->Frame->pack(-expand => 'y', -fill => 'x', -pady => 2);

	my @options = (
		[ kh_msg->get('ns'), 'id'], # $self->gui_jchar('出現順')
		[ kh_msg->get('l5'),  'l5'], # $self->gui_jchar('左・5')
		[ kh_msg->get('l4'),  'l4'], # $self->gui_jchar('左・4')
		[ kh_msg->get('l3'),  'l3'], # $self->gui_jchar('左・3')
		[ kh_msg->get('l2'),  'l2'], # $self->gui_jchar('左・2')
		[ kh_msg->get('l1'),  'l1'], # $self->gui_jchar('左・1')
		[ kh_msg->get('center'), 'center'], # $self->gui_jchar('活用形')
		[ kh_msg->get('r1'),  'r1'], # $self->gui_jchar('右・1')
		[ kh_msg->get('r2'),  'r2'], # $self->gui_jchar('右・2')
		[ kh_msg->get('r3'),  'r3'], # $self->gui_jchar('右・3')
		[ kh_msg->get('r4'),  'r4'], # $self->gui_jchar('右・4')
		[ kh_msg->get('r5'),  'r5'] # $self->gui_jchar('右・5')
	);

	$fra4h->Label(
		-text => kh_msg->get('sort1'), #$self->gui_jchar('ソート1：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{menu1} = gui_widget::optmenu->open(
		parent   => $fra4h,
		pack     => {-anchor=>'e', -side => 'left'},
		options  => \@options,
		variable => \$self->{sort1},
		width    => 6,
		command  => sub{$self->_menu_check;}
	);

	$fra4h->Label(
		-text => kh_msg->get('sort2'),#$self->gui_jchar('　ソート2：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{menu2} = gui_widget::optmenu->open(
		parent   => $fra4h,
		pack     => {-anchor=>'e', -side => 'left'},
		options  => \@options,
		variable => \$self->{sort2},
		width    => 6,
		command  => sub{$self->_menu_check;}
	);

	$fra4h->Label(
		-text => kh_msg->get('sort3'),#$self->gui_jchar('　ソート3：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{menu3} = gui_widget::optmenu->open(
		parent   => $fra4h,
		pack     => {-anchor=>'e', -side => 'left'},
		options  => \@options,
		variable => \$self->{sort3},
		width    => 6,
		command  => sub{$self->_menu_check;}
	);
	$self->_menu_check;


	$fra4h->Label(
		-text => kh_msg->get('retrieveNum1'),#$self->gui_jchar('　（前後'),
		-font => "TKFN"
	)->pack(-side => 'left');

	my $e3 = $fra4h->Entry(
		-width => 2,
		-background => 'white'
	)->pack(-side => 'left');
	$e3->insert('end','24');
	$self->config_entry_focusin($e3);

	$fra4h->Label(
		-text => kh_msg->get('retrieveNum2'),#$self->gui_jchar('語を表示）'),
		-font => "TKFN"
	)->pack(-side => 'left');


	my $status = $fra4h->Label(
		-text => 'Ready.',
		-foreground => 'blue'
	)->pack(-side => 'right');

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
		-background       => 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		-selectmode       => 'extended',
		-height           => 10,
		-command          => sub{$self->view_doc;}
	)->pack(-fill =>'both',-expand => 'yes');

	$self->{copy_btn} = $fra5->Button(
		-text => kh_msg->gget('copy'),#$self->gui_jchar('コピー'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub {gui_hlist->copy($self->list);}
	)->pack(-side => 'left',-anchor => 'w', -pady => 1, -padx => 2);

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{copy_btn}->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$self->{copy_btn},
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);

	$fra5->Button(
		-text => kh_msg->get('viewDoc'),#$self->gui_jchar('文書表示'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub {$self->view_doc;}
	)->pack(-side => 'left',-anchor => 'w', -pady => 1);

	$fra5->Label(
		-text => kh_msg->get('viewingUnit'),#$self->gui_jchar(' 表示単位：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	
	my %pack = (
		-side => 'left',
		-pady => 1
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $fra5,
		pack   => \%pack
	);

	$fra5->Label(
		-text => '  ',
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{btn_prev} = $fra5->Button(
		-text        => kh_msg->get('prev').mysql_conc->docs_per_once,#$self->gui_jchar('前'.mysql_conc->docs_per_once),
		-font        => "TKFN",
		-command     =>
			sub{
				my $start =
					$self->{current_start} - mysql_conc->docs_per_once;
				$self->display($start);
			},
		-borderwidth => 1,
		-state       => 'disable',
	)->pack(-side => 'left',-padx => 2);

	$self->{btn_next} = $fra5->Button(
		-text        => kh_msg->get('next').mysql_conc->docs_per_once,#$self->gui_jchar('次'.mysql_conc->docs_per_once),
		-font        => "TKFN",
		-command     =>
			sub{
				my $start =
					$self->{current_start} + mysql_conc->docs_per_once;
				$self->display($start);
			},
		-borderwidth => 1,
		-state       => 'disable',
	)->pack(-side => 'left');

	my $hits = $fra5->Label(
		-text => kh_msg->get('hits'),#$self->gui_jchar('  ヒット数：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{btn_coloc} = $fra5->Button(
		-text        => kh_msg->get('stats'),#$self->gui_jchar('集計'),
		-font        => "TKFN",
		-command     => sub{$self->coloc;},
		-borderwidth => 1,
		-state       => 'disable'
	)->pack(-side => 'right');

	$self->{btn_save} = $fra5->Button(
		-text        => kh_msg->gget('save'),#$self->gui_jchar('保存'),
		-font        => "TKFN",
		-command     => sub{$self->save;},
		-borderwidth => 1,
		-state       => 'disable'
	)->pack(-side => 'right',-padx => 2);

	# $self->{entry_limit} = $limit_e;
	$self->{st_label} = $status;
	$self->{hit_label} = $hits;
	$self->{list}     = $lis;
	#$self->{win_obj}  = $wmw;
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
		
		if ($self->sort($n) eq 'id'){
			$flag = 1;
		}
	}
}

sub btn_check{
	my $self = shift;
	
	if (
		   $gui_window::word_conc::additional->{1}{pos}
		#&& length($gui_window::word_conc::additional->{1}{query})
	){
		$self->{btn_tuika}->configure(-text => kh_msg->get('additional').'*'); # $self->gui_jchar('追加条件＊')
	} else {
		$self->{btn_tuika}->configure(-text => kh_msg->get('additional') );
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

	$selected = $self->{current_start} + $selected;
	my $foot = $self->{result_obj}->_count;
	$foot = kh_msg->get('currentDoc')."$selected / "."$foot,  "; #"・現在表示中の検索結果： 
	#print "foot: $foot\n";
	
	my $view_win = gui_window::doc_view->open;
	$view_win->view(
		hyosobun_id => $hyosobun_id,
		kyotyo      => \@kyotyo,
		tani        => "$tani",
		parent      => $self,
		head        => $foot,
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
	
	$selected = $self->{current_start} + $selected;
	my $foot = $self->{result_obj}->_count;
	$foot = kh_msg->get('currentDoc')."$selected / "."$foot,  ";

	return ($hyosobun_id,undef,undef,undef,$foot);
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
	
	$selected = $self->{current_start} + $selected;
	my $foot = $self->{result_obj}->_count;
	$foot = kh_msg->get('currentDoc')."$selected / "."$foot,  ";

	return ($hyosobun_id,undef,undef,undef,$foot);
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
	if ($::main_gui){
		$::main_gui->get('w_doc_view')->close
			if $::main_gui->if_opened('w_doc_view');
		$::main_gui->get('w_word_conc_coloc')->close
			if $::main_gui->if_opened('w_word_conc_coloc');
	}
}

#----------#
#   保存   #
#----------#

sub save{
	my $self = shift;
	
	# 保存先の参照
	my @types = (
		[ "csv file",[qw/.csv/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.csv',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt( kh_msg->get('saving')), # 'コンコーダンス（KWIC）検索の結果を保存'
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);
	
	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);
	
	$self->{result_obj}->save_all(
		path => $path,
	) if $path;
	
	return 1;
}

#----------#
#   集計   #
#----------#

sub coloc{
	my $self = shift;
	$self->{result_obj}->coloc;
	
	my $view_win = gui_window::word_conc_coloc->open;
	$view_win->view($self->{result_obj});
}

#----------#
#   検索   #
#----------#

sub search{
	my $self = shift;

	# 変数取得
	my $query = $self->entry->get;
	#unless ($query){
	#	return;
	#}
	my $katuyo = $self->entry2->get;
	my $hinshi = $self->entry4->get;
	my $length = gui_window->gui_jgn( $self->entry3->get );

	$query  = $self->check_entry_input($query );
	$katuyo = $self->check_entry_input($katuyo);
	$hinshi = $self->check_entry_input($hinshi);

	# 表示の初期化
	$self->hit_label->configure(
		-text => kh_msg->get('hits'),#$self->gui_jchar("  ヒット数：")
	);
	$self->list->delete('all');
	$self->{btn_prev}->configure(-state => 'disable');
	$self->{btn_next}->configure(-state => 'disable');
	$self->{btn_coloc}->configure(-state => 'disable');
	$self->{btn_save}->configure(-state => 'disable');
	$self->st_label->configure(
		-text => 'Searching...',
		-foreground => 'red',
	);
	$self->win_obj->update;

	# 検索実行
	use Benchmark;
	my $t0 = new Benchmark;

	# my ($result, $r_num)
	$self->{result_obj} = mysql_conc->a_word(
		query  => $query,
		katuyo => $katuyo,
		hinshi => $hinshi,
		tuika  => $gui_window::word_conc::additional,
		length => $length,
		sort1  => $self->sort1,
		sort2  => $self->sort2,
		sort3  => $self->sort3,
	);

	$self->st_label->configure(
		-text => 'Ready.',
		-foreground => 'blue',
	);

	$self->display(1);
	
	if (
		   defined( $::main_gui->{'w_word_conc_coloc'})
		&& Exists($::main_gui->{'w_word_conc_coloc'}->win_obj)
	){
		$self->win_obj->update;
		$self->{result_obj}->coloc if $self->{result_obj};
		$::main_gui->get('w_word_conc_coloc')->view($self->{result_obj});
	}
	
	my $t1 = new Benchmark;
	#print "Total: ",timestr(timediff($t1,$t0)),"\n";
	
	return $self;
}

#--------------#
#   結果表示   #
#--------------#

sub display{
	my $self = shift;
	my $start = shift;
	
	$self->{current_start} = $start;
	
	# HListの更新
	unless ($self->{result_obj}){
		return undef;
	}
	my $result = $self->{result_obj}->_format($start);
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
		-background => 'white',
		-padx => 5,
	);
	my $center_style = $self->list->ItemStyle(
		'text',
		-anchor => 'c',
		-font => "TKFN",
		-background => 'white',
		-foreground => 'red',
		-padx => 5,
	);
	my $left_style = $self->list->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'w',
		-background => 'white',
		-padx => 5,
	);
	
	my $row = 0;
	foreach my $i (@{$result}){
		$self->list->add($row,-at => "$row");
		$self->list->itemCreate(
			$row,
			0,
			-text  => $self->gui_jchar($i->[0]),
			-style => $right_style
		);
		my $center = $self->list->itemCreate(
			$row,
			1,
			-text  => $self->gui_jchar($i->[1]),
			-style => $center_style
		);
		$self->list->itemCreate(
			$row,
			2,
			-text  => $self->gui_jchar($i->[2]),
			-style => $left_style
		);
		++$row;
	}

	# ラベルの更新
	my $num_total = $self->{result_obj}->_count;
	my $num_disp  = $start + mysql_conc->docs_per_once - 1;
	my $num_disp2;
	if ($num_total > $num_disp){
		$num_disp2 = $num_disp;
	} else {
		$num_disp2 = $num_total;
	}
	if ($num_total == 0){$start = 0;}
	$self->hit_label->configure(
		-text => 
			 kh_msg->get('hits')
			."$num_total"
			.kh_msg->get('viewing')
			."$start".
			"-$num_disp2"
		);
	
	# ボタンの更新
	if ($start > 1){
		$self->{btn_prev}->configure(-state => 'normal');
	} else {
		$self->{btn_prev}->configure(-state => 'disable');
	}
	if ($num_total > $num_disp){
		$self->{btn_next}->configure(-state => 'normal');
	} else {
		$self->{btn_next}->configure(-state => 'disable');
	}
	$self->{btn_coloc}->configure(-state => 'normal');
	$self->{btn_save}->configure(-state => 'normal');
	$self->win_obj->update;

	# 表示のセンタリング
	$self->list->xview(moveto => 1);
	$self->list->yview(0);
	$self->win_obj->update;

	my $w_col0 = $self->list->columnWidth(0);
	my $w_col1 = $self->list->columnWidth(1);
	my $w_col2 = $self->list->columnWidth(2);

	my $xv;
	if ($Tk::version >= 8.4){
		$xv = $self->list->xview->[0];
	} else {
		$xv = $self->list->xview;
	}

	my $visible = ($w_col0 + $w_col1 + $w_col2 - $xv);
	my $v_center = int( $visible / 2);
	#print "$v_center\n";
	my $s_center = $w_col0 + ( $w_col1 / 2 );
	my $s_scroll = $s_center - $v_center;
	#print "s_scroll: $s_scroll\n";
	if ($s_scroll < 0){
		$self->list->xview(moveto => 0);
	} else {
		my $fragment = $s_scroll / ($w_col0 + $w_col1 + $w_col2);
		#print "fragment: $fragment\n";
		$self->list->xview(moveto => $fragment);
	}
	$self->list->yview(0);
	
	$self->{result} = $result;
	return $self;
}

#------------#
#   初期化   #
#------------#

sub start{
	my $self = shift;
	$gui_window::word_conc::additional = undef;
	mysql_conc->initialize;
	$self->entry->focus;

	$self->win_obj->bind(
		'<Key-Escape>',
		sub{
			#my $self = shift;
			print "escape pressed...\n";
			if ($self->{match_entry}->{popped}) {
				$self->{match_entry}->close_listbox;
			} else {
				$self->close;
			}
		}
	);	
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
