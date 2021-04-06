package gui_window::topic_result;
use base qw(gui_window);

use strict;
use utf8;
use Jcode;
use List::Util qw(max sum);

my $debug_ms = 0;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;

	my %args = @_;
	foreach my $i (keys %args){
		$self->{$i} = $args{$i};
	}

	my $win = $self->{win_obj};
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # 学習結果ファイル：

	#------------------#
	#   全体的な情報   #

	my $lf = $win->LabFrame(
		-label => 'Info',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');


	$lf->Label(
		-text => kh_msg->get('gui_widget::words->unit'), # 単位：
	)->pack(-side => 'left');

	$self->{entry_unit} = $lf->Entry(
		-width => 3,
	)->pack(-side => 'left',-fill => 'x', -expand => 1);

	$lf->Label(-text => '  ')->pack(-side => 'left');
	$lf->Label(
		-text => kh_msg->get('gui_window::topic_fitting->n_topics'), # トピック数：
	)->pack(-side => 'left');

	$self->{entry_n_topics} = $lf->Entry(
		-width => 3,
	)->pack(-side => 'left',-fill => 'x', -expand => 1);

	$lf->Label(-text => ' ')->pack(-side => 'left');
	$lf->Label(
		-text => kh_msg->get('gui_window::bayes_view_knb->n_types'), # 語数：
	)->pack(-side => 'left');

	$self->{entry_n_words} = $lf->Entry(
		-width => 3,
	)->pack(-side => 'left',-fill => 'x', -expand => 1);

	my $unit_label = $args{tani};
	if ( $unit_label eq 'dan' ){
		$unit_label = kh_msg->gget('paragraph'),
	}
	elsif ( $unit_label eq 'bun' ){
		$unit_label = kh_msg->gget('sentence'),
	}

	$self->{entry_unit}    ->insert(0, $unit_label      );
	$self->{entry_n_topics}->insert(0, $args{n_topics}  );
	$self->{entry_n_words} ->insert(0, $args{used_words});

	gui_window->disabled_entry_configure( $self->{entry_unit}     );
	gui_window->disabled_entry_configure( $self->{entry_n_topics} );
	gui_window->disabled_entry_configure( $self->{entry_n_words}  );

	$self->{entry_unit}    ->configure(-state => 'disable');
	$self->{entry_n_topics}->configure(-state => 'disable');
	$self->{entry_n_words} ->configure(-state => 'disable');


	my $lf1 = $win->LabFrame(
		-label => 'Topics',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	$self->{list_flame} = $lf1->Frame()->pack(-fill => 'both', -expand => 1);

	#------------------#
	#   操作ボタン類   #

	$self->{view_type} = 1;
	$self->{show_bars} = 0;

	my $f1 = $lf1->Frame()->pack(-fill => 'x',-pady => 2);
	
	$self->{check_view_type} = $f1->Checkbutton(
		-variable => \$self->{view_type},
		-text     => kh_msg->get('extended'),
		-command  => sub {
			$self->view;
		},
	)->pack(-anchor => 'w', -side => 'left');

	$f1->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-side => 'left');
	
	$self->{check_show_bars} = $f1->Checkbutton(
		-variable => \$self->{show_bars},
		-text     => kh_msg->get('gui_window::word_search->show_bars'),
		-command  => sub {
			$self->view;
		},
	)->pack(-anchor => 'w', -side => 'left');


	my $btn = $f1->Button(
		-text => kh_msg->gget('copy_all'), # コピー（表全体）
		-command => sub { $self->copy; }
	)->pack(-side => 'right', -padx => 2);

	return $self; ###


	$self->{entry_wsearch} = $f1->Entry(
		-width => 15,
	)->pack(-side => 'left', -fill => 'x', -expand => 1);

	$self->{entry_wsearch}->bind(
		"<Key-Return>",
		sub{
			my $key = $self->{last_sort_key};
			$self->{last_sort_key} = undef;
			$self->sort($key);
		}
	);
	$self->{entry_wsearch}->bind(
		"<KP_Enter>",
		sub{
			my $key = $self->{last_sort_key};
			$self->{last_sort_key} = undef;
			$self->sort($key);
		}
	);

	$f1->Button(
		-text => kh_msg->get('search'), # 検索
		-command => sub{
			my $key = $self->{last_sort_key};
			$self->{last_sort_key} = undef;
			$self->sort($key);
		}
	)->pack(-side => 'left', -padx => 2);

	$f1->Label(
		-text => '  ',
	)->pack(-side => 'left');

	$f1->Button(
		-text => kh_msg->get('whole'), # 全抽出語のリスト
		-command => sub { $self->list_all; }
	)->pack(-side => 'left', -padx => 2);


	
	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $btn->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$btn,
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);
	
	return $self;
}

