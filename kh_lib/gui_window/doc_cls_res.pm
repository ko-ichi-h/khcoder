package gui_window::doc_cls_res;
use base qw(gui_window);

use gui_window::doc_cls_res::clara;

use strict;
use gui_hlist;
use mysql_words;

sub _new{
	my $self = shift;
	my %args = @_;
	$self->{tani} = $args{tani};
	$self->{command_f} = $args{command_f};
	$self->{plots} = $args{plots};
	$self->{merge_files} = $args{merge_files};

	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};
	$wmw->title($self->gui_jt(kh_msg->get('win_title'))); # 文書のクラスター分析

	#--------------------------------#
	#   各クラスターに含まれる文書   #

	my $fr_top = $wmw->Frame()->pack(-fill => 'both', -expand => 'yes');

	my $fr_dcs = $fr_top->LabFrame(
		-label => kh_msg->get('docs_in_clusters'), # 各クラスターに含まれる文書
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'both', -expand => 1, -padx => 2, -pady => 2, -side => 'left');

	my $lis2 = $fr_dcs->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 2,
		-padx             => 2,
		#-command          => sub{$self->cls_docs},
		-background       => 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		#-selectmode       => 'single',
		-height           => 10,
		-width            => 10,
	)->pack(-fill =>'both',-expand => 'yes');
	$lis2->header('create',0,-text => kh_msg->get('h_cls_id')); # クラスター番号
	$lis2->header('create',1,-text => kh_msg->get('h_doc_num')); # 文書数

	$lis2->bind("<Shift-Double-1>",sub{$self->cls_words;});
	$lis2->bind("<ButtonPress-3>",sub{$self->cls_words;});
	
	$lis2->bind("<Double-1>",sub{$self->cls_docs;});
	$lis2->bind("<Key-Return>",sub{$self->cls_docs;});
	$lis2->bind("<KP_Enter>",sub{$self->cls_docs;});

	my $fhl = $fr_dcs->Frame->pack(-fill => 'x');

	my $btn_ds = $fhl->Button(
		-text        => kh_msg->get('docs'), # 文書検索
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub {$self->cls_docs;}
	)->pack(-side => 'left', -padx => 2, -pady => 2, -anchor => 'c');

	$wmw->Balloon()->attach(
		$btn_ds,
		-balloonmsg => kh_msg->get('bal_docs'), # クラスターに含まれる文書を検索\n[クラスターをダブルクリック]
		-font       => "TKFN"
	);

	my $btn_ass = $fhl->Button(
		-text        => kh_msg->get('words'), # 特徴語
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub {$self->cls_words;}
	)->pack(-side => 'left', -padx => 2, -pady => 2, -anchor => 'c');
	
	$wmw->Balloon()->attach(
		$btn_ass,
		-balloonmsg => kh_msg->get('bal_words'), # クラスターの特徴をあらわす語を検索\n[Shift + クラスターをダブルクリック]
		-font       => "TKFN"
	);
	
	$self->{copy_btn} = $fhl->Button(
		-text        => kh_msg->gget('copy'), # コピー
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub {gui_hlist->copy_all($self->list);}
	)->pack(-side => 'right', -padx => 2, -pady => 2, -anchor => 'c');
	
	if ( $self->{plots}{_dendro} ){
		$fhl->Button(
			-text        => kh_msg->gget('plot'), # プロット
			-font        => "TKFN",
			-borderwidth => '1',
			-command     => sub {
				if ($::main_gui->if_opened('w_doc_cls_plot')){
					$::main_gui->get('w_doc_cls_plot')->close;
				}
			
				gui_window::r_plot::doc_cls->open(
					plots     => [$self->{plots}{_dendro}],
					plot_size => $self->{plots}{_dendro}{width},
				);
			}
		)->pack(-side => 'right', -padx => 2, -pady => 2, -anchor => 'c');
	}

	#--------------------------#
	#   クラスター併合の過程   #
	
	my $fr_cls = $fr_top->LabFrame(
		-label => kh_msg->get('agglm'), # クラスター併合の過程
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'both', -expand => 1, -padx => 2, -pady => 2, -side => 'right');
	
	my $lis_f = $fr_cls->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 4,
		-padx             => 2,
		#-command          => sub{$self->cls_docs},
		-background       => 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		#-selectmode       => 'single',
		-height           => 10,
		-width            => 10,
	)->pack(-fill =>'both',-expand => 'yes');
	$lis_f->header('create',0,-text => kh_msg->get('h_stage')); # 段階
	$lis_f->header('create',1,-text => kh_msg->get('h_cls1')); # 併合1
	$lis_f->header('create',2,-text => kh_msg->get('h_cls2')); # 併合2
	$lis_f->header('create',3,-text => kh_msg->get('h_coeff')); # 併合水準
	
	$lis_f->bind("<Double-1>",sub{$self->merge_docs;});
	
	my $fhr = $fr_cls->Frame->pack(-fill => 'x');

	my $mb = $fhr->Menubutton(
		-text        => kh_msg->get('docs'), # 文書検索
		-tearoff     => 'no',
		-relief      => 'raised',
		-indicator   => 'no',
		-font        => "TKFN",
		#-width       => $self->{width},
		-borderwidth => 1,
	)->pack(-side => 'left',-padx => 2, -pady => 2);

	$mb->command(
		-command => sub {$self->merge_docs();},
		-label   => kh_msg->get('both'), # 1と2
	);

	$mb->command(
		-command => sub {$self->merge_docs('l');},
		-label   => kh_msg->get('only1'), # 1のみ
	);

	$mb->command(
		-command => sub {$self->merge_docs('r');},
		-label   => kh_msg->get('only2'), # 2のみ
	);

	$wmw->Balloon()->attach(
		$mb,
		-balloonmsg => kh_msg->get('bal_agg_docs'), # [ダブルクリック]\n併合したクラスターに含まれる文書を検索
		-font       => "TKFN"
	);

	$self->{btn_prev} = $fhr->Button(
		-text => kh_msg->get('gui_window::word_conc->prev').'200', # 前200
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			$self->{start} = $self->{start} - 200;
			$self->fill_list2;
		}
	)->pack(-side => 'left',-padx => 2, -pady => 2);

	$self->{btn_next} = $fhr->Button(
		-text => kh_msg->get('gui_window::word_conc->next').'200', # 次200
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			$self->{start} = $self->{start} + 200;
			$self->fill_list2;
		}
	)->pack(-side => 'left',-padx => 2, -pady => 2);

	$fhr->Button(
		-text        => kh_msg->gget('copy'), # コピー
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub {
			#return 0 unless $::config_obj->os eq 'win32';
			my $t = '';
			foreach my $i (@{$self->{merge}}){
				$t .= "$i->[0]\t$i->[1]\t$i->[2]\t$i->[3]\n";
			}
			use kh_clipboard;
			kh_clipboard->string($t);
		}
	)->pack(-side => 'right', -padx => 2, -pady => 2);
	
	$fhr->Button(
		-text => kh_msg->gget('plot'), # プロット
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			if ($::main_gui->if_opened('w_doc_cls_height')){
				$::main_gui->get('w_doc_cls_height')->renew(
					'_cluster_tmp'
				);
			} else {
				gui_window::cls_height::doc->open(
					plots => $self->{plots},
					type  => '_cluster_tmp'
				);
			}
		}
	)->pack(-side => 'right',-padx => 2, -pady => 2);
	
	
	#----------------#
	#   Window下部   #
	
	my $fb = $wmw->Frame()->pack(-fill => 'x', -padx => 2, -pady => 2);
	
	$fb->Button(
		-text => kh_msg->get('config'), # 調整
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			gui_window::doc_cls_res_opt->open(
				command_f => $self->{command_f},
				tani      => $self->{tani},
			);
		}
	)->pack(-side => 'left',-padx => 5);

	$fb->Button(
		-text => kh_msg->get('save'), # 分類結果の保存
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			gui_window::doc_cls_res_sav->open(
				var_from => '_cluster_tmp'
			);
		}
	)->pack(-side => 'right');

	$self->{list}  = $lis2;
	$self->{list2} = $lis_f;

	$self->renew;
	
	# 「外部変数リスト」が開いている場合は更新
	if ($::main_gui->if_opened('w_outvar_list')){
		my $win_list = $::main_gui->get('w_outvar_list');
		$win_list->_fill if defined($win_list);
	}
	
	return $self;
}

