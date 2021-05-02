package gui_window::topic_stats;
use base qw(gui_window);
use strict;
use gui_widget::optmenu;
use mysql_outvar;

use utf8;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # コーディング・外部変数とのクロス集計
	
	my %args = @_;
	foreach my $i (keys %args){
		$self->{$i} = $args{$i};
	}
	
	#------------------------#
	#   オプション入力部分   #
	
	my $lf = $win->LabFrame(
		-label => 'Option',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	
	my $f1 = $lf->Frame->pack(-fill => 'x', -pady => 3);

	# 変数選択
	$f1->Label(
		-text => kh_msg->get('var'), # 集計：
		-font => "TKFN"
	)->pack(-side => 'left');
	
	$self->{opt_frame} = $f1;
	
	#$f1->Button(
	#	-text    => kh_msg->get('gui_window::cod_outtab->run'), # 集計
	#	-font    => "TKFN",
	#	-width   => 8,
	#	-command => sub{$self->_calc;}
	#)->pack( -anchor => 'e', -side => 'right')->focus;
	
	#------------------#
	#   結果表示部分   #

	my $rf = $win->LabFrame(
		-label => 'Result',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both',-expand => 'yes',-anchor => 'n');

	$self->{list_flame} = $rf->Frame()->pack(-fill => 'both',-expand => 1);
	
	$self->{list} = $self->{list_flame}->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 0,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 3,
		-padx             => 2,
		-background       => 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		-selectmode       => 'extended',
		-height           => 10,
	)->pack(-fill =>'both',-expand => 'yes');

	$self->{label} = $rf->Label(
		-text       => 'Ready.',
		-font       => "TKFN",
		-foreground => 'blue'
	)->pack(-side => 'left');

	$self->{copy_btn} = $rf->Button(
		-text => kh_msg->gget('copy_all'), # コピー（表全体）
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub { $self->copy; }
	)->pack(-anchor => 'e', -pady => 2, -side => 'right');

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{copy_btn}->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$self->{copy_btn},
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);

	$rf->Label(
		-text       => '  ',
	)->pack(-side => 'right');

	my $b1 = $self->{line_mb} = $rf->Menubutton(
		-text        => kh_msg->get('gui_window::cod_outtab->line_select'), # 選択
		-tearoff     => 'no',
		-relief      => 'raised',
		-indicator   => 'no',
		-font        => "TKFN",
		#-width       => $self->{width},
		-borderwidth => 1,
	)->pack(-anchor => 'e', -pady => 2, -padx => 2, -side => 'right');

	my $b2 = $rf->Button(
		-text => kh_msg->get('gui_window::cod_outtab->line_all'), # すべて
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $self->plot(2); }
	)->pack(-anchor => 'e', -pady => 2, -padx => 2, -side => 'right');

	$rf->Label(
		-text       => kh_msg->get('gui_window::cod_outtab->line'), # 折れ線
	)->pack(-side => 'right');

	my $b3 = $rf->Button(
		-text => kh_msg->get('gui_window::r_plot::cod_mat->fluc'), # バブル
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $self->plot(1); }
	)->pack(-anchor => 'e', -pady => 2, -padx => 2, -side => 'right');

	my $b4 = $rf->Button(
		-text => kh_msg->get('gui_window::r_plot::cod_mat->heat'), # ヒート
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $self->plot(0); }
	)->pack(-anchor => 'e', -pady => 2, -padx => 2, -side => 'right');

	$rf->Label(
		-text       => kh_msg->get('gui_window::cod_outtab->map'), # マップ
	)->pack(-side => 'right');

	# Rが使えない場合
	unless ($::config_obj->R){
		$b1->configure(-state => 'disable');
		$b2->configure(-state => 'disable');
		$b3->configure(-state => 'disable');
		$b4->configure(-state => 'disable');
	}

	$self->fill;
	return 0 unless $self->{var_obj}{if_vars}; # no variables available
	
	# select a variable
	my $var = '';
	if ( length( $::project_obj->status_topic_tabulation_var ) ){
		$var = $::project_obj->status_topic_tabulation_var;
	} else {
		foreach my $i (@{$self->{var_obj}{options}}){
			my $n = 0;
			if ($i->[1] =~ /^h[0-5]$/) {
				$n = mysql_exec->select("select count(*) from $i->[1]",1)->hundle->fetch->[0];
				print "$i->[1], $n\n";
			} else {
				my $var = mysql_outvar::a_var->new(undef, $i->[1])->values;
				$n = @{$var};
				print "$i->[0], $n\n";
			}
			if ($n <= 200) {
				$var = $i->[1];
				last;
			}
		}
	}
	
	$self->{var_obj}{var_id} = $var;
	$self->{var_obj}{opt_body}->set_value($var);
	$self->_calc;
	
	return $self;
}

