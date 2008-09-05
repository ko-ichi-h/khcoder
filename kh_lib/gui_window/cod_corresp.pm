package gui_window::cod_corresp;
use base qw(gui_window);

use strict;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt('コーディング・対応分析（オプション）'));

	my $lf = $win->LabFrame(
		-label       => 'Options',
		-labelside   => 'acrosstop',
		-borderwidth => 2
	)->pack(
		-fill   => 'both',
		-expand => 1
	);

	# ルール・ファイル
	my %pack0 = (
		-anchor => 'w',
		#-padx => 2,
		#-pady => 2,
		-fill => 'x',
		-expand => 0,
	);
	$self->{codf_obj} = gui_widget::codf->open(
		parent  => $lf,
		pack    => \%pack0,
		command => sub{$self->read_cfile;},
	);
	
	# コーディング単位
	my $f1 = $lf->Frame()->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 4
	);
	$f1->Label(
		-text => $self->gui_jchar('コーディング単位：'),
		-font => "TKFN",
	)->pack(-side => 'left');
	my %pack1 = (
		-anchor => 'w',
		-padx => 2,
		-pady => 2,
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $f1,
		command => sub { $self->refresh; },
		pack   => \%pack1,
	);

	# コード選択
	$lf->Label(
		-text => $self->gui_jchar('コード選択：'),
		-font => "TKFN",
	)->pack(-anchor => 'nw', -padx => 2, -pady => 0);

	my $f2 = $lf->Frame()->pack(
		-fill   => 'both',
		-expand => 1,
		-padx   => 2,
		-pady   => 2
	);

	$f2->Label(
		-text => $self->gui_jchar('　　','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);

	my $f2_1 = $f2->Frame(
		-borderwidth        => 2,
		-relief             => 'sunken',
	)->pack(
			-anchor => 'w',
			-side   => 'left',
			-pady   => 2,
			-padx   => 2,
			-fill   => 'both',
			-expand => 1
	);

	# コード選択用HList
	$self->{hlist} = $f2_1->Scrolled(
		'HList',
		-scrollbars         => 'osoe',
		#-relief             => 'sunken',
		-font               => 'TKFN',
		-selectmode         => 'none',
		-indicator => 0,
		-highlightthickness => 0,
		-columns            => 1,
		-borderwidth        => 0,
		-height             => 12,
	)->pack(
		-fill   => 'both',
		-expand => 1
	);

	my $f2_2 = $f2->Frame()->pack(
		-fill   => 'x',
		-expand => 0,
		-side   => 'left'
	);
	$f2_2->Button(
		-text => $self->gui_jchar('全て選択'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->select_all;});}
	)->pack(-pady => 3);
	$f2_2->Button(
		-text => $self->gui_jchar('クリア'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->select_none;});}
	)->pack();

	$lf->Label(
		-text => $self->gui_jchar('　　※コードを3つ以上選択して下さい。','euc'),
		-font => "TKFN",
	)->pack(
		-anchor => 'w',
		-padx   => 4,
		-pady   => 2,
	);

	# 入力データの設定

	$lf->Label(
		-text => $self->gui_jchar('分析に使用するクロス表の種類：'),
		-font => "TKFN",
	)->pack(-anchor => 'nw', -padx => 2, -pady => 0);

	my $fi = $lf->Frame()->pack(
		-fill   => 'x',
		-expand => 0,
		-padx   => 2,
		-pady   => 2
	);

	$fi->Label(
		-text => $self->gui_jchar('　　','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);

	my $fi_1 = $fi->Frame(
		-borderwidth        => 2,
		-relief             => 'sunken',
	)->pack(
		-anchor => 'w',
		-side   => 'left',
		-pady   => 2,
		-padx   => 2,
		-fill   => 'x',
		-expand => 0
	);

	$self->{radio} = 0;
	$fi_1->Radiobutton(
		-text             => $self->gui_jchar('コード ｘ 文書（同時布置なし）'),
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 0,
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w');

	$fi_1->Radiobutton(
		-text             => $self->gui_jchar('コード ｘ 上位の章・節・段落'),
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 1,
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w');

	my $fi_2 = $fi_1->Frame()->pack(-anchor => 'w');
	$self->{label_high} = $fi_2->Label(
		-text => $self->gui_jchar('　　集計単位：','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{opt_frame_high} = $fi_2;

	$fi_1->Radiobutton(
		-text             => $self->gui_jchar('コード ｘ 外部変数'),
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 2,
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w');

	my $fi_3 = $fi_1->Frame()->pack(-anchor => 'w');
	$self->{label_var} = $fi_3->Label(
		-text => $self->gui_jchar('　　変数：','euc'),
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);
	$self->{opt_frame_var} = $fi_3;
	$self->refresh;

	# 成分
	my $fd = $lf->Frame()->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 4,
	);

	$fd->Label(
		-text => $self->gui_jchar('成分数：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_d_n} = $fd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_d_n}->insert(0,'2');

	$fd->Label(
		-text => $self->gui_jchar('  x軸の成分：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_d_x} = $fd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_d_x}->insert(0,'1');

	$fd->Label(
		-text => $self->gui_jchar('  y軸の成分：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_d_y} = $fd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_d_y}->insert(0,'2');

	# フォントサイズ
	my $ff = $lf->Frame()->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 4,
	);

	$ff->Label(
		-text => $self->gui_jchar('フォントサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_font_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_font_size}->insert(0,'80');

	$ff->Label(
		-text => $self->gui_jchar('%'),
		-font => "TKFN",
	)->pack(-side => 'left');

	# OK・キャンセル
	my $f3 = $win->Frame()->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 2
	);

	$f3->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$self->{ok_btn} = $f3->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-state => 'disable',
		-command => sub{ $mw->after(10,sub{$self->_calc;});}
	)->pack(-side => 'right');

	$self->read_cfile;

	return $self;
}

# ラジオボタン関連
sub refresh{
	my $self = shift;
	unless ($self->{tani_obj}){return 0;}

	#------------------------#
	#   外部変数選択Widget   #

	unless ($self->{last_tani} eq $self->tani){
		my @options = ();
		my @tanis   = ();

		if ($self->{opt_body_var}){
			$self->{opt_body_var}->destroy;
		}

		# 利用できる変数があるかどうかチェック
		my %tani_check = ();
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			$tani_check{$i} = 1;
			last if ($self->tani eq $i);
		}
		if ($self->tani eq 'bun'){
			%tani_check = ();
			$tani_check{'bun'} = 1;
		}
		
		$self->{last_tani} = $self->tani;
		
		my $h = mysql_outvar->get_list;
		my @options = ();
		foreach my $i (@{$h}){
			if ($tani_check{$i->[0]}){
				push @options, [$self->gui_jchar($i->[1]), $i->[2]];
				#print "varid: $i->[2]\n";
			}
		}
		
		if (@options){
			$self->{opt_body_var} = gui_widget::optmenu->open(
				parent  => $self->{opt_frame_var},
				pack    => {-side => 'left', -padx => 2},
				options => \@options,
				variable => \$self->{var_id},
			);
			$self->{opt_body_var_ok} = 1;
		} else {
			$self->{opt_body_var} = gui_widget::optmenu->open(
				parent  => $self->{opt_frame_var},
				pack    => {-side => 'left', -padx => 2},
				options => 
					[
						[$self->gui_jchar('利用不可'), undef],
					],
				variable => \$self->{var_id},
			);
			$self->{opt_body_var_ok} = 0;
		}

	#------------------------------#
	#   上位の文書単位選択Widget   #

		if ($self->{opt_body_high}){
			$self->{opt_body_high}->destroy;
		}

		my %tani_name = (
			"bun" => "文",
			"dan" => "段落",
			"h5"  => "H5",
			"h4"  => "H4",
			"h3"  => "H3",
			"h2"  => "H2",
			"h1"  => "H1",
		);

		@tanis = ();
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			last if ($self->tani eq $i);
			
			if (
				mysql_exec->select(
					"select status from status where name = \'$i\'",1
				)->hundle->fetch->[0]
			){
				push @tanis, [$self->gui_jchar($tani_name{$i}),$i];
			}
		}

		if (@tanis){
			$self->{opt_body_high} = gui_widget::optmenu->open(
				parent  => $self->{opt_frame_high},
				pack    => {-side => 'left', -padx => 2},
				options => \@tanis,
				variable => \$self->{high},
			);
			$self->{opt_body_high_ok} = 1;
		} else {
			$self->{opt_body_high} = gui_widget::optmenu->open(
				parent  => $self->{opt_frame_high},
				pack    => {-side => 'left', -padx => 2},
				options => 
					[
						[$self->gui_jchar('利用不可'), undef],
					],
				variable => \$self->{high},
			);
			$self->{opt_body_high_ok} = 0;
		}
	}

	#----------------------------------#
	#   Widgetの有効・無効を切り替え   #

	if ($self->{radio} == 0){
		$self->{opt_body_high}->configure(-state => 'disable');
		$self->{label_high}->configure(-foreground => 'gray');
		
		$self->{opt_body_var}->configure(-state => 'disable');
		$self->{label_var}->configure(-foreground => 'gray');
	}
	elsif ($self->{radio} == 1){
		if ($self->{opt_body_high_ok}){
			$self->{opt_body_high}->configure(-state => 'normal');
		} else {
			$self->{opt_body_high}->configure(-state => 'disable');
		}
		$self->{label_high}->configure(-foreground => 'black');
		
		$self->{opt_body_var}->configure(-state => 'disable');
		$self->{label_var}->configure(-foreground => 'gray');
	}
	elsif ($self->{radio} == 2){
		$self->{opt_body_high}->configure(-state => 'disable');
		$self->{label_high}->configure(-foreground => 'gray');

		if ($self->{opt_body_var_ok}){
			$self->{opt_body_var}->configure(-state => 'normal');
		} else {
			$self->{opt_body_var}->configure(-state => 'disable');
		}
		$self->{label_var}->configure(-foreground => 'black');
	}
	
	return 1;
}


# コーディングルール・ファイルの読み込み
sub read_cfile{
	my $self = shift;
	
	$self->{hlist}->delete('all');
	
	unless (-e $self->cfile ){
		$self->{code_obj} = undef;
		return 0;
	}
	
	my $cod_obj = kh_cod::func->read_file($self->cfile);
	
	unless (eval(@{$cod_obj->codes})){
		$self->{code_obj} = undef;
		return 0;
	}

	my $left = $self->{hlist}->ItemStyle('window',-anchor => 'w');

	my $row = 0;
	foreach my $i (@{$cod_obj->codes}){
		
		$self->{checks}[$row]{check} = 1;
		$self->{checks}[$row]{name}  = $i;
		
		my $c = $self->{hlist}->Checkbutton(
			-text     => gui_window->gui_jchar($i->name,'euc'),
			-variable => \$self->{checks}[$row]{check},
			-command  => sub{ 
				$self->win_obj->after(10,sub{ $self->check_selected_num; });
			},
			-anchor => 'w',
		);
		
		$self->{checks}[$row]{widget} = $c;
		
		$self->{hlist}->add($row,-at => "$row");
		$self->{hlist}->itemCreate(
			$row,0,
			-itemtype  => 'window',
			-style     => $left,
			-widget    => $c,
		);
		++$row;
	}
	$self->{code_obj} = $cod_obj;
	
	$self->check_selected_num;
	
	return $self;
}

# コードが3つ以上選択されているかチェック
sub check_selected_num{
	my $self = shift;
	
	my $selected_num = 0;
	foreach my $i (@{$self->{checks}}){
		++$selected_num if $i->{check};
	}
	
	if ($selected_num >= 3){
		$self->{ok_btn}->configure(-state => 'normal');
	} else {
		$self->{ok_btn}->configure(-state => 'disable');
	}
	return $self;
}

# すべて選択
sub select_all{
	my $self = shift;
	foreach my $i (@{$self->{checks}}){
		$i->{widget}->select;
	}
	$self->check_selected_num;
	return $self;
}

# クリア
sub select_none{
	my $self = shift;
	foreach my $i (@{$self->{checks}}){
		$i->{widget}->deselect;
	}
	$self->check_selected_num;
	return $self;
}

# プロット作成＆表示
sub _calc{
	my $self = shift;

	my @selected = ();
	foreach my $i (@{$self->{checks}}){
		push @selected, $i->{name} if $i->{check};
	}

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	my $d_n = $self->gui_jg( $self->{entry_d_n}->get );
	my $d_x = $self->gui_jg( $self->{entry_d_x}->get );
	my $d_y = $self->gui_jg( $self->{entry_d_y}->get );

	# データ取得
	my $r_command;
	unless ( $r_command = $self->{code_obj}->out2r_selected($self->tani,\@selected) ){
		gui_errormsg->open(
			type   => 'msg',
			window  => \$self->win_obj,
			msg    => "出現数が0のコードは利用できません。"
		);
		#$self->close();
		return 0;
	}

	# データ整形
	$r_command .= "\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "row.names(d) <- c(";
	foreach my $i (@{$self->{checks}}){
		my $name = $i->{name}->name;
		substr($name, 0, 2) = ''
			if index($name,'＊') == 0
		;
		$r_command .= '"'.$name.'",'
			if $i->{check}
		;
	}
	chop $r_command;
	$r_command .= ")\n";
	$r_command .= "d <- t(d)\n";
	
	# 上位見出しの付与
	if ($self->{radio} == 1){
		my $tani_low  = $self->tani;
		my $tani_high = $self->{high};
		
		unless ($tani_high){
			gui_errormsg->open(
				type   => 'msg',
				window  => \$self->win_obj,
				msg    => "集計単位の選択が不正です。"
			);
			return 0;
		}
		
		my $sql = '';
		$sql .= "SELECT $tani_high.id\n";
		$sql .= "FROM $tani_high, $tani_low\n";
		$sql .= "WHERE\n";
		my $n = 0;
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			$sql .= "AND " if $n;
			$sql .= "$tani_low.$i"."_id = $tani_high.$i"."_id\n";
			++$n;
			if ($i eq $tani_high){
				last;
			}
		}
		$sql .= "ORDER BY $tani_low.id\n";
		
		my $max = mysql_exec->select("SELECT MAX(id) FROM $tani_high",1)
			->hundle->fetch->[0];
		my %names = ();
		my $n = 1;
		while ($n <= $max){
			$names{$n} = Jcode->new(
				mysql_getheader->get($tani_high, $n),
				'sjis'
			)->euc;
			++$n;
		}
		
		$r_command .= "v <- c(";
		my $h = mysql_exec->select($sql,1)->hundle;
		while (my $i = $h->fetch){
			if (length($names{$i->[0]})){
				$names{$i->[0]} =~ s/"/ /g;
				$r_command .= "\"$names{$i->[0]}\",";
			} else {
				$r_command .= "$i->[0],";
			}
		}
		chop $r_command;
		$r_command .= ")\n";
		$r_command .= "d <- aggregate(d,list(name = v), sum)\n";
		$r_command .= 'row.names(d) <- d$name'."\n";
		$r_command .= 'd$name <- NULL'."\n";
	}
	
	# 外部変数の付与
	if ($self->{radio} == 2){
		unless ($self->{var_id}){
			gui_errormsg->open(
				type   => 'msg',
				window  => \$self->win_obj,
				msg    => "外部変数の選択が不正です。"
			);
			return 0;
		}
		my $tani = $self->tani;
		
		my $sql = '';
		my $var_obj = mysql_outvar::a_var->new(undef,$self->{var_id});
		if ( $var_obj->{tani} eq $tani){
			$sql .= "SELECT $var_obj->{column} FROM $var_obj->{table} ";
			$sql .= "ORDER BY id";
		} else {
			$sql .= "SELECT $var_obj->{table}.$var_obj->{column}\n";
			$sql .= "FROM $tani, $var_obj->{tani}, $var_obj->{table}\n";
			$sql .= "WHERE\n";
			$sql .= "	$var_obj->{tani}.id = $var_obj->{table}.id\n";
			foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
				$sql .= "	and $var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
				last if ($var_obj->{tani} eq $i);
			}
			$sql .= "ORDER BY $tani.id";
		}
		
		$r_command .= "v <- c(";
		my $h = mysql_exec->select($sql,1)->hundle;
		my $n = 0;
		while (my $i = $h->fetch){
			if ( length( $var_obj->{labels}{$i->[0]} ) ){
				my $t = $var_obj->{labels}{$i->[0]};
				$t =~ s/"/ /g;
				$r_command .= "\"$t\",";
			} else {
				$r_command .= "$i->[0],";
			}
			++$n;
		}
		#print "num1: $n\n";
		chop $r_command;
		$r_command .= ")\n";
		$r_command .= "d <- aggregate(d,list(name = v), sum)\n";
		$r_command .= 'row.names(d) <- d$name'."\n";
		$r_command .= 'd$name <- NULL'."\n";
		
		$r_command .= 'd <- subset(d,row.names(d) != "欠損値" & row.names(d) != "." & row.names(d) != "missing")'."\n";
	}
	
	# MDS実行のためのRコマンド
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "d <- t(d)\n";
	
	$r_command .= "library(MASS)\n";
	$r_command .= "c <- corresp(d, nf=$d_n)\n";
	
	my $r_command_tmp = $r_command;
	$r_command_tmp = Jcode->new($r_command_tmp)->sjis
		if $::config_obj->os eq 'win32';
	$::config_obj->R->send($r_command_tmp);

	# 寄与率の取得
	$::config_obj->R->send(
		'print( paste("khcoder", min(nrow(d), ncol(d)), sep="" ) )'
	);
	my $count = $::config_obj->R->read;
	my $kiyo1;
	my $kiyo2;
	if ($count =~ /"khcoder(.+)"/){
		$count = $1;
	} else {
		$count = -1;
	}
	while ($count > 0){
		#print "$count\n";
		$::config_obj->R->send(
			 'print( paste("khcoder",round('
			."c(c\$cor[$d_x], c\$cor[$d_y])^2"
			.'/sum(corresp(d, nf='
			.$count
			.')$cor^2) * 100,2), sep=""))'
		);
		my $t = $::config_obj->R->read;
		if ($t =~ /"khcoder(.+)".*"khcoder(.+)"/){
			$kiyo1 = $1;
			$kiyo2 = $2;
			last;
		}
		--$count;
	}

	# プロットのためのRコマンド
	my ($r_command_2a, $r_command_2, $r_command_a);
	if ($self->{radio} == 0){                     # 同時布置なし
		$r_command .= 
		
		$r_command_2a = 
			 "plot(cbind(c\$cscore[,$d_x], c\$cscore[,$d_y]),"
				.'xlab="成分'.$d_x
				.' ('.$kiyo1.'%)",ylab="成分'.$d_y.' ('.$kiyo2.'%)")'
				."\n"
			."text(cbind(c\$cscore[,$d_x], c\$cscore[,$d_y]),"
				.'rownames(c$cscore), pos=1, cex='.$fontsize.')'
				."\n"
		;
		$r_command_2 = $r_command.$r_command_2a;
		
		$r_command_a .=
			 "plot(cbind(c\$cscore[,$d_x], c\$cscore[,$d_y]),"
				.'type="n", xlab="成分'.$d_x
				.' ('.$kiyo1.'%)", ylab="成分'.$d_y.' ('.$kiyo2.'%)")'
				."\n"
			."text(cbind(c\$cscore[,$d_x], c\$cscore[,$d_y]),"
				.'rownames(c$cscore), cex='.$fontsize.')'
		;
	} else {                                      # 同時布置あり
		$r_command_2a .= 'c$cscore <- cbind(c$cscore, 1)'."\n";
		$r_command_2a .= 'c$rscore <- cbind(c$rscore, 2)'."\n";

		$r_command_2a .= 
			 'plot(cb <- rbind('
				."cbind(c\$cscore[,$d_x], c\$cscore[,$d_y], 1),"
				."cbind(c\$rscore[,$d_x], c\$rscore[,$d_y], 2)"
				.'), xlab="成分'.$d_x.' ('.$kiyo1
				.'%)", ylab="成分'.$d_y.' ('.$kiyo2
				.'%)", pch=c(1,15)[cb[,3]] )'."\n"
			.'text('
				."cbind(c\$cscore[,$d_x], c\$cscore[,$d_y]),"
				.'rownames(c$cscore),pos=1,cex='.$fontsize.')'."\n"
			.'text('
				."cbind(c\$rscore[,$d_x], c\$rscore[,$d_y]),"
				.'rownames(c$rscore),pos=1, cex='.$fontsize.', )'
		;
		$r_command_2 = $r_command.$r_command_2a;

		$r_command_a .=
			 'plot(rbind('
				."cbind(c\$cscore[,$d_x], c\$cscore[,$d_y]),"
				."cbind(c\$rscore[,$d_x], c\$rscore[,$d_y])"
				.'), type="n", xlab="成分'.$d_x.' ('.$kiyo1
				.'%)", ylab="成分'.$d_y.' ('.$kiyo2.'%)")'
				."\n"
			.'text(c$cscore, rownames(c$cscore), cex='.$fontsize.')'."\n"
			.'text(c$rscore, rownames(c$rscore), cex='.$fontsize.', col="red")'
		;
	}
	$r_command .= $r_command_a;

	# プロット作成
	use kh_r_plot;
	my $plot1 = kh_r_plot->new(
		name      => 'codes_CORRESP1',
		command_a => $r_command_a,
		command_f => $r_command,
	) or return 0;

	my $plot2 = kh_r_plot->new(
		name      => 'codes_CORRESP2',
		command_a => $r_command_2a,
		command_f => $r_command_2,
	) or return 0;

	# プロットWindowを開く
	if ($::main_gui->if_opened('w_cod_corresp_plot')){
		$::main_gui->get('w_cod_corresp_plot')->close;
	}
	$self->close;
	gui_window::cod_corresp_plot->open(
		plots   => [$plot1,$plot2],
		#kiyo    => $kiyo,
	);

	return 1;
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
sub win_name{
	return 'w_cod_corresp';
}
1;