sub renew{
	my $self = shift;
	
	#--------------------------------#
	#   各クラスターに含まれる文書   #
	
	# 外部変数取りだし
	my $var_obj = mysql_outvar::a_var->new('_cluster_tmp');
	
	my $sql = '';
	$sql .= "SELECT $var_obj->{column} FROM $var_obj->{table} ";
	$sql .= "ORDER BY id";
	
	my $h = mysql_exec->select($sql,1)->hundle;
	my %v = ();
	while (my $i = $h->fetch){
		++$v{$i->[0]};
	}

	# 表示
	my $numb_style = $self->list->ItemStyle(
		'text',
		-anchor => 'e',
		-background => 'white',
		-font => "TKFN"
	);
	$self->list->delete('all');
	my $row = 0;
	foreach my $i (sort {$a<=>$b} keys %v){
		my $t = kh_msg->get('cluster').$i; # クラスター
		$t = kh_msg->get('na') if $i eq '.'; # 分類不可
		
		$self->list->add($row,-at => "$row");
		$self->list->itemCreate(
			$row, 0,
			-text  => $t,
		);
		$self->list->itemCreate(
			$row, 1,
			-text  => $v{$i},
			-style => $numb_style
		);
		++$row;
	}
	
	#--------------------------#
	#   クラスター併合の過程   #
	
	# データの読み込み
	if ($self->{merge_files}){
		
		# modify sentence id number (1)
		my $bun_id_2_seq;
		if ( $self->{tani} eq 'bun' ){
			my $h = mysql_exec->select("SELECT id, seq FROM bun",1)->hundle;
			while (my $i = $h->fetch) {
				$bun_id_2_seq->{$i->[0]} = $i->[1];
			}
		}
		
		open (MERGE,$self->{merge_files}{'_cluster_tmp'}) or
			gui_errormsg->open(
				type => 'file',
				file => $self->{merge_files}{'_cluster_tmp'},
			);
		
		my $merge;
		while (<MERGE>){
			chomp;
			my @c = split /,/, $_;
			
			# modify sentence id number (2)
			if ( $self->{tani} eq 'bun' ){
				if ($c[1] < 0) {
					$c[1] = $bun_id_2_seq->{$c[1] * -1} * -1;
				}
				if ($c[2] < 0) {
					$c[2] = $bun_id_2_seq->{$c[2] * -1} * -1;
				}
			}
			
			push @{$merge}, \@c;
		}
		close (MERGE);
		$self->{merge} = $merge;
		
		# 表示
		$self->{start} = 0;
		$self->fill_list2;
		
		# リモートウィンドウ
		#if ($::main_gui->if_opened('w_doc_cls_height')){
		#	$::main_gui->get('w_doc_cls_height')->renew(
		#		'_cluster_tmp'
		#	);
		#}
	}
	
	# デンドログラム・ウィンドウ
	#if ($::main_gui->if_opened('w_doc_cls_plot')){
	#	$::main_gui->get('w_doc_cls_plot')->close;
	#	
	#	gui_window::r_plot::doc_cls->open(
	#		plots       => [$self->{plots}{_dendro}],
	#		plot_size   => 480,
	#	);
	#}
	
	gui_hlist->update4scroll($self->list);
	return 1;
}

