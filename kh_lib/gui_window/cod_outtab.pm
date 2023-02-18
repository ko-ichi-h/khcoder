package gui_window::cod_outtab;
use base qw(gui_window);
use strict;
use gui_widget::optmenu;
use mysql_outvar;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	#$win->focus;
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # コーディング・外部変数とのクロス集計
	
	#------------------------#
	#   オプション入力部分   #
	
	my $lf = $win->LabFrame(
		-label => 'Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	
	my $f0 = $lf->Frame->pack(-fill => 'x');
	# ルール・ファイル
	my %pack0 = (-side => 'left');
	$self->{codf_obj} = gui_widget::codf->open(
		parent => $f0,
		pack   => \%pack0
	);
	# セル内容選択
	$f0->Label(
		-text => kh_msg->get('cells'), # 　　セル内容：
		-font => "TKFN",
	)->pack(-side => 'left');
	
	gui_widget::optmenu->open(
		parent  => $f0,
		pack    => {-side => 'left'},
		options =>
			[
				[kh_msg->get('f_p') , 0], # 度数とパーセント
				[kh_msg->get('f')   , 1], # 度数のみ
				[kh_msg->get('p')   , 2], # パーセントのみ
			],
		variable => \$self->{cell_opt},
	);
	
	my $f1 = $lf->Frame->pack(-fill => 'x', -pady => 3);
	
	# 単位選択
	$f1->Label(
		-text => kh_msg->get('unit_cod'), # コーディング単位：
		-font => "TKFN"
	)->pack(-side => 'left');
	my %pack = (
		-pady   => 3,
		-side   => 'left',
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent  => $f1,
		pack    => \%pack,
		command => sub{$self->fill;}
	);

	# 変数選択
	$f1->Label(
		-text => kh_msg->get('var'), #  　クロスする変数：
		-font => "TKFN"
	)->pack(-side => 'left');
	
	$self->{opt_frame} = $f1;
	
	$f1->Button(
		-text    => kh_msg->get('run'), # 集計
		-font    => "TKFN",
		-width   => 8,
		-command => sub{$self->_calc;}
	)->pack( -anchor => 'e', -side => 'right')->focus;
	
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
		-text        => kh_msg->get('line_select'), # 選択
		-tearoff     => 'no',
		-relief      => 'raised',
		-indicator   => 'no',
		-font        => "TKFN",
		#-width       => $self->{width},
		-borderwidth => 1,
	)->pack(-anchor => 'e', -pady => 2, -padx => 2, -side => 'right');

	my $b2 = $rf->Button(
		-text => kh_msg->get('line_all'), # すべて
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub { $self->plot(2); }
	)->pack(-anchor => 'e', -pady => 2, -padx => 2, -side => 'right');

	$rf->Label(
		-text       => kh_msg->get('line'), # 折れ線
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
		-text       => kh_msg->get('map'), # マップ
	)->pack(-side => 'right');

	#SCREEN plugin
	use screen_code::cross_func;
	screen_code::cross_func::add_menu($self,$rf);
	#SCREEN Plugin

	# Rが使えない場合
	unless ($::config_obj->R){
		$b1->configure(-state => 'disable');
		$b2->configure(-state => 'disable');
		$b3->configure(-state => 'disable');
		$b4->configure(-state => 'disable');
	}

	#$rf->Label(
	#	-text       => kh_msg->get('plot'),
	#)->pack(-side => 'right');

	$self->fill;
	return $self;
}

#----------------------------------#
#   利用できる変数のリストを表示   #
#----------------------------------#