#------------#
#   初期化   #

sub start{
	my $self = shift;
	
	# data structure
	# $term->[topic_number - 1] = [
	#	[word, value],
	#	[word, value],
	#	,,,
	# ]
	
	# load data 1: open file
	my $tsv = Text::CSV_XS->new ( { binary => 1, auto_diag => 2, sep_char  => "\t" } );
	use File::BOM;
	File::BOM::open_bom (my $fh, $self->{file_term}, ":encoding(utf8)" );
	gui_errormsg->open(
		type => 'file',
		file => $self->{file_term}
	) unless $fh;
	
	# load data 2: the fist line
	my $words = $tsv->getline($fh);
	shift @{$words};
	
	# load data 3: 2nd and so on...
	my $term;
	while ( my $row = $tsv->getline($fh) ){
		my $current_topic_number = shift @{$row};
		--$current_topic_number;
		my $n = 0;
		foreach my $i (@{$row}){
			push @{$term->[$current_topic_number]}, [$words->[$n],$i];
			++$n;
		}
	}
	
	# check
	#my $n = 0;
	#foreach my $i (sort {$b->[1] <=> $a->[1]} @{$term->[0]}){
	#	print "$i->[0], ";
	#	++$n;
	#	if ($n == 10) {
	#		last;
	#	}
	#}
	#print "\n";
	
	$self->{term} = $term;
	$self->view;
	return $self;
}

sub list_all{
	my $self = shift;
	my $dist = $::project_obj->file_TempCSV;
	$self->{knb_obj}->make_csv(
		$dist,
	);
	gui_OtherWin->open($dist);
}

sub _view_simple{
	my $self = shift;

	$self->{list} = $self->{list_flame}->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header             => 1,
		-itemtype           => 'text',
		-font               => 'TKFN',
		-columns            => 2,
		-padx               => 2,
		-background         => 'white',
		-selectforeground   => 'black',
		-selectmode         => 'extended',
		-height             => 10,
		#-borderwidth        => 0,
		-highlightthickness => 0,
	)->pack(-fill => 'both', -expand => 1);
	$self->{list}->header('create',0,-text => '#');
	
	my $header_label = $self->{list}->Label(
		-text => kh_msg->gget('words').' (Top 10)',
		-font               => "TKFN",
	);
	$self->{list}->header('create',1,-itemtype  => 'window',-widget => $header_label);

	my $row = 0;
	foreach my $topic (@{$self->{term}}){
		
		$self->{list}->add($row,-at => "$row");
		
		$self->{list}->itemCreate(
			$row,
			0,
			-text => $row + 1,
		);
		
		#my $c = $self->{list}->Entry(
		#	-font  => "TKFN",
		#	-width => 15
		#);
		#$self->{list}->itemCreate(
		#	$row,
		#	1,
		#	-itemtype  => 'window',
		#	-widget    => $c,
		#);
		#$self->{entry}[$row] = $c;

		my $w = '';
		my $n_w = 0;
		foreach my $i (sort {$b->[1] <=> $a->[1]} @{$topic}){
			if (length($w)) {
				$w .= ', ';
			}
			$w .= $i->[0];
			++$n_w;
			last if $n_w >= 10;
		}
		
		$self->{list}->itemCreate(
			$row,
			1,
			-text => $w,
		);
		#print "$w\n";
		
		++$row;
	}

	$self->{copy_text} = gui_hlist->get_all( $self->{list} );
	return $self;
}