sub fill_list2{
	my $self  = shift;
	my $start = $self->{start};

	my $numb_style = $self->list2->ItemStyle(
		'text',
		-anchor => 'e',
		-background => 'white',
		-font => "TKFN"
	);

	$self->list2->delete('all');
	for (my $row = 0; $row < 200; ++$row){
		unless ($self->{merge}[$row + $start]){
			last;
		}
		
		$self->list2->add($row,-at => "$row");
		$self->list2->itemCreate(
			$row, 0,
			-text  => $self->{merge}[$row + $start][0],
			-style => $numb_style,
		);
		$self->list2->itemCreate(
			$row, 1,
			-text  => $self->{merge}[$row + $start][1],
			-style => $numb_style,
		);
		$self->list2->itemCreate(
			$row, 2,
			-text  => $self->{merge}[$row + $start][2],
			-style => $numb_style,
		);
		$self->list2->itemCreate(
			$row, 3,
			-text  => sprintf("%.3f", $self->{merge}[$row + $start][3]),
			-style => $numb_style,
		);
	}
	gui_hlist->update4scroll($self->list2);
	
	if ($self->{start} >= 200){
		$self->{btn_prev}->configure(-state => 'normal');
	} else {
		$self->{btn_prev}->configure(-state => 'disabled');
	}
	
	my $n = @{$self->{merge}};
	if ( $n > $self->{start} + 200 ){
		$self->{btn_next}->configure(-state => 'normal');
	} else {
		$self->{btn_next}->configure(-state => 'disabled');
	}
	
	
	return $self;
}

