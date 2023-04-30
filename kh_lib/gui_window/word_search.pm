package gui_window::word_search;
use base qw(gui_window);
use vars qw($method $kihon $katuyo $filter);
use strict;
use utf8;
use Tk;
use Tk::Tree;
use Tk::ProgressBar;
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
	my $fra4e = $fra4->Frame()->pack(-expand => 'y', -fill => 'x', -padx => 2, -pady => 2);

	my $e1 = $fra4e->Entry(
		-font => "TKFN",
		-background => 'white',
		-width => 25,
	)->pack(-expand => 'y', -fill => 'x', -side => 'left');
	$wmw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e1]);
	$e1->bind("<Key-Return>",sub{return 0 if $self->{running}; $self->search;});
	$e1->bind("<KP_Enter>",sub{return 0 if $self->{running}; $self->search;});
	$self->config_entry_focusin($e1);

	$self->{btn_clear} = $fra4e->Button(
		-text => kh_msg->gget('clear'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{return 0 if $self->{running}; $self->clear;}
	)->pack(-side => 'right', -padx => '2');

	my $sbutton = $fra4e->Button(
		-text => kh_msg->get('search'),#$self->gui_jchar('検索'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{return 0 if $self->{running}; $self->search;}
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
	
	my $fra4i = $fra4->Frame->pack(-expand => 'y', -fill => 'x', -padx => 2, -pady => 4);

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

	$self->{filter_button} = $fra4i->Button(
		-text => kh_msg->get('gui_window::word_ass->filter'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ gui_window::word_search_opt->open; }
	)->pack(-anchor=>'e', -side => 'left', -padx => 2);

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
			-columns          => 5,
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
			-width            => 48,
			-browsecmd        => sub {$self->_unselect;},
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => '#');
	$lis->header('create',1,-text => kh_msg->get('word')); # $self->gui_jchar('抽出語')
	$lis->header('create',2,-text => kh_msg->get('pos_conj')); # $self->gui_jchar('品詞')
	$lis->header('create',3,-text => kh_msg->get('freq')); # $self->gui_jchar('頻度')

	$self->{list_f} = $hlist_fra;
	$self->{list}  = $lis;

	#$self->{copy_btn} = $fra5->Button(
	#	-text => kh_msg->gget('copy_all'),
	#	-font => "TKFN",
	#	-borderwidth => '1',
	#	-command => sub {$self->copy_all;}
	#)->pack(-side => 'right');

	$self->{copy_btn} = $fra5->Button(
		-text => kh_msg->get('excel'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { gui_window::word_list->open; }
	)->pack(-side => 'right');

	$self->{show_bars} = $::config_obj->show_bars_wordlist;
	$fra5->Checkbutton(
		-variable => \$self->{show_bars},
		-text     => kh_msg->get('show_bars'),
		-command  => sub {
			$::config_obj->show_bars_wordlist($self->{show_bars});
			return 0 if $self->{running};
			$self->search;
		},
	)->pack(-anchor => 'w', -side => 'left');

	$fra5->Label(
		-text     => ' ',
	)->pack(-anchor => 'w', -side => 'left');

	$fra5->Checkbutton(
		-variable => \$self->{enable_filter},
		-text     => kh_msg->get('enable_filter'),
		-command  => sub{
			return 0 if $self->{running};
			$self->search;
		},
	)->pack(-anchor => 'w', -side => 'left');

	$fra5->Label(
		-text     => ' ',
	)->pack(-anchor => 'w', -side => 'left');

	$self->{button_p100} = $fra5->Button(
		-text => kh_msg->get('p100'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $self->display( $self->{start} - 100 ); }
	)->pack(-anchor => 'w', -side => 'left');

	$self->{button_n100} = $fra5->Button(
		-text => kh_msg->get('n100'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $self->display( $self->{start} + 100 ); }
	)->pack(-anchor => 'w', -side => 'left');

	#SCREEN Plugin
	use screen_code::word_cloud;
	&screen_code::word_cloud::add_button_wordcloud($self,$wmw,$fra5);
	#SCREEN Plugin
	
	
	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->copy_all; }
	);
	
	$self->win_obj->bind(
		'<Control-Key-z>',
		sub{ $self->speed_test; }
	);
	
	#$self->win_obj->Balloon()->attach(
	#	$self->{copy_btn},
	#	-balloonmsg => 'Ctrl + C',
	#	-font => "TKFN"
	#);

	#--------------------------#
	#   initialise POS stats   #
	
	# 全体と比較するよりも、画面上のほかの語と比較する方が効果的だった…
	$self->{morpho_analyzer} = $::project_obj->morpho_analyzer;
	if (0) {
		my $pos;
		my $pos_list;
		my $h = mysql_exec->select("
			SELECT khhinshi.name, katuyo.name, count(*)
			FROM katuyo, hyoso, genkei, khhinshi
			WHERE 
			  hyoso.katuyo_id = katuyo.id
			  AND hyoso.genkei_id = genkei.id
			  AND genkei.khhinshi_id = khhinshi.id
			GROUP BY katuyo.id, khhinshi.id
			ORDER BY khhinshi_id
		")->hundle;
		
		while (my $i = $h->fetch){
			my $name = $i->[1];
			
			# Heuristic for ChaSen & IPADic: See 2 first chars only
			$name = substr($name, 0, 2) if $self->{morpho_analyzer} eq 'chasen';
			
			push @{$pos_list->{$i->[0]}}, $name unless defined($pos->{$i->[0]}{$name});
			$pos->{$i->[0]}{$name} += $i->[2];
		}
		$self->{pos} = $pos;
		$self->{pos_list} = $pos_list;
	}
	
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

sub clear{
	my $self = shift;
	$self->entry->delete(0, 'end');
	
	$self->search;
	return $self;
}

sub speed_test{ # Ctrl + Z
	my $self = shift;
	
	use Benchmark;
	my $t0 = new Benchmark;
	
	for (my $n = 0; $n < 5; ++$n){
		# 1
		$self->entry->delete(0, 'end');
		$self->entry->insert(0, '生');
		$self->search;
		$self->clear;
	
		# 2
		$self->entry->delete(0, 'end');
		$self->entry->insert(0, '死　殺　亡');
		$self->search;
		$self->clear;
		
		# 3
		$self->entry->delete(0, 'end');
		$self->entry->insert(0, '先');
		$self->search;
		$self->clear;
		
		# 4
		$self->entry->delete(0, 'end');
		$self->entry->insert(0, '友');
		$self->search;
		$self->clear;
		
		# 5
		$self->entry->delete(0, 'end');
		$self->entry->insert(0, '男　女');
		$self->search;
		$self->clear;
	}

	my $t1 = new Benchmark;
	print timestr(timediff($t1,$t0)),"\n";
	
	return $self;
}


#----------#
#   検索   #
#----------#

my $debug = 0;

sub search{
	my $self = shift;
	
	$self->{running} = 1;
	#print "search!\n";
	
	# 変数取得
	my $query = $self->gui_jg( $self->entry->get );

	if ( length( $query ) && $self->{enable_filter} == 0 ){
		$self->{filter_button}->configure(-state => 'disabled');
	} else {
		$self->{filter_button}->configure(-state => 'normal');
	}

	# 検索実行
	print "search..." if $debug;
	$self->{result} = mysql_words->search(
		query         => $query,
		method        => $gui_window::word_search::method,
		kihon         => $gui_window::word_search::kihon,
		katuyo        => $gui_window::word_search::katuyo,
		mode          => $gui_window::word_search::s_mode,
		filter        => $filter,
		enable_filter => $self->{enable_filter},
	);
	print "ok   " if $debug;
	
	$self->display(0);
	return $self;
}

sub display{
	my $self = shift;
	my $start = shift;
	$self->{start} = $start;
	
	print "ready..." if $debug;
	
	# update P & N buttons
	if ($self->{start} == 0) {
		$self->{button_p100}->configure(-state => "disabled");
	} else {
		$self->{button_p100}->configure(-state => "normal");
	}
	if ($self->{result}->search_hits > $self->{start} + 100 ) {
		$self->{button_n100}->configure(-state => "normal");
	} else {
		$self->{button_n100}->configure(-state => "disabled");
	}
	
	my $result = $self->{result}->fetch($start);
	
	# POS check 1st pass
	if (0) {
	
	my $n = 0;
	my $flg_katuyo = 0;
	my $current;
	my $last;
	my $pos_num;
	my $pos_list;
	foreach my $i (@{$result}){
		if ($i->[0] eq 'katuyo') {
			if ($flg_katuyo == 0) {
				$current->{posname} = $last->[1];
				$flg_katuyo = 1;
			}
			my $name = $i->[2];
			$name = substr($name, 0, 2) if $self->{morpho_analyzer} eq 'chasen';
			
			push @{$pos_list->{$current->{posname}}}, $name
				unless defined( $pos_num->{$current->{posname}}{$name} );
			$pos_num->{$current->{posname}}{$name} += $i->[3];
			
		}
		
		if ( ($flg_katuyo == 1) &! ($i->[0] eq 'katuyo') ) {
			$flg_katuyo = 0;
			$current->{posname} = '';
		}
		
		$last = $i;
		++$n;
	}
	
	$self->{pos_list} = $pos_list;
	$self->{pos} = $pos_num;
	
	
	# POS check 2nd pass
	use Statistics::ChisqIndep;
	my $chi = new Statistics::ChisqIndep;
	
	$n = 0;
	$flg_katuyo = 0;
	$current = undef;
	$last = undef;
	my $pos_chk;
	my %have_child;
	foreach my $i (@{$result}){
		if ($i->[0] eq 'katuyo') {
			if ($flg_katuyo == 0) {
				$current->{mother}  = $n - 1;
				$current->{posname} = $last->[1];
				$current->{word}    = $last->[0];
				$have_child{$current->{mother}} = 1;
				$flg_katuyo = 1;
			}
			
			my $name = $i->[2];
			$name = substr($name, 0, 2) if $self->{morpho_analyzer} eq 'chasen';
			$current->{pos}{$name} += $i->[3];
		}
		
		if ( ($flg_katuyo == 1) &! ($i->[0] eq 'katuyo') ) {
			# check distribution
			my @data;
			foreach my $h ( @{$self->{pos_list}{$current->{posname}}} ){
				my $num = 0;
				if ( defined($current->{pos}{$h}) ){
					$num = $current->{pos}{$h};
				}
				push @{$data[1]}, $num;
				push @{$data[0]}, $self->{pos}{$current->{posname}}{$h} - $num;
			}

			$chi->load_data(\@data);
			my $v = 0;
			$v = sqrt( $chi->{chisq_statistic} / $chi->{total} ) if $chi->{total};
			if ($v >= 0.1 && $chi->{p_value} < 0.01) {
				#$pos_chk->{$current->{mother}} = 1;
				
				# check residuals
				my $cols = @{$data[1]};
				for (my $j = 0; $j <= $cols; ++$j){
					my $rsd = 0;
					$rsd = ( $chi->{obs}[1][$j] - $chi->{expected}[1][$j] )
						/ sqrt( $chi->{expected}[1][$j] ) if $chi->{expected}[1][$j];
					if ($rsd >= 3.291) {
						$pos_chk->{$current->{mother}}->{$self->{pos_list}{"$current->{posname}"}[$j]} = 1;
					}
				}
			
			}
			
			$current = undef;
			$flg_katuyo = 0;
		}
		
		
		$last = $i;
		++$n;
	}
	}
	
	# No POS check
	my $n = 0;
	my $flg_katuyo = 0;
	my %have_child;
	foreach my $i (@{$result}){
		if ($i->[0] eq 'katuyo') {
			if ($flg_katuyo == 0) {
				my $nn = $n -1;
				$have_child{$nn} = 1;
				$flg_katuyo = 1;
			}
		}
		if ( ($flg_katuyo == 1) &! ($i->[0] eq 'katuyo') ) {
			$flg_katuyo = 0;
		}
		++$n;
	}
	
	print "ok   ";
	print "print..." if $debug;
	
	# display the result # it takes too much time!!!
	
	$self->list->destroy;
	my $lis = $self->{list_f}->Scrolled(
			'Tree',
			-scrollbars       => 'osoe',
			-header           => 1,
			-itemtype         => 'text',
			-font             => 'TKFN',
			-columns          => 5,
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
			-width            => 48,
			-browsecmd        => sub {$self->_unselect;},
	)->pack(-fill =>'both',-expand => 'yes');

	$lis->header('create',0,-text => '#');
	$lis->header('create',1,-text => kh_msg->get('word')); # $self->gui_jchar('抽出語')
	$lis->header('create',2,-text => kh_msg->get('pos_conj')); # $self->gui_jchar('品詞')
	$lis->header('create',3,-text => kh_msg->get('freq')); # $self->gui_jchar('頻度')
	$self->{list}  = $lis;
	
	print "," if $debug;

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
	
	my $leftu = $self->list->ItemStyle(
		'window',
		-anchor => 'nw',
		-pady => 0,
		-padx => 0,
	);
	
	my $row = 0;
	my $num = 1 + $start;
	my $last = undef;
	my $child_flag = 0;
	# my $pos_flag = 0;
	my $max = $result->[0][2];
	foreach my $i (@{$result}){
		my $cu;
		my $col = 0;
		
		# not sure why we need this...
		my $chk = @{$i};
		next unless $chk;
		
		# children (conjugated)
		if ( $i->[0] eq 'katuyo' ){
			$cu = $self->list->addchild($last);
			#shift @{$i};
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
			
			#if ( $have_child{$row} && $pos_chk->{$row} ){
			#	$pos_flag = $row;
			#} else {
			#	$pos_flag = -1;
			#}
			
			if ($have_child{$row}) {
			#if (0) {
			
				my $color = "#007b43";
				##$color = "#ea5506" if $pos_chk->{$row}; # temporarily hiding the new feature
				
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
					#-text => $num,
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
			if ($col == 1 && $h eq 'katuyo'){
				next;
			}
			
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
					##if ($col == 2 && $child_flag && $pos_flag > -1) {
					##	my $name = $h;
					##	$name = substr($name, 0, 2) if $self->{morpho_analyzer} eq 'chasen';
					##	if ($pos_chk->{$pos_flag}{$name}) {
					##		$h .= " !";
					##	}
					##}
					
					# clickable text
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
		
		# bar graph
		if ( $self->{show_bars} ){
			my $nbar;
			my $bar_col;
			if ($child_flag){
				$nbar = $i->[3];
				$bar_col = '#cee4ae';
			} else {
				$nbar = $i->[2];
				$bar_col = '#89c3eb';
			}
			
			# 多すぎるとPerlが落ちるので、活用形についてはグラフ非表示
			unless ( $child_flag ){
				my $bv = 0;
				my $b = $self->list->ProgressBar(
					-troughcolor => 'white',
					-colors => [ 0, $bar_col ],
					-gap => 0,
					-length => 150,
					-padx => 7,
					-pady => 2,
					-variable => \$bv,
					#-value => $nbar / $max * 100,
				);
				#print $row, ', ', $nbar / $max * 100, "\n";
				$bv = $nbar / $max * 100;
				#$bv = 3;
				#$b->value( $nbar / $max * 100 );
				$self->list->itemCreate(
					$cu,
					$col,
					-itemtype => 'window',
					-widget => $b,
					-style => $leftu,
				);
			}
		}
		
		$self->list->hide('entry', $cu) if $child_flag;
		++$row;
	}
	print "." if $debug;
	$self->{last_search} = $result;
	$self->{list_entry_mode} = undef;
	$self->list->autosetmode();
	
	gui_hlist->update4scroll($self->list);
	use Time::HiRes;
	sleep (0.01);
	$self->{running} = 0;
	print "ok\n" if $debug;

	return 1;
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

sub copy_all{
	my $self = shift;
	
	return 0 unless $self->{last_search};
	
	my $t = '';
	my $r = 0;
	foreach my $i (@{$self->{last_search}}){
		my $c = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $c;
			if ($h eq 'katuyo' && $c == 0){
				#print "katuyo!";
			} else {
				$t .= "$h";
			}
			++$c;
		}
		$t .= "\n";
	}
	
	use kh_clipboard;
	kh_clipboard->string($t);
	return $t;
}

#----------------------------#
#   Open KWIC Concordance   #

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
		$katuyo = $self->gui_jchar($result->[$parent + $child + 1][2]);
		#substr($katuyo,0,3) = '';
	} else {
		$query = $self->gui_jchar($result->[$selected][0]);
		$hinshi = $self->gui_jchar($result->[$selected][1]);
	}
	if ( length($katuyo) && $katuyo =~ /(.+) !$/ ){
		$katuyo = $1;
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
	
	$self->{win_obj}->focus unless $::config_obj->os eq 'win32';
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

sub start{
	my $self = shift;
	$self->entry->focus;
}

1;