sub _view_with_val{
	my $self = shift;

	$self->{list} = $self->{list_flame}->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header             => 0,
		-itemtype           => 'text',
		-font               => 'TKFN',
		-columns            => @{$self->{term}} * 3,
		-padx               => 2,
		-background         => 'white',
		-selectforeground   => 'black',
		-selectmode         => 'none',
		-height             => 10,
		#-borderwidth        => 0,
		-highlightthickness => 0,
	)->pack(-fill => 'both', -expand => 1);

	my $lgray_style = $self->{list}->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'w',
		-background => "#f0f0f0",
	);

	my $gray_style = $self->{list}->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'w',
		-background => "gray",
	);

	for (my $r = 0; $r <= 10; ++$r){
		$self->{list}->add($r,-at => $r);
	}

	my $t = 1;
	foreach my $topic (@{$self->{term}}){
		my $col = ( $t - 1 ) * 3;
		
		$self->{list}->itemCreate(
			0,
			$col,
			-text => '#'.$t,
			-style => $lgray_style,
		);
		
		$self->{list}->itemCreate(
			0,
			$col + 2,
			-text => ' ',
			#-style => $gray_style,
		);
		
		my $c = $self->{list}->Entry(
			-font  => "TKFN",
			-width => 15
		);
		#$self->{list}->itemCreate(
		#	0,
		#	$col + 1,
		#	-itemtype  => 'window',
		#	-widget    => $c,
		#);
		$self->{entry}[$t-1] = $c;

		my $row = 1;
		foreach my $i (sort {$b->[1] <=> $a->[1]} @{$topic}){
			
			$self->{list}->itemCreate(
				$row,
				$col,
				-text => $i->[0],
				-style => $lgray_style,
			);
			$self->{list}->itemCreate(
				$row,
				$col + 1,
				-text => sprintf("%.3f", $i->[1]),
				#-style => $lgray_style,
			);
			
			
			
			++$row;
			last if $row >= 10;
		}
		++$t;
	}

	$self->{copy_text} = gui_hlist->get_all($self->{list});
	return $self;
}

sub _view_with_valbar{
	my $self = shift;
	my @copy_text = ();

	$self->{list} = $self->{list_flame}->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header             => 0,
		-itemtype           => 'text',
		-font               => 'TKFN',
		-columns            => @{$self->{term}} * 3,
		-padx               => 2,
		-background         => 'white',
		-selectforeground   => 'black',
		-selectmode         => 'none',
		-height             => 10,
		#-borderwidth        => 0,
		-highlightthickness => 0,
	)->pack(-fill => 'both', -expand => 1);

	my $lgray_style = $self->{list}->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'w',
		-background => "#f0f0f0",
	);

	my $gray_style = $self->{list}->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'w',
		-background => "gray",
	);

	for (my $r = 0; $r <= 10; ++$r){
		$self->{list}->add($r,-at => $r);
	}

	my $t = 1;
	my @values = ();
	my @col_values = ();
	foreach my $topic (@{$self->{term}}){
		my $col = ( $t - 1 ) * 3;
		
		$self->{list}->itemCreate(
			0,
			$col,
			-text => '#'.$t,
			-style => $lgray_style,
		);
		
		$copy_text[0] .= "\t\t\t" if length( $copy_text[0] );
		$copy_text[0] .= '#'.$t;
		
		$self->{list}->itemCreate( # spacer
			0,
			$col + 2,
			-text => ' ',
			#-style => $gray_style,
		);

		my $row = 1;
		foreach my $i (sort {$b->[1] <=> $a->[1]} @{$topic}){
			
			$self->{list}->itemCreate(
				$row,
				$col,
				-text => $i->[0],
				-style => $lgray_style,
			);
			#$self->{list}->itemCreate(
			#	$row,
			#	$col + 1,
			#	-text => sprintf("%.3f", $i->[1]),
			#	#-style => $lgray_style,
			#);
			
			push @values, $i->[1];
			push @{$col_values[$t - 1]}, $i->[1];
			
			$copy_text[$row] .= "\t\t" if length( $copy_text[$row] );
			$copy_text[$row] .= "$i->[0]\t$i->[1]";
			
			++$row;
			last if $row >= 10;
		}
		++$t;
	}
	
	# bar graph
	my $test_label = $self->{list}->Label(       # width & height
		-text => '0.000',
		-font => "TKFN",
		-background => 'white',
		-foreground => 'white',
	);
	$self->{list}->itemCreate(
		0,
		1,
		-itemtype => 'window',
		-widget => $test_label,
	);
	$self->{list}->update;
	my $height = $test_label->height;
	my $width_min  = $test_label->width;
	#$test_label->destroy;
	$self->{list}->itemDelete(0, 1);
	
	use Statistics::Lite;                        # preparation for computing bar length
	my $min = Statistics::Lite::min(@values);
	my $max = Statistics::Lite::max(@values);
	my $range = $max - $min;
	
	
	$t = 1;                                      # draw bars & numbers
	foreach my $topic (@{$self->{term}}){
		my $row = 1;
		
		my $width = Statistics::Lite::max( @{$col_values[$t - 1]} );
		$width = int( ( $width - $min ) / $range * 100 );
		if ($width < $width_min) {
			$width = $width_min
		}
		
		foreach my $i (sort {$b->[1] <=> $a->[1]} @{$topic}){
			my $col = ( $t - 1 ) * 3;
			
			my $length = int( ( $i->[1] - $min ) / $range * 100 );
			
			
			my $c = $self->{list}->Canvas(
				-width => $width,
				-height => $height,
				-background => 'white',
				-borderwidth => 0,
				-highlightthickness => 0,
			);
			$c->create(
				'rectangle',
				0, 0, $length, 20,
				-fill    => '#a0d8ef',
				-outline => '#a0d8ef',
			);

			$c->createText(
				0, 10,
				-text => ' '.sprintf("%.3f", $i->[1]),
				-anchor => 'w',
				-font => "TKFN",
			);

			$self->{list}->itemCreate(
				$row,
				$col + 1,
				-itemtype => 'window',
				-widget => $c,
				#-style => $leftu,
			);
			
			++$row;
			last if $row >= 10;
		}
		++$t;
	}
	
	$self->{copy_text} = join("\n", @copy_text);
	return $self;
}