sub fill{
	my $self = shift;
	unless ($self->{tani_obj}){return 0;}
	
	if ( ! $self->{var_obj} ){
		$self->{var_obj} =  gui_widget::select_a_var->open(
			parent          => $self->{opt_frame},
			tani            => $self->tani,
			show_headings   => 1,
			higher_headings => 1,
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
		unless ( $self->tani && -e $self->cfile ){
			my $win = $self->win_obj;
			gui_errormsg->open(
				msg => kh_msg->get('er_ill'), # 指定された条件での集計は行えません。
				window => \$win,
				type => 'msg',
			);
			$self->rtn;
			return 0;
		}
	} else {
		unless ( $self->tani && -e $self->cfile && $self->var_id > -1){
			my $win = $self->win_obj;
			gui_errormsg->open(
				msg => kh_msg->get('er_ill'), # 指定された条件での集計は行えません。
				window => \$win,
				type => 'msg',
			);
			$self->rtn;
			return 0;
		}
	}
	
	#print "var_id: ".$self->var_id."\n";
	
	# 集計の実行
	my $result;
	unless ($result = kh_cod::func->read_file($self->cfile)){
		$self->rtn;
		return 0;
	}

	if ($self->{var_obj}->var_id =~ /h[1-5]/){    # 見出しの場合
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
	} else {                                      # 外部変数の場合
		unless (
			$result = $result->outtab(
				$self->tani,
				$self->var_id,
				$self->{cell_opt}
			)
		){
			$self->rtn;
			return 0;
		}
	}

	# 結果表示用のHList作成
	my $cols = @{$result->{display}[0]};
	my $width = 0;
	foreach my $i (@{$result->{display}}){
		if ( length( Encode::encode('cp932',$i->[0]) ) > $width ){
			$width = length( Encode::encode('cp932',$i->[0]) );
		}
		# Chinese characters will be transformed to "??".
		# So it's OK to get length.
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
			my $w = $self->{list}->Label(
				-text               => $self->gui_jchar($i),
				-font               => "TKFN",
				-foreground         => 'black',
				#-background         => 'white',
				-padx               => 0,
				-pady               => 0,
				-borderwidth        => 0,
				-highlightthickness => 0,
			);
			$self->list->header(
				'create',
				$col - 1,
				-itemtype  => 'window',
				-widget    => $w,
			);
			push @code_names, substr(
				$self->gui_jchar($i),
				1,
				length( $self->gui_jchar($i) )
			);
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
					-text  => $h,#$self->gui_jchar($h,'sjis'),
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
	if ($::main_gui->if_opened('w_cod_mat_plot')){          # マップ
		# オプション類はすべてリセット
		$self->plot($::main_gui->get('w_cod_mat_plot')->{ax});
	}
	
	if ($::main_gui->if_opened('w_cod_mat_line')){          # 折れ線
		# オプション類はリセットするがコード選択だけは活かすように試みる
		my @selected2 = ();
		my @selected3 = ();
		my @names = ();
		my @selected_names = ();
		if (
			$::main_gui->get('w_cod_mat_line')->{plots}[0]->command_f
			=~ /d <\- as\.matrix\(d\[,c\((.+)\)\]\)\n/ 
		){
			# 選択されたコードの番号
			@selected2 = eval( "($1)" );
			
			# 選択されたコードの名前
			if (
				$::main_gui->get('w_cod_mat_line')->{plots}[0]->command_f
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
	$rcom .= 'rsd <- matrix( c(';
	foreach my $row (@{$self->{result}{t_rsd}}){
		foreach my $cell (@{$row}){
			$rcom .= "$cell,"
		}
	}
	chop $rcom;
	$rcom .= "), byrow=T, nrow=$ncol, ncol=$nrow )\n";
	$rcom .= "rsd <- t(rsd)\n";
	
	# 列名
	foreach my $i (@col_names){ # 行頭の「＊」を削除（データはdecode済み）
		substr($i,0,1) = '';
	}
	$rcom .= "colnames(d) <- c(";
	foreach my $i (@col_names){
		my $name = $i;
		$name = kh_r_plot->quote($name);
		$rcom .= "$name,";
	}
	chop $rcom;
	$rcom .= ")\n";
	
	# 行名
	$rcom .= "rownames(d) <- c(";
	foreach my $i (@row_names){
		my $name = $i;
		$name = kh_r_plot->quote($name);
		$rcom .= "$name,";
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
	if ($ax <= 1){                      # ヒート・バブル
		use plotR::code_mat;
		$plot = plotR::code_mat->new(
			font_size           => $::config_obj->plot_font_size / 100,
			r_command           => $rcom,
			heat_dendro_c       => 1,
			heat_cellnote       => $nrow < 10 ? 1 : 0,
			plotwin_name        => 'code_mat',
			plot_size_heat      => $height,
			plot_size_maph      => $height_f,
			plot_size_mapw      => $width_f,
			bubble_size         => $bubble_size,
			selection           => $selection,
		);
		
		$wait_window->end(no_dialog => 1);
		
		if ($::main_gui->if_opened('w_cod_mat_plot')){
			$::main_gui->get('w_cod_mat_plot')->close;
		}
		
		return 0 unless $plot;
		
		gui_window::r_plot::cod_mat->open(
			plots       => $plot->{result_plots},
			ax          => $ax,
			no_geometry => 1,
		);
	} else {
		use plotR::code_mat_line;
		$plot = plotR::code_mat_line->new(
			font_size           => $::config_obj->plot_font_size / 100,
			r_command           => $rcom,
			plotwin_name        => 'code_mat_line',
			selection           => $selection,
		);
		
		$wait_window->end(no_dialog => 1);
		
		if ($::main_gui->if_opened('w_cod_mat_line')){
			$::main_gui->get('w_cod_mat_line')->close;
		}
		
		return 0 unless $plot;
		
		gui_window::r_plot::cod_mat_line->open(
			plots       => $plot->{result_plots},
			#no_geometry => 1,
		);
	}


	$plot = undef;
}

#--------------#
#   アクセサ   #

sub cfile{
	my $self = shift;
	return $self->{codf_obj}->cfile;
}
sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
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
	return 'w_cod_outtab';
}
1;