sub merge_docs{
	my $self = shift;
	my $opt  = shift;
	
	# 選択箇所を取得
	my @selected = $self->list2->infoSelection;
	unless(@selected){
		return 0;
	}
	my $n = $self->gui_jg( $self->list2->itemCget($selected[0], 0, -text)) - 1;
	
	# 文書番号を探索
	my (@docs, @cls);
	
	if ($opt eq 'l'){
		if ($self->{merge}[$n][1] > 0){
			push @cls, $self->{merge}[$n][1];
		} else {
			push @docs, $self->{merge}[$n][1] * -1;
		}
	}
	elsif ($opt eq 'r'){
		if ($self->{merge}[$n][2] > 0){
			push @cls, $self->{merge}[$n][2];
		} else {
			push @docs, $self->{merge}[$n][2] * -1;
		}
	} else {
		if ($self->{merge}[$n][1] > 0){
			push @cls, $self->{merge}[$n][1];
		} else {
			push @docs, $self->{merge}[$n][1] * -1;
		}
		if ($self->{merge}[$n][2] > 0){
			push @cls, $self->{merge}[$n][2];
		} else {
			push @docs, $self->{merge}[$n][2] * -1;
		}
	}
	
	while (@cls){
		my @temp = ();
		foreach my $i (@cls){
			if ($self->{merge}[$i - 1][1] > 0){
				push @temp, $self->{merge}[$i - 1][1];
			} else {
				push @docs, $self->{merge}[$i - 1][1] * -1;
			}
			if ($self->{merge}[$i - 1][2] > 0){
				push @temp, $self->{merge}[$i - 1][2];
			} else {
				push @docs, $self->{merge}[$i - 1][2] * -1;
			}
		}
		@cls = @temp;
	}
	
	$n = @docs;
	if ($n > 200){
		$self->search_byov(\@docs);
	} else {
		$self->search_direct(\@docs);
	}
}

sub search_byov{
	my $self = shift;
	my $docs = shift;
	
	# データ準備
	my %doc;
	foreach my $i (@{$docs}){
		$doc{$i} = 1;
	}
	
	my $n_doc = mysql_exec->select("SELECT count(*) FROM $self->{tani}")
		->hundle->fetch->[0];
	my $t = "_temp_for_search\n";
	for (my $n = 1; $n <= $n_doc; ++$n){
		if ($doc{$n}){
			$t .= "1\n";
		} else {
			$t .= "0\n";
		}
	}
	chomp $t;
	
	# ファイルに書き出し
	my $file = $::project_obj->file_TempCSV;
	open (OVOUT,">$file") or 
		gui_errormsg->open(
			type => 'file',
			file => $file,
		);
	print OVOUT $t;
	close (OVOUT);
	
	# 外部変数として読み込み
	foreach my $i (@{mysql_outvar->get_list}){
		if ($i->[1] eq '_temp_for_search'){
			mysql_outvar->delete(name => '_temp_for_search');
		}
	}
	mysql_outvar::read::tab->new(
		file     => $file,
		tani     => $self->{tani},
		var_type => 'INT',
	)->read;
	
	# リモートウィンドウの操作
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
	
	$win->{direct_w_o}->set_value('code');
	
	$win->{direct_w_e}->delete(0,'end');
	$win->{direct_w_e}->insert('end','<>_temp_for_search-->1');
	$win->win_obj->raise;
	$win->win_obj->focus;
	$win->search;
}