sub view{
	my $self = shift;

	#-------------------#
	#   Create HLists   #

	# column length
	my $cols = 2;

	# Hlist Widgets
	$self->{list}->destroy if $self->{list};                # Destroy
	$self->{list2}->destroy if $self->{list2};
	$self->{sb1}->destroy if $self->{sb1};
	$self->{sb2}->destroy if $self->{sb2};
	$self->{list_flame_inner}->destroy if $self->{list_flame_inner};

	$self->{list_flame_inner} = $self->{list_flame}->Frame( # Create
		-relief      => 'sunken',
		-borderwidth => 2
	);

	if ( $self->{view_type} == 0 ){
		$self->_view_simple;
		$self->{check_show_bars}->configure(-state => 'disable');
	} else {
		if ( $self->{show_bars} ){
			$self->_view_with_valbar;
		} else {
			$self->_view_with_val;
		}
		$self->{check_show_bars}->configure(-state => 'normal');
	}
	
	
	return $self;



	$self->{list2} = $self->{list_flame_inner}->HList(
		-header             => 1,
		-itemtype           => 'text',
		-font               => 'TKFN',
		-columns            => 2,
		-padx               => 2,
		-background         => 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectmode         => 'extended',
		-height             => 10,
		-width              => 22,
		-borderwidth        => 0,
		-highlightthickness => 0,
	);
	$self->{list2}->header('create',0,-text => 'topic#');
	my $h = $self->{list2}->Label(
		-text               => 'name',
		-font               => "TKFN",
		#-foreground         => 'blue',
		#-cursor             => 'hand2',
		-padx               => 0,
		-pady               => 0,
		-borderwidth        => 0,
		-highlightthickness => 0,
	);
	$self->{list2}->header('create',1,-itemtype  => 'window',-widget => $h);
	
	$self->{list} = $self->{list_flame_inner}->HList(
		-header             => 1,
		-itemtype           => 'text',
		-font               => 'TKFN',
		-columns            => $cols - 1,
		-padx               => 2,
		-background         => 'white',
		-selectforeground   => 'black',
		-selectmode         => 'extended',
		-height             => 10,
		-borderwidth        => 0,
		-highlightthickness => 0,
	);

	my $col = 0;                                            # Add Header
	foreach my $i (
		kh_msg->gget('words').' (Top 10)'
	){
		my $w = $self->{list}->Label(
			-text               => $i,
			-font               => "TKFN",
			#-foreground         => 'blue',
			#-cursor             => 'hand2',
			-padx               => 0,
			-pady               => 0,
			-borderwidth        => 0,
			-highlightthickness => 0,
		);
		my $key = $col;

		$self->{list}->header(
			'create',
			$col,
			-itemtype  => 'window',
			-widget    => $w,
		);
		++$col;
	}

	$self->confugre_hlist_scroll;

	#---------------------#
	#   Fill the HLists   #

	my $row = 0;
	foreach my $topic (@{$self->{term}}){
		
		$self->{list}->add($row,-at => "$row");
		$self->{list2}->add($row,-at => "$row");
		
		$self->{list2}->itemCreate(
			$row,
			0,
			-text => $row + 1,
		);
		
		my $c = $self->{list2}->Entry(
			-font  => "TKFN",
			-width => 15
		);
		$self->{list2}->itemCreate(
			$row,
			1,
			-itemtype  => 'window',
			-widget    => $c,
		);
		$self->{entry}[$row] = $c;

		my $w = '';
		my $n_w = 0;
		foreach my $i (sort {$b->[1] <=> $a->[1]} @{$topic}){
			if (length($w)) {
				$w .= ', ';
			}
			$w .= $i->[0];
			++$n_w;
			last if $n_w >= 10;
		}
		
		$self->{list}->itemCreate(
			$row,
			0,
			-text => $w,
		);
		
		++$row;
	}

	return $self;
}

