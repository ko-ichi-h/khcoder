package gui_window::bayes_view_log;
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
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # 分類ログファイル：

	$self->{path} = shift;

	#------------------#
	#   全体的な情報   #

	my $lf = $win->LabFrame(
		-label => 'Info',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');


	$lf->Label(
		-text => kh_msg->get('model_file'), # 学習結果：
	)->pack(-side => 'left');

	$self->{entry_file_model} = $lf->Entry(
		-width => 12,
	)->pack(-side => 'left',-fill => 'x', -expand => 1);


	$lf->Label(
		-text => kh_msg->get('saved_var'), #  保存先変数：
	)->pack(-side => 'left');

	$self->{entry_outvar} = $lf->Entry(
		-width => 12,
	)->pack(-side => 'left',-fill => 'x', -expand => 1);


	$lf->Label(
		-text => kh_msg->get('unit'), #  分類単位：
	)->pack(-side => 'left');

	$self->{entry_tani} = $lf->Entry(
		-width => 6,
	)->pack(-side => 'left');

	$lf->Label(
		-text => kh_msg->get('doc_id'), #  文書No.
	)->pack(-side => 'left');

	$self->{entry_dno} = $lf->Entry(
		-width => 6,
		-background => 'gray',
	)->pack(-side => 'left');

	$self->{entry_dno}->bind("<Key-Return>",sub{$self->select_doc;});
	$self->{entry_dno}->bind("<KP_Enter>",sub{$self->select_doc;});

	gui_window->disabled_entry_configure( $self->{entry_file_model} );
	gui_window->disabled_entry_configure( $self->{entry_outvar}     );
	gui_window->disabled_entry_configure( $self->{entry_tani}       );

	#--------------------#
	#   当該文書の情報   #

	$self->{frame_scores} = $win->LabFrame(
		-label => 'Scores',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');


	my $lf1 = $win->LabFrame(
		-label => 'Words',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	$self->{list_flame} = $lf1->Frame()->pack(-fill => 'both', -expand => 1);

	#------------------#
	#   操作ボタン類   #

	my $f1 = $lf1->Frame()->pack(-fill => 'x',-pady => 2);

	$f1->Label(
		-text => kh_msg->get('search_words'), # 抽出語の検索：
	)->pack(-side => 'left');

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

	$f1->Button(
		-text => kh_msg->get('run'), # 検索
		-command => sub{
			my $key = $self->{last_sort_key};
			$self->{last_sort_key} = undef;
			$self->sort($key);
		}
	)->pack(-side => 'left', -padx => 2);

	$f1->Label(
		-text => '  ',
	)->pack(-side => 'left');

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
	$self->{log_obj} = Storable::retrieve($self->{path});
	
	# モデルファイル名
	use File::Basename;
	my $fm = gui_window->gui_jchar($self->{log_obj}{file_model});
	$fm = File::Basename::basename($fm);

	$self->{entry_file_model}->configure(-state => 'normal');
	$self->{entry_file_model}->delete(0,'end');
	$self->{entry_file_model}->insert(0,$fm);
	$self->{entry_file_model}->configure(-state => 'disable');

	# 変数名
	$self->{entry_outvar}->configure(-state => 'normal');
	$self->{entry_outvar}->delete(0,'end');
	$self->{entry_outvar}->insert(0,
		$self->{log_obj}{outvar}
	);
	$self->{entry_outvar}->configure(-state => 'disable');

	# 単位
	my $tani = $self->{log_obj}{tani};
	$tani = kh_msg->gget('sentence') if $tani eq 'bun';
	$tani = kh_msg->gget('paragraph') if $tani eq 'dan';

	$self->{entry_tani}->configure(-state => 'normal');
	$self->{entry_tani}->delete(0,'end');
	$self->{entry_tani}->insert(0,
		$tani
	);
	$self->{entry_tani}->configure(-state => 'disable');
	
	$self->{bun_sq_2_id} = undef;
	$self->{bun_id_2_sq} = undef;
	if ( $self->{log_obj}{tani} eq 'bun') {
		my $h = mysql_exec->select("SELECT id, seq FROM bun",1)->hundle;
		while (my $i = $h->fetch) {
			$self->{bun_id_2_sq}{$i->[0]} = $i->[1];
			$self->{bun_sq_2_id}{$i->[1]} = $i->[0];
		}
	}

	# ログファイル名
	my $fl = $::config_obj->uni_path($self->{path});
	$fl = File::Basename::basename($fl);
	$self->{win_obj}->title(
		kh_msg->get('win_title')." $fl"
	);

	# 表示する文書の選択
	if ( $::main_gui->if_opened('w_doc_view') ){
		$self->{current} = $::main_gui->get('w_doc_view')->{doc_id};
	} else {
		$self->{current} = 1;
		
		# modify sentence id number
		if ( $self->{log_obj}{tani} eq 'bun'){
			#print "modify 4: $self->{current}, $self->{bun_sq_2_id}{$self->{current}}\n";
			$self->{current} = $self->{bun_sq_2_id}{$self->{current}};
		}
	}
	
	$self->view;
	
	return $self;
}

#----------------------#
#   文書の情報を表示   #

sub from_doc_view{
	my $self = shift;
	my $tani = shift;
	my $id   = shift;
	
	if ($tani eq  $self->{log_obj}{tani}){
		$self->{entry_dno}->delete(0,'end');
		
		# modify sentence id number
		my $id_4_print = $id;
		if ( $self->{log_obj}{tani} eq 'bun'){
			#print "modify 1: $id_4_print, $self->{bun_id_2_sq}{$id_4_print}\n";
			$id_4_print = $self->{bun_id_2_sq}{$id_4_print};
		}
		$self->{entry_dno}->insert(0,$id_4_print);
	
		$self->{current} = $id;
		$self->view;
	}
	
}

sub select_doc{
	my $self = shift;
	my $doc = $self->gui_jg( $self->{entry_dno}->get );
	
	# modify sentence id number
	if ( $self->{log_obj}{tani} eq 'bun'){
		#print "modify 3: $doc, $self->{bun_sq_2_id}{$doc}\n";
		$doc = $self->{bun_sq_2_id}{$doc};
	}
	
	$self->{current} = $doc;
	$self->view;
	return $self;
}


sub view{
	my $self = shift;

	#------------------------------#
	#   表示する文書が変わる場合   #

	my $selected_by_bayes;
	unless ( $self->{current} == $self->{ready} ){
		# テーブルの準備
		my $scores;
		($self->{result}, $scores) =
			&kh_nbayes::predict::make_each_log_table(
				$self->{log_obj}{log}{$self->{current}},
				$self->{log_obj}{labels},
				$self->{log_obj}{fixer},
				$self->{log_obj}{prior_probs},
			)
		;
		
		# 文書番号の表示
		$self->{entry_dno}->delete(0,'end');
		
		# modify sentence id number
		my $id_4_print = $self->{current};
		if ( $self->{log_obj}{tani} eq 'bun'){
			#print "modify 2: $id_4_print, $self->{bun_id_2_sq}{$id_4_print}\n";
			$id_4_print = $self->{bun_id_2_sq}{$id_4_print};
		}
		$self->{entry_dno}->insert(0, $id_4_print);
		
		# スコアの表示
		$self->{frame_scores_a}->destroy if $self->{frame_scores_a};
		$self->{frame_scores_a} = $self->{frame_scores}->Frame()->pack(
			-fill => 'x'
		);
		my $n = 0;
		foreach my $i (
			sort { $scores->{$b} <=> $scores->{$a} }
			keys %{$scores}
		){
			
			unless ($n + 1){
				$self->{frame_scores_a}->Label(
					-text => kh_msg->get('class'), # 分類：
				)->pack(-side => 'left');
				
				my @len;
				foreach my $h (@{$self->{log_obj}{labels}}){
					push @len, length( $h );
				}
				my $width = max(@len);
				
				my $e = $self->{frame_scores_a}->Entry(
					-width => $width + 2,
				)->pack(-side => 'left', -fill => 'x', -expand => 1);
				
				$e->insert(0, $self->gui_jchar($i) );
				$e->configure(-state => 'disable');
				gui_window->disabled_entry_configure( $e );
			}
			
			$selected_by_bayes = $i unless $n;
			$self->{frame_scores_a}->Label(
				-text => ' '
			)->pack(-side => 'left') if $n;

			$self->{frame_scores_a}->Label(
				-text => $self->gui_jchar($i.'：'),
			)->pack(-side => 'left');
			
			my $ent = $self->{frame_scores_a}->Entry(
				-width => 8,
			)->pack(
				-side => 'left',
				#-fill => 'x',
				#-expand => 1
			);
			
			$ent->insert(0, sprintf("%.2f",$scores->{$i}) );
			$ent->configure(-state => 'disable');
			gui_window->disabled_entry_configure( $ent );
			
			++$n;
			#last if $n >= 5;
		}
		$self->{frame_scores_a}->Label(
			-text => kh_msg->get('higher_left'), #  ※左からスコアの高い順に表示
		)->pack(-side => 'left');
		
		$self->{last_sort_key} = undef;
		$self->{ready} = $self->{current};
	}

	#--------------------#
	#   抽出語のリスト   #

	my $width = 0;
	foreach my $i (keys %{$self->{log_obj}{log}{$self->{current}}} ){
		if ( length($i) > $width ){
			$width = length($i);
		}
	}
	my $cols = 2 + 1 + @{$self->{log_obj}{labels}} * 2;

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
	foreach my $i ( @{$self->{log_obj}{labels}} ){
		push @temp, $i.' (%)';
	}
	foreach my $i (
		kh_msg->get('word'), # 抽出語
		kh_msg->get('freq'), # 頻度
		@{$self->{log_obj}{labels}},
		kh_msg->get('variance'), # 分散
		@temp
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
				sub { $w->configure(-foreground => 'blue'); }
			);
		}
		$self->{list}->header(
			'create',
			$col - 1,
			-itemtype  => 'window',
			-widget    => $w,
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
	
	my $n = 2;
	my $key;
	foreach my $i (@{$self->{log_obj}{labels}}){
		$key = $n if $selected_by_bayes eq $i;
		++$n;
	}
	$self->sort($key);
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
	
	return 0 unless $self->{result};
	
	# ソート
	my @sort;
	if ($key){
		@sort = sort { $b->[$key] <=> $a->[$key] } @{$self->{result}};
	} else {
		@sort = @{$self->{result}};
	}

	# 検索ルーチン
	my $s_method = 'AND';
	my $search = $self->gui_jg( $self->{entry_wsearch}->get );
	#$search = Jcode->new($search, 'sjis')->euc;
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
		my $len = ( @{$i} - 3 ) / 2;

		my $max1 = max( @{$i}[2..1+$len] );
		my $max2 = max( @{$i}[3+$len..2+$len+$len] );

		$self->{list}->add($row,-at => "$row");
		$self->{list2}->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			if ($col){
				my $style = $right_style;
				if     ($col >= 2 && $col <= 1+$len && $h == $max1){
					$style = $right_style_g;
				} elsif ($col >= 3+$len && $col <= 2+$len+$len && $h == $max2){
					$style = $right_style_g;
				} elsif ($col == 2 + $len){
					$style = $right_style_o;
				}


				$self->{list}->itemCreate(
					$row,
					$col - 1,
					-text  => $h,
					-style => $style
				);
			} else {
				$self->{list2}->itemCreate(
					$row,
					0,
					-text  => $h
				);
			}
			++$col;
		}
		++$row;
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
	
	return 0 unless $self->{result};
	
	# 1行目
	my $clip = "\t";
	
	my $cols = @{$self->{result}->[0]} - 2;
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
	my $rows = @{$self->{result}} - 1;
	for (my $r = 0; $r <= $rows; ++$r){
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
	return 'w_bayes_view_log';
}

1;