sub search_direct{
	my $self = shift;
	my $docs = shift;
	
	my $q = '';
	foreach my $i (@{$docs}){
		$q .= " | " if length($q);
		$q .= "No. == $i";
	}
	
	# リモートウィンドウの操作
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
	
	$win->{direct_w_o}->set_value('code');
	
	$win->{direct_w_e}->delete(0,'end');
	$win->{direct_w_e}->insert('end',$q);
	$win->win_obj->raise;
	$win->win_obj->focus;
	$win->search;
}


sub cls_words{
	my $self = shift;
	
	# クエリー作成
	my @selected = $self->list->infoSelection;
	unless(@selected){
		return 0;
	}
	my $query = $self->list->itemCget($selected[0], 0, -text);
	
	my $cls = kh_msg->get('cluster');
	if ($query =~ /$cls([0-9]+)/){
		$query = '<>'.'_cluster_tmp'.'-->'.$1;
	} else {
		$query = '<>'.'_cluster_tmp'.'-->.';
	}
	
	# リモートウィンドウの操作
	my $win;
	if ($::main_gui->if_opened('w_doc_ass')){
		$win = $::main_gui->get('w_doc_ass');
	} else {
		$win = gui_window::word_ass->open;
	}

	$win->{tani_obj}->{raw_opt} = $self->{tani};
	$win->{tani_obj}->mb_refresh;

	$win->{clist}->selectionClear;
	$win->{clist}->selectionSet(0);
	$win->clist_check;
	
	$win->{direct_w_e}->delete(0,'end');
	$win->{direct_w_e}->insert('end',$query);
	$win->win_obj->raise;
	$win->win_obj->focus;
	$win->search;
}

sub cls_docs{
	my $self = shift;
	
	# クエリー作成
	my @selected = $self->list->infoSelection;
	unless(@selected){
		return 0;
	}
	my $query = $self->list->itemCget($selected[0], 0, -text);
	my $cls = kh_msg->get('cluster');
	if ($query =~ /$cls([0-9]+)/){
		$query = '<>'.'_cluster_tmp'.'-->'.$1;
	} else {
		$query = '<>'.'_cluster_tmp'.'-->.';
	}
	
	# リモートウィンドウの操作
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
	
	$win->{direct_w_e}->delete(0,'end');
	$win->{direct_w_e}->insert('end',$query);
	$win->win_obj->raise;
	$win->win_obj->focus;
	$win->search;
}

sub end{
	foreach my $i (@{mysql_outvar->get_list}){
		if ($i->[1] eq "_cluster_tmp"){
			mysql_outvar->delete(name => $i->[1]);
		}
		if ($i->[1] eq '_temp_for_search'){
			mysql_outvar->delete(name => '_temp_for_search');
		}
	}
	# 「外部変数リスト」が開いている場合は更新
	if ($::main_gui->if_opened('w_outvar_list')){
		my $win_list = $::main_gui->get('w_outvar_list');
		$win_list->_fill if defined($win_list);
	}
	
	# 「併合水準」が開いている場合は閉じる
	if ($::main_gui->if_opened('w_doc_cls_height')){
		$::main_gui->get('w_doc_cls_height')->close;
	}

	# デンドログラムが開いている場合は閉じる
	if ($::main_gui->if_opened('w_doc_cls_plot')){
		$::main_gui->get('w_doc_cls_plot')->close;
	}
}


#--------------#
#   アクセサ   #

sub win_name{
	return 'w_doc_cls_res';
}

sub list{
	my $self = shift;
	return $self->{list};
}
sub list2{
	my $self = shift;
	return $self->{list2};
}

1;