#----------------------------------#
#   利用できる変数のリストを表示   #
#----------------------------------#

sub fill{
	my $self = shift;
	
	if ( ! $self->{var_obj} ){
		$self->{var_obj} =  gui_widget::select_a_var->open(
			parent          => $self->{opt_frame},
			tani            => $self->tani,
			show_headings   => 1,
			higher_headings => 1,
			no_topics       => 1,
			command         => sub {$self->_calc;},
		);
	} else {
		$self->{var_obj}->new_tani( $self->tani );
	}
}

sub var_id{
	my $self = shift;
	return $self->{var_obj}->var_id;
}

#------------------#
#   集計ルーチン   #

sub _calc{
	my $self = shift;
	$self->label->configure(
		-text => 'Counting...',
		-foreground => 'red'
	);
	$self->win_obj->update;
	
	# 入力内容チェック
	if ($self->var_id =~ /h[1-5]/i ) {
		# good to go?
	} else {
		unless ( $self->tani && $self->var_id > -1){
			my $win = $self->win_obj;
			gui_errormsg->open(
				msg => kh_msg->get('gui_window::cod_outtab->er_ill'), # 指定された条件での集計は行えません。
				window => \$win,
				type => 'msg',
			);
			$self->rtn;
			return 0;
		}
	}
	
	#print "var_id: ".$self->var_id."\n";
	
	# 集計の実行
	#my $result;
	#unless ($result = kh_cod::func->read_file($self->cfile)){
	#	$self->rtn;
	#	return 0;
	#}

	$::project_obj->status_topic_tabulation_var( $self->var_id );
	
	my $result;
	if ($self->var_id =~ /h[1-5]/){              # Headings (not ready yet)
		unless (
			$result = $result->tab(
				$self->tani,
				$self->var_id,
				$self->{cell_opt}
			)
		){
			$self->rtn;
			return 0;
		}
	} else {                                      # Variables
		# check the selected variable
		my $heap = 'TYPE=HEAP';
		$heap = '' unless $::config_obj->use_heap;
		my ($outvar_tbl,$outvar_clm);
		my $var_obj = mysql_outvar::a_var->new(undef,$self->var_id);
		if ( $var_obj->{tani} eq $self->{tani}){
			$outvar_tbl = $var_obj->{table};
			$outvar_clm = $var_obj->{column};
		} else {
			$outvar_tbl = 'tp_outvar_cross';
			$outvar_clm = 'value';
			mysql_exec->drop_table('tp_outvar_cross');
			mysql_exec->do("
				CREATE TABLE tp_outvar_cross (
					id int primary key not null,
					value varchar(255)
				) $heap
			",1);
			my $sql;
			$sql .= "INSERT INTO tp_outvar_cross\n";
			$sql .= "SELECT $self->{tani}.id, $var_obj->{table}.$var_obj->{column}\n";
			$sql .= "FROM $self->{tani}, $var_obj->{tani}, $var_obj->{table}\n";
			$sql .= "WHERE\n";
			$sql .= "	$var_obj->{tani}.id = $var_obj->{table}.id\n";
			foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
				$sql .= "	and $var_obj->{tani}.$i"."_id = $self->{tani}.$i"."_id\n";
				last if ($var_obj->{tani} eq $i);
			}
			$sql .= "ORDER BY $self->{tani}.id";
			#print "$sql\n\n";
			mysql_exec->do("$sql",1);
		}
		
		# compose & run SQL for stats
		my $topic_table = mysql_outvar::a_var->new('_topic_docid',undef)->table;
		my $sql;
		$sql .= "SELECT if ( outvar_lab.lab is NULL, $outvar_tbl.$outvar_clm, outvar_lab.lab) as name,";
		for (my $i = 1; $i <= $self->{n_topics}; ++$i){
			$sql .= "AVG( $topic_table.col$i ),";
		}
		$sql .= " count(*) \n";
		$sql .= "FROM $outvar_tbl\n";
		$sql .= "LEFT JOIN $topic_table ON $outvar_tbl.id = $topic_table.id\n";
		$sql .= "LEFT JOIN outvar_lab ON ( outvar_lab.var_id = $var_obj->{id} AND outvar_lab.val = $outvar_tbl.$outvar_clm )\n";
		$sql .= "\nGROUP BY name";
		$sql .= "\nORDER BY ".$::project_obj->mysql_sort('name');
		my $h = mysql_exec->select($sql,1)->hundle;
		
		# compose output table
		my @result;
		my @for_plot;
		
		my @head = ('');                         # the 1st line (header)
		for (my $i = 1; $i <= $self->{n_topics}; ++$i){
			push @head, "#$i";
		}
		use Clone qw(clone);
		push @for_plot, clone(\@head);
		push @head, kh_msg->get('kh_cod::func->n_cases');
		push @result, \@head;
		
		while (my $i = $h->fetch){               # 2nd and so on...
			my $n = 0;
			my @current;
			my @current_for_plot;
			my @c = @{$i};
			my $nd = pop @c;
		
			$var_obj->{labels}{$c[0]} = ''
				unless defined($var_obj->{labels}{$c[0]});
		
			next if
				   length($i->[0]) == 0
				or $c[0] eq '.'
				or $c[0] eq '欠損値'
				or $c[0] =~  /^missing$/i
				or $var_obj->{labels}{$c[0]} eq '.'
				or $var_obj->{labels}{$c[0]} eq '欠損値'
				or $var_obj->{labels}{$c[0]} =~ /^missing$/i
			;
		
			foreach my $h (@c){
				if ($n == 0){                         # the 1st col
					push @current,          gui_window->gui_jchar($h);
					push @current_for_plot, gui_window->gui_jchar($h);
				} else {                              # 2nd and so on...
					push @current_for_plot, $h;
					push @current,          sprintf("%.3f", $h);
				}
				++$n;
			}
			push @current, $nd;
			push @result, \@current;
			push @for_plot, \@current_for_plot;
		}
		$result->{display} = \@result;
		$result->{plot}    = \@for_plot;
	}

	# 結果表示用のHList作成
	my $cols = @{$result->{display}[0]};
	my $width = 0;
	my $longest = '';
	foreach my $i (@{$result->{display}}){
		if ( length( Encode::encode('cp932',$i->[0]) ) > $width ){
			$width = length( Encode::encode('cp932',$i->[0]) );
			$longest = $i->[0];
		}
		# Chinese characters will be transformed to "??".
		# So it's OK to get length.
	}
	unless ( $longest =~ /(\P{ASCII}+)/ ){
		$width += 1;
		print "width +1\n";
	}
	
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
		-selectbackground   => 'white',
		-selectforeground   => 'black',
		-selectmode         => 'extended',
		-height             => 10,
		-width              => $width,
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

	my $sb1 = $self->{list_flame}->Scrollbar(               # スクロール設定
		-orient  => 'v',
		-command => [ \&multiscrolly, $self->{sb1}, [$self->{list}, $self->{list2}]]
	);
	my $sb2 = $self->{list_flame}->Scrollbar(
		-orient => 'h',
		-command => ['xview' => $self->{list}]
	);
	$self->{list}->configure( -yscrollcommand => ['set', $sb1] );
	$self->{list}->configure( -xscrollcommand => ['set', $sb2] );
	$self->{list2}->configure( -yscrollcommand => ['set', $sb1] );
	$self->{sb1} = $sb1;
	$self->{sb2} = $sb2;

	$sb1->pack(-side => 'right', -fill => 'y');             # Pack
	$self->{list_flame_inner}->pack(-fill =>'both',-expand => 'yes');
	$self->{list2}->pack(-side => 'left', -fill =>'y', -pady => 0);
	$self->{list}->pack(-fill =>'both',-expand => 'yes', -pady => 0);
	$sb2->pack(-fill => 'x');

	# 結果の書き出し
	my $right_style = $self->list->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'e',
	);
	my $center_style = $self->list->ItemStyle(
		'text',
		-font => "TKFN",
		-anchor => 'c',
		-background => 'white',
	);
	
	# 一行目（Header）
	my $col = 0;
	my @code_names = ();
	foreach my $i (@{$result->{display}[0]}){
		if ($col){
			my $w;
			if ($i =~ /#[0-9]+/) {
				$w = $self->{list}->Label(
					-text               => $self->gui_jchar($i),
					-font               => "TKFN",
					-foreground         => 'blue',
					#-cursor             => 'hand2',
					-padx               => 0,
					-pady               => 0,
					-borderwidth        => 0,
					-highlightthickness => 0,
				);
				$w->bind(
					"<Button-1>",
					sub { $self->plot(2,[$self->{code2number}{$i}]) }
				);
				$w->bind(
					"<Enter>",
					sub { $w->configure(-foreground => 'red'); }
				);
				$w->bind(
					"<Leave>",
					sub { $w->configure(-foreground => 'blue'); }
				);
			} else {
				$w = $self->{list}->Label(
					-text               => $self->gui_jchar($i),
					-font               => "TKFN",
					-foreground         => 'black',
					#-background         => 'white',
					-padx               => 0,
					-pady               => 0,
					-borderwidth        => 0,
					-highlightthickness => 0,
				);
			}

			$self->list->header(
				'create',
				$col - 1,
				-itemtype  => 'window',
				-widget    => $w,
			);
			push @code_names, $i;
			#push @code_names, substr(
			#	$self->gui_jchar($i),
			#	1,
			#	length( $self->gui_jchar($i) )
			#);
		}
		++$col;
	}
	$self->{result} = $result;
	my @result_inside = @{$result->{display}};
	shift @result_inside;
	
	my $row = 0;
	foreach my $i (@result_inside){
		$self->list->add($row,-at => "$row");
		$self->{list2}->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			if ($col){
				$self->list->itemCreate(
					$row,
					$col -1,
					-text  => " ".$h,#$self->gui_jchar($h,'sjis'),
					-style => $right_style
				);
			} else {
				$self->{list2}->itemCreate(
					$row,
					0,
					-text  => $h,#$self->gui_jchar($h,'sjis')
				);
			}
			++$col;
		}
		++$row
		;
	}
	
	$self->{line_mb}->menu->delete(0,'end');
	my $n = 1;
	pop @code_names;
	$self->{code2number} = undef;
	foreach my $i (@code_names){
		$self->{code2number}{$i} = $n;
		$self->{line_mb}->command(
			-label => $i,
			-command => sub { $self->plot(2,[$self->{code2number}{$i}]) },
		
		);
		++$n;
	}
	
	$self->rtn;
	
	# プロットWindowが開いている場合は内容を更新する
	if ($::main_gui->if_opened('w_tpc_mat_plot')){          # マップ
		# オプション類はすべてリセット
		$self->plot($::main_gui->get('w_tpc_mat_plot')->{ax});
	}
	
	if ($::main_gui->if_opened('w_tpc_mat_line')){          # 折れ線
		# オプション類はリセットするがコード選択だけは活かすように試みる
		my @selected2 = ();
		my @selected3 = ();
		my @names = ();
		my @selected_names = ();
		if (
			$::main_gui->get('w_tpc_mat_line')->{plots}[0]->command_f
			=~ /d <\- as\.matrix\(d\[,c\((.+)\)\]\)\n/ 
		){
			# 選択されたコードの番号
			@selected2 = eval( "($1)" );
			
			# 選択されたコードの名前
			if (
				$::main_gui->get('w_tpc_mat_line')->{plots}[0]->command_f
				=~ /colnames\(d\) <\- c\((.+?)\)\n/ 
			){
				@names = eval( "($1)" );
			}
			foreach my $i (@selected2){
				push @selected_names, $self->gui_jchar($names[$i-1]);
			}
			
			# 選択されたコードの（新しい）番号
			foreach my $i (@selected_names){
				#print $self->gui_jg($i), ", ";
				if ($self->{code2number}{$i}){
					push @selected3, $self->{code2number}{$i};
					#print $self->{code2number}{$i};
				}
				#print "\n";
			}
			my $n = @selected3;
			if ($n == 0){
				@selected3 = (1);
			}
		}
		
		$self->plot(2,\@selected3);
	}
}

