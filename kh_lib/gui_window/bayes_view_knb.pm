package gui_window::bayes_view_knb;
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
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # 学習結果ファイル：

	$self->{path} = shift;

	#------------------#
	#   全体的な情報   #

	my $lf = $win->LabFrame(
		-label => 'Info',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');


	$lf->Label(
		-text => kh_msg->get('n_docs'), # 学習した文書：
	)->pack(-side => 'left');

	$self->{entry_instances} = $lf->Entry(
		-width => 12,
	)->pack(-side => 'left',-fill => 'x', -expand => 1);


	$lf->Label(
		-text => kh_msg->get('n_types'), #  異なり語数：
	)->pack(-side => 'left');

	$self->{entry_words} = $lf->Entry(
		-width => 12,
	)->pack(-side => 'left',-fill => 'x', -expand => 1);

	gui_window->disabled_entry_configure( $self->{entry_instances} );
	gui_window->disabled_entry_configure( $self->{entry_words}     );

	my $lf1 = $win->LabFrame(
		-label => 'Words (Top 500)',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	$self->{list_flame} = $lf1->Frame()->pack(-fill => 'both', -expand => 1);

	#------------------#
	#   操作ボタン類   #

	my $f1 = $lf1->Frame()->pack(-fill => 'x',-pady => 2);

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

	my $btn = $f1->Button(
		-text => kh_msg->gget('copy_all'), # コピー（表全体）
		-command => sub { $self->copy; }
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
	$self->{knb_obj} = kh_nbayes::Util->knb2lst( path => $self->{path} );

	# ファイル名
	my $fl = gui_window->gui_jchar($self->{path});
	$fl = File::Basename::basename($fl);
	$fl = $::config_obj->uni_path($fl);
	$self->{win_obj}->title(
		$self->gui_jt(
			kh_msg->get('win_title')." $fl"
		));


	# 文書数
	$self->{entry_instances}->configure(-state => 'normal');
	$self->{entry_instances}->delete(0,'end');
	$self->{entry_instances}->insert(0,$self->{knb_obj}->instances);
	$self->{entry_instances}->configure(-state => 'disable');

	# 抽出語数
	$self->{entry_words}->configure(-state => 'normal');
	$self->{entry_words}->delete(0,'end');
	$self->{entry_words}->insert(0,$self->{knb_obj}->words);
	$self->{entry_words}->configure(-state => 'disable');

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


sub view{
	my $self = shift;

	#--------------------#
	#   抽出語のリスト   #

	# 1列目の長さ
	my $width = 0;
	foreach my $i ( @{$self->{knb_obj}->rows} ){
		if ( length($i->[0]) > $width ){
			$width = length($i->[0]);
		}
	}
	my $cols = 2 + ($self->{knb_obj}->labels) * 2;

	# リストWidget
	$self->{list}->destroy if $self->{list};                # 古いものを廃棄
	$self->{list2}->destroy if $self->{list2};
	$self->{sb1}->destroy if $self->{sb1};
	$self->{sb2}->destroy if $self->{sb2};
	$self->{list_flame_inner}->destroy if $self->{list_flame_inner};

	$self->{list_flame_inner} = $self->{list_flame}->Frame( # 新たなリスト作成
		-relief      => 'sunken',
		-borderwidth => 2
	);
	$self->{list2} = $self->{list_flame_inner}->HList(
		-header             => 1,
		-itemtype           => 'text',
		-font               => 'TKFN',
		-columns            => 1,
		-padx               => 2,
		-background         => 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectmode         => 'extended',
		-height             => 10,
		#-width              => $width,
		-borderwidth        => 0,
		-highlightthickness => 0,
	);
	$self->{list2}->header('create',0,-text => ' ');
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

	my $col = 0;                                            # Header作成
	my @temp = ();
	foreach my $i ( $self->{knb_obj}->labels ){
		push @temp, $i.' (%)';
	}
	foreach my $i (
		kh_msg->gget('words'), $self->{knb_obj}->labels, kh_msg->get('variance'), @temp # 分散
	){
		unless ($col){
			++$col;
			next;
		}
		my $w = $self->{list}->Label(
			-text               => $self->gui_jchar($i),
			-font               => "TKFN",
			-foreground         => 'blue',
			-cursor             => 'hand2',
			-padx               => 0,
			-pady               => 0,
			-borderwidth        => 0,
			-highlightthickness => 0,
		);
		my $key = $col;
		unless ( $i eq '  ' ){
			$w->bind(
				"<Button-1>",
				sub { $self->sort($key); }
			);
			$w->bind(
				"<Enter>",
				sub { $w->configure(-foreground => 'red'); }
			);
			$w->bind(
				"<Leave>",
				sub { $w->configure(-foreground => 'blue');}
			);
		}
		$self->{list}->header(
			'create',
			$col - 1,
			-itemtype  => 'window',
			-widget => $w,
		);
		++$col;
	}

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

	#--------------------#
	#   抽出語のリスト   #

	$self->sort;
	return $self;
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

sub copy{
	my $self = shift;
	
	return 0 unless $self->{knb_obj}->rows;
	
	# 1行目
	my $clip = "\t";
	
	my $cols = @{$self->{knb_obj}->rows->[0]} - 2;
	for (my $n = 0; $n <= $cols; ++$n){
		#if ($self->{last_sort_key}){
		#	unless ($n + 1 == $self->{last_sort_key}){
		#		next;
		#	}
		#}
		
		my $w = $self->{list}->header(
			'cget',
			$n,
			'-widget'
		);
		$clip .= $w->cget('-text')."\t";
	}
	chop $clip;
	$clip .= "\n";

	# 中身
	my $rows = @{$self->{knb_obj}->rows} - 2;
	for (my $r = 0; $r <= $rows; ++$r){
		last unless $self->{list2}->info('exists', $r);
		
		# 1列目
		if ($self->{list2}->itemExists($r, 0)){
			my $cell = $self->{list2}->itemCget($r, 0, -text);
			chop $cell if $cell =~ /\r$/o;
			$clip .= "$cell\t";
		} else {
			$clip .= "\t";
		}
		# 2列目以降
		for (my $c = 0; $c <= $cols; ++$c){
			#if ($self->{last_sort_key}){
			#	unless ($c + 1 == $self->{last_sort_key}){
			#		next;
			#	}
			#}
		
			if ($self->{list}->itemExists($r, $c)){
				my $cell = $self->{list}->itemCget($r, $c, -text);
				chop $cell if $cell =~ /\r$/o;
				$clip .= "$cell\t";
			} else {
				$clip .= "\t";
			}
		}
		chop $clip;
		$clip .= "\n";
	}
	
	use kh_clipboard;
	kh_clipboard->string($clip);
}


sub win_name{
	return 'w_bayes_view_knb';
}

1;