sub copy{
	my $self = shift;
	
	
	
	use kh_clipboard;
	kh_clipboard->string( $self->{copy_text} );
}














sub confugre_hlist_scroll{
	my $self = shift;
	
	my $sb1 = $self->{list_flame}->Scrollbar(               # スクロール設定
		-orient  => 'v',
		-command => sub {
			$self->multiscrolly(@_);
		},
	);

	my $sb2 = $self->{list_flame}->Scrollbar(
		-orient => 'h',
		-command => ['xview' => $self->{list}]
	);

	$self->{list}->configure(
		-yscrollcommand => sub{
			$sb1->set(@_);
			# もう一方のリストが追随していなければ同期させる
			my $p1 = $_[0];
			my @t = $self->{list2}->yview;
			my $p2 = $t[0];
			
			if (
				   defined($self->{list_moveto})
				&& $self->{list_moveto} == $p1 
			){
					print "list1: pass\n" if $debug_ms;
					return 1;
			}
			
			if ($p1 == $p2){
				print "list1: list2 ok\n" if $debug_ms;
			} else {
				if ($self->{list2_moveto} == $p1){
					print "list1: already moved?\n" if $debug_ms;
					return 1
				}
				print "list1: change list2 to $p1 from $p2\n" if $debug_ms;
				$self->{list2_moveto} = $p1;
				$self->{list2}->yview(
					moveto => $p1,
				);
			}
		},
	);

	$self->{list2}->configure(
		-yscrollcommand => sub{
			$sb1->set(@_);
			# もう一方のリストが追随していなければ同期させる
			my $p1 = $_[0];
			my @t = $self->{list}->yview;
			my $p2 = $t[0];
			
			if (
				   defined($self->{list2_moveto})
				&& $self->{list2_moveto} == $p1 
			){
				print "list2: pass\n" if $debug_ms;
				return 1;
			}
			
			if ($p1 == $p2){
				print "list2: list1 ok\n" if $debug_ms;
			} else {
				if ($self->{list_moveto} == $p1){
					print "list2: already moved?\n" if $debug_ms;
					return 1
				}
				print "list2: change list1 to $p1 from $p2\n" if $debug_ms;
				$self->{list_moveto} = $p1;
				$self->{list}->yview(
					moveto => $p1,
				);
			}
		},
	);
	
	$self->{list}->configure( -xscrollcommand => ['set', $sb2] );
	$self->{sb1} = $sb1;
	$self->{sb2} = $sb2;
	
	$sb1->pack(-side => 'right', -fill => 'y');             # Pack
	$self->{list_flame_inner}->pack(-fill =>'both',-expand => 'yes');
	$self->{list2}->pack(-side => 'left', -fill =>'y', -pady => 0);
	$self->{list}->pack(-fill =>'both',-expand => 'yes', -pady => 0);
	$sb2->pack(-fill => 'x');
}

