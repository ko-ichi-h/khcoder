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

	$f1->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-side => 'left');

	$f1->Label(
		-text => kh_msg->get('words'),,
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_n_words} = $f1->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);

	$self->{entry_n_words}->insert(0, '10');
	$self->{entry_n_words}->bind("<Key-Return>", sub{ $self->view; });
	$self->{entry_n_words}->bind("<KP_Enter>", sub{ $self->view; });
	gui_window->config_entry_focusin( $self->{entry_n_words} );

	my $btn = $f1->Button(
		-text => kh_msg->gget('copy_all'), # コピー（表全体）
		-command => sub { $self->copy_all; }
	)->pack(-side => 'right', -padx => 3);
	$btn->update;

	my $mb = $f1->Menubutton(
		-text        => kh_msg->get('export'), # ▽出力
		-tearoff     => 'no',
		-relief      => 'raised',
		-indicator   => 'no',
		-font        => "TKFN",
		#-height     => $btn->height,
		#-width       => $self->{width},
		#-borderwidth => 1,
	)->pack(-padx => 2, -pady => 2, -side => 'right');

	$mb->command(
		-command => sub { $self->export_topic_term; },
		-label   => kh_msg->get('topic_term'), # 「トピック×語の確率」表
	);

	$mb->command(
		-command => sub {$self->export_doc_topic;},
		-label   => kh_msg->get('doc_topic'), # 「文書×トピック確率」表
	);

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
	
	# load topic-term data 1: open file
	my $tsv = Text::CSV_XS->new ( { binary => 1, auto_diag => 2, sep_char  => "\t" } );
	use File::BOM;
	File::BOM::open_bom (my $fh, $self->{file_term}, ":encoding(utf8)" );
	gui_errormsg->open(
			type => 'file',
			file => $self->{file_term}
	) unless $fh;
	
	# load topic-term data 2: the fist line
	my $words = $tsv->getline($fh);
	shift @{$words};
	
	# load topic-term data 3: 2nd and so on...
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
	close( $fh );
	$self->{term} = $term;

	# load doc-topic data 1: delete old variables
	my $h = mysql_outvar->get_list;
	foreach my $i (@{$h}){
		if ( $i->[1] =~ /^_topic_/ ){
			mysql_outvar->delete(
				tani => $i->[0],
				name => $i->[1],
			);
		}
	}

	# load doc-topic data 2: read variables
	mysql_outvar::read::csv->new(
		file     => $self->{file_topics_csv},
		tani     => $self->{tani},
		var_type => "DOUBLE",
	)->read;

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
		-text => kh_msg->gget('words').' (Top '.$self->{n_words}.')',
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
			last if $n_w >= $self->{n_words};
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

	for (my $r = 0; $r <= $self->{n_words} + 1; ++$r){
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
			last if $row >= $self->{n_words} + 1;
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

	for (my $r = 0; $r <= $self->{n_words} + 1; ++$r){
		$self->{list}->add($r,-at => $r);
	}

	my $t = 1;
	my @values = ();
	my @col_values = ();
	foreach my $topic (@{$self->{term}}){
		my $col = ( $t - 1 ) * 3;
		
		# topic_number: start
		my $c = $self->{list}->Label(
			-text => '#'.$t,
			-font       => "TKFN",
			-foreground => "blue",
			-activeforeground => "blue",
			-anchor     => 'w',
			-background => 'white',
			-pady       => 0,
			-activebackground => $::config_obj->color_ListHL_back,
		);
		my $tmp_number = $t;
		$c->bind(
			"<Button-1>",
			sub {
				$self->show_docs($tmp_number);
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
		$self->{list}->itemCreate(
			0,
			$col,
			-itemtype => 'window',
			-widget => $c,
		);
		# topic_number: end
		
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
			last if $row >= $self->{n_words} + 1;
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
			last if $row >= $self->{n_words} + 1;
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

	$self->{n_words} = gui_window->gui_jgn( $self->{entry_n_words}->get );
	
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
}

sub show_docs{
	my $self = shift;
	my $t = shift;
	print "show_docs: $t\n";
	
	my $win;
	if ($::main_gui->if_opened('w_doc_search')){
		$win = $::main_gui->get('w_doc_search');
	} else {
		$win = gui_window::doc_search->open;
	}
	
	$win->{tani_obj}->{raw_opt} = $self->{tani};
	$win->{tani_obj}->mb_refresh;
	
	$win->{clist}->selectionClear;
	$win->{clist}->selectionSet(0);
	$win->clist_check;
	
	$win->{direct_w_o}->set_value('var');
	&{$win->{direct_w_o}{command}};
	
	$win->{direct_w_e}->delete(0,'end');
	$win->{direct_w_e}->insert('end','_topic_'.$t);
	$win->win_obj->raise;
	$win->win_obj->focus;
	$win->search;
}


sub export_topic_term{
	my $self = shift;
	
	# save file name
	my @types = (
		['CSV Files',[qw/.csv/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.csv',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('topic_term')),
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);
	
	# open source file
	my $tsv = Text::CSV_XS->new ( { binary => 1, auto_diag => 2, sep_char  => "\t" } );
	use File::BOM;
	File::BOM::open_bom (my $fh, $self->{file_term}, ":encoding(utf8)" );
	gui_errormsg->open(
		type => 'file',
		file => $self->{file_term}
	) unless $fh;
	
	# open export file
	use File::BOM;
	open (my $of, '>:encoding(utf8):via(File::BOM)', $path) or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$path"
		)
	;
	my $csv = Text::CSV_XS->new ( { binary => 1, auto_diag => 2 } );
	
	while ( my $row = $tsv->getline($fh) ){
		$csv->print($of, $row);
		print $of "\n";
	}
	close ($fh);
	close ($of);
	
	return 1;
}

sub export_doc_topic{
	my $self = shift;
	
	# save file name
	my @types = (
		['CSV Files',[qw/.csv/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.csv',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('doc_topic')),
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);
	
	# copy the file
	use File::Copy qw/copy/;
	copy($self->{file_topics_csv}, $path) or warn("File copy failed: $path\n");
	
	return 1;
}



sub copy_all{
	my $self = shift;
	
	use kh_clipboard;
	kh_clipboard->string( $self->{copy_text} );
}

sub win_name{
	return 'w_topic_result';
}

1;