sub rtn{
	my $self = shift;
	$self->label->configure(
		-text => 'Ready.',
		-foreground => 'blue'
	);
}

sub copy{
	my $self = shift;
	my $t = '';
	
	foreach my $i (@{$self->{result}{display}}){
		my $n = 0;
		foreach my $h (@{$i}){
			$t .= "\t" if $n;
			$t .= $self->to_clip($h);
			++$n;
		}
		$t .= "\n";
	}
	use kh_clipboard;
	kh_clipboard->string($t);
}

sub multiscrolly{
	my ($sb,$wigs,@args) = @_;
	my $w;
	foreach $w (@$wigs){
		$w->yview(@args);
	}
}

sub plot{
	my $self   = shift;
	my $ax     = shift;
	my $selection = shift;
	
	unless ($self->{result}){
		return 0;
	}
	
	
	my $wait_window = gui_wait->start;
	
	my @matrix    = @{$self->{result}{plot}};
	my @col_names = @{shift @matrix};
	shift @col_names;
	my $nrow = @matrix;
	my $ncol = @col_names;

	# データ行列
	my $rcom = 'd <- matrix( c(';
	my @row_names;
	foreach my $row (@matrix){
		my $n = 0;
		foreach my $h (@{$row}){
			if ($n == 0){
				push @row_names, $h;
			} else {
				$rcom .= "$h,";
			}
			++$n;
		}
	}
	chop $rcom;
	$rcom .= "), byrow=T, nrow=$nrow, ncol=$ncol )\n";
	
	# 残差行列
	#$rcom .= 'rsd <- matrix( c(';
	#foreach my $row (@{$self->{result}{t_rsd}}){
	#	foreach my $cell (@{$row}){
	#		$rcom .= "$cell,"
	#	}
	#}
	#chop $rcom;
	#$rcom .= "), byrow=T, nrow=$ncol, ncol=$nrow )\n";
	#$rcom .= "rsd <- t(rsd)\n";
	
	# 列名
	#foreach my $i (@col_names){ # 行頭の「＊」を削除（データはdecode済み）
	#	substr($i,0,1) = '';
	#}
	$rcom .= "colnames(d) <- c(";
	foreach my $i (@col_names){
		$rcom .= "\"$i\",";
	}
	chop $rcom;
	$rcom .= ")\n";
	
	# 行名
	$rcom .= "rownames(d) <- c(";
	foreach my $i (@row_names){
		$rcom .= "\"$i\",";
	}
	chop $rcom;
	$rcom .= ")\n";
	
	$rcom .= "# END: DATA\n\n";

	# マップの高さ
	my $label_length = 0;
	foreach my $i (@row_names){
		if ( $label_length < length($i) ){
			$label_length = length($i);
		}
	}
	my $height = int( ( 30 * $ncol + $label_length * 14 ) * ($::config_obj->plot_size_codes / 480));
	if ($height < $::config_obj->plot_size_codes){
		$height = $::config_obj->plot_size_codes;
	}
	
	my $bs_h = 1;
	my $bs_w = 1;
	my $height_f = int( ( 20 * $ncol + $label_length * 15 ) * ($::config_obj->plot_size_codes / 480));
	if ($height_f < $::config_obj->plot_size_codes){
		$height_f = $::config_obj->plot_size_codes;
		$bs_h = (480 - $label_length * 15) / $ncol / 34;
	}
	
	# マップの幅
	$label_length = 0;
	foreach my $i (@col_names){
		if ( $label_length < length($i) ){
			$label_length = length($i);
		}
	}
	my $width_f = int( (18 * $nrow + $label_length * 15 + 25) * ($::config_obj->plot_size_words / 640) );
	if ($width_f < $::config_obj->plot_size_words){
		$width_f = $::config_obj->plot_size_words;
		$bs_w = (640 - 10 - $label_length * 15) / ($nrow + 1) / 34;
	}
	use List::Util 'min';
	print "bubble size adjustment, height: $bs_h,  width: $bs_w\n";
	my $bubble_size = int( min($bs_h, $bs_w) / ( $::config_obj->plot_font_size / 100 ) * 10 ) / 10;
	
	# プロット作成
	my $plot;
	if ($ax <= 1){                      # Heat & Bubble Map
		use plotR::code_mat;
		$plot = plotR::code_mat->new(
			font_size           => $::config_obj->plot_font_size / 100,
			r_command           => $rcom,
			heat_dendro_c       => 1,
			heat_cellnote       => $nrow < 10 ? 1 : 0,
			plotwin_name        => 'tpc_mat',
			plot_size_heat      => $height,
			plot_size_maph      => $height_f,
			plot_size_mapw      => $width_f,
			bubble_size         => $bubble_size,
			selection           => $selection,
			color_rsd           => 0,
		);
		
		$wait_window->end(no_dialog => 1);
		
		if ($::main_gui->if_opened('w_tpc_mat_plot')){
			$::main_gui->get('w_tpc_mat_plot')->close;
		}
		
		return 0 unless $plot;
		
		gui_window::r_plot::tpc_mat->open(
			plots       => $plot->{result_plots},
			ax          => $ax,
			no_geometry => 1,
			var         => $self->var_id,
			tani        => $self->tani,
		);
	} else {                            # Line Chart
		use plotR::code_mat_line;
		$plot = plotR::code_mat_line->new(
			font_size           => $::config_obj->plot_font_size / 100,
			r_command           => $rcom,
			plotwin_name        => 'tpc_mat_line',
			selection           => $selection,
		);
		
		$wait_window->end(no_dialog => 1);
		
		if ($::main_gui->if_opened('w_tpc_mat_line')){
			$::main_gui->get('w_tpc_mat_line')->close;
		}
		
		return 0 unless $plot;
		
		gui_window::r_plot::tpc_mat_line->open(
			plots => $plot->{result_plots},
			var   => $self->var_id,
			tani  => $self->tani,
			#no_geometry => 1,
		);
	}


	$plot = undef;
}

sub end{
	my $self = shift;
	
	if ($::main_gui->if_opened('w_tpc_mat_line')){
		$::main_gui->get('w_tpc_mat_line')->close;
	}
	if ($::main_gui->if_opened('w_tpc_mat_plot')){
		$::main_gui->get('w_tpc_mat_plot')->close;
	}
}


#--------------#
#   アクセサ   #

sub tani{
	my $self = shift;
	return $self->{tani};
}
sub label{
	my $self = shift;
	return $self->{label};
}
sub list{
	my $self = shift;
	return $self->{list};
}
sub list_frame{
	my $self = shift;
	return $self->{listframe};
}
sub win_name{
	return 'w_topic_stats';
}
1;