sub multiscrolly{
	my $self = shift;
	
	my $from = ( $self->{sb1}->get() )[0];
	
	$self->{list}->yview('moveto', $_[1]);
	

	print "multiscrolly to $_[1] from $from\n" if $debug_ms;
	
	return $self;
}

#--------------------------#
#   抽出語のソート＋表示   #

sub sort{
	my $self = shift;
	my $key  = shift;
	$key = 0 if $self->{last_sort_key} == $key;
	
	$self->{list}->delete('all');
	$self->{list2}->delete('all');
	
	# ソート
	my @sort;
	if ($key){
		@sort = sort { $b->[$key] <=> $a->[$key] } @{$self->{knb_obj}->rows};
	} else {
		@sort = @{$self->{knb_obj}->rows};
	}

	# 検索ルーチン
	my $s_method = 'AND';
	my $search = $self->gui_jg( $self->{entry_wsearch}->get );
	$search =~ s/　/ /go;
	$search = [ split / /, $search ]; # /

	my @temp = ();
	if ( @{$search} ){
		foreach my $i (@sort){
			my $cnt = 0;
			foreach my $j (@{$search}){
				if ($i->[0] =~ /$j/) {
					if ($s_method eq 'OR'){
						push @temp, $i;
						last;
					} else {
						++$cnt;
					}
				} else {
					if ($s_method eq 'AND'){
						last;
					}
				}
			}
			if ($s_method eq 'AND' && $cnt == @{$search}){
				push @temp, $i;
			}
		}
	} else {
		@temp = @sort;
	}

	# 出力
	my $right_style = $self->{list}->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'e',
	);
	my $right_style_g = $self->{list}->ItemStyle(
		'text',
		-font             => "TKFN",
		-anchor           => 'e',
		-foreground       => '#B22222',
		-selectforeground => '#B22222',
		#-background       => 'white'
	);
	my $right_style_o = $self->{list}->ItemStyle(
		'text',
		-font             => "TKFN",
		-anchor           => 'e',
		-foreground       => '#2A4596',
		-selectforeground => '#2A4596',
		#-background       => 'white'
	);

	my $row = 0;
	foreach my $i ( @temp ){
		my $len = ( @{$i} - 2 ) / 2;

		my $max1 = max( @{$i}[1..$len] );
		my $max2 = max( @{$i}[2+$len..1+$len+$len] );

		$self->{list}->add($row,-at => "$row");
		$self->{list2}->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			if ($col){
				my $style = $right_style;
				if     ($col >= 1 && $col <= $len && $h == $max1){
					$style = $right_style_g;
				} elsif ($col >= 2+$len && $col <= 1+$len+$len && $h == $max2){
					$style = $right_style_g;
				} elsif ($col == 1 + $len){
					$style = $right_style_o;
				}

				$self->{list}->itemCreate(
					$row,
					$col - 1,
					-text  => sprintf("%.2f", $h),
					-style => $style
				);
			} else {
				$self->{list2}->itemCreate(
					$row,
					0,
					-text => $h
				);
			}
			++$col;
		}
		++$row;
		last if $row >= 500;
	}
	$self->{list}->yview(0);
	$self->{list2}->yview(0);
	
	# ラベルの色を変更
	if ($key){
		my $w = $self->{list}->header(
			'cget',
			$key - 1,
			'-widget'
		);
		$w->configure(
			-foreground => 'red',
			#-cursor => undef
		);
		$w->bind(
			"<Leave>",
			sub { $w->configure(-foreground => 'red'); }
		);
	}
	
	# 前回変更したラベルの色を元に戻す
	if ($self->{last_sort_key}){
		my $lw = $self->{list}->header(
			'cget',
			$self->{last_sort_key} - 1,
			'-widget'
		);
		$lw->configure(
			-foreground => 'blue',
			#-cursor => 'hand2'
		);
		$lw->bind(
			"<Leave>",
			sub { $lw->configure(-foreground => 'blue'); }
		);
	}
	
	$self->{last_sort_key} = $key;
	return $self;
}




sub win_name{
	return 'w_topic_result';
}

1;