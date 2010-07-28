package gui_window::doc_cls_res;
use base qw(gui_window);

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
	$wmw->title($self->gui_jt('文書のクラスター分析'));
	
	#--------------------------------#
	#   各クラスターに含まれる文書   #
	
	my $fr_top = $wmw->Frame()->pack(-fill => 'both', -expand => 'yes');
	
	my $fr_dcs = $fr_top->LabFrame(
		-label => $self->gui_jchar('各クラスターに含まれる文書'),
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
		-selectforeground => 'brown',
		-selectbackground => 'cyan',
		#-selectmode       => 'single',
		-height           => 10,
		-width            => 10,
	)->pack(-fill =>'both',-expand => 'yes');
	$lis2->header('create',0,-text => $self->gui_jchar('クラスター番号'));
	$lis2->header('create',1,-text => $self->gui_jchar('文書数'));

	$lis2->bind("<Shift-Double-1>",sub{$self->cls_words;});
	$lis2->bind("<ButtonPress-3>",sub{$self->cls_words;});
	
	$lis2->bind("<Double-1>",sub{$self->cls_docs;});
	$lis2->bind("<Key-Return>",sub{$self->cls_docs;});

	my $fhl = $fr_dcs->Frame->pack(-fill => 'x');

	$fhl->Button(
		-text        => $self->gui_jchar('文書検索'),
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub{ $mw->after(10,sub {$self->cls_docs;}); }
	)->pack(-side => 'left', -padx => 2, -pady => 2, -anchor => 'c');

	$fhl->Button(
		-text        => $self->gui_jchar('特徴語'),
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub{ $mw->after(10,sub {$self->cls_words;}); }
	)->pack(-side => 'left', -padx => 2, -pady => 2, -anchor => 'c');
	
	$self->{copy_btn} = $fhl->Button(
		-text        => $self->gui_jchar('コピー'),
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub{ $mw->after(10,sub {gui_hlist->copy_all($self->list);});} 
	)->pack(-side => 'right', -padx => 2, -pady => 2, -anchor => 'c');

	#$self->win_obj->bind(
	#	'<Control-Key-c>',
	#	sub{ $self->{copy_btn}->invoke; }
	#);
	#$self->win_obj->Balloon()->attach(
	#	$self->{copy_btn},
	#	-balloonmsg => 'Ctrl + C',
	#	-font => "TKFN"
	#);
	
	#--------------------------#
	#   クラスター併合の過程   #
	
	my $fr_cls = $fr_top->LabFrame(
		-label => $self->gui_jchar('クラスター併合の過程'),
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
		-selectforeground => 'brown',
		-selectbackground => 'cyan',
		#-selectmode       => 'single',
		-height           => 10,
		-width            => 10,
	)->pack(-fill =>'both',-expand => 'yes');
	$lis_f->header('create',0,-text => $self->gui_jchar('段階'));
	$lis_f->header('create',1,-text => $self->gui_jchar('併合1'));
	$lis_f->header('create',2,-text => $self->gui_jchar('併合2'));
	$lis_f->header('create',3,-text => $self->gui_jchar('併合水準'));
	
	$lis_f->bind("<Double-1>",sub{$self->merge_docs;});
	
	my $fhr = $fr_cls->Frame->pack(-fill => 'x');

	$self->{btn_prev} = $fhr->Button(
		-text => $self->gui_jchar('前200'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {
			$self->{start} = $self->{start} - 200;
			$self->fill_list2;
		});} 
	)->pack(-side => 'left',-padx => 2, -pady => 2);

	$self->{btn_next} = $fhr->Button(
		-text => $self->gui_jchar('次200'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {
			$self->{start} = $self->{start} + 200;
			$self->fill_list2;
		});} 
	)->pack(-side => 'left',-padx => 2, -pady => 2);

	$fhr->Button(
		-text        => $self->gui_jchar('コピー'),
		-font        => "TKFN",
		-borderwidth => '1',
		-command     => sub{ $mw->after(10,sub {
			gui_hlist->copy_all($self->list2);
		});} 
	)->pack(-side => 'right', -padx => 2, -pady => 2);
	
	$fhr->Button(
		-text => $self->gui_jchar('プロット'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {
			if ($::main_gui->if_opened('w_doc_cls_height')){
				$::main_gui->get('w_doc_cls_height')->renew(
					$self->{tmp_out_var}
				);
			} else {
				gui_window::doc_cls_height->open(
					plots => $self->{plots},
					type  => $self->{tmp_out_var},
				);
			}
		});} 
	)->pack(-side => 'right',-padx => 2, -pady => 2);
	
	
	#----------------#
	#   Window下部   #
	
	$wmw->Label(
		-text => $self->gui_jchar('方法：',),
		-font => "TKFN",
	)->pack(-side => 'left');
	
	my @opt = (
		[$self->gui_jchar('Ward法','euc'),   '_cluster_tmp_w'],
		[$self->gui_jchar('群平均法','euc'), '_cluster_tmp_a'],
		[$self->gui_jchar('最遠隣法','euc'), '_cluster_tmp_c'],
	);
	
	$self->{optmenu} = gui_widget::optmenu->open(
		parent  => $wmw,
		pack    => {-side => 'left', -padx => 2},
		options => \@opt,
		variable => \$self->{tmp_out_var},
		command  => sub {$self->renew;},
	);
	$self->{optmenu}->set_value('_cluster_tmp_w');
	
	$wmw->Button(
		-text => $self->gui_jchar('調整'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {
			gui_window::doc_cls_res_opt->open(
				command_f => $self->{command_f},
				tani      => $self->{tani},
			);
		});} 
	)->pack(-side => 'left',-padx => 5);

	$wmw->Button(
		-text => $self->gui_jchar('分類結果の保存'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {
			gui_window::doc_cls_res_sav->open(
				var_from => $self->{tmp_out_var}
			);
		});} 
	)->pack(-side => 'right');

	$self->{list}  = $lis2;
	$self->{list2} = $lis_f;

	$self->renew;
	return $self;
}

sub renew{
	my $self = shift;
	
	#--------------------------------#
	#   各クラスターに含まれる文書   #
	
	# 外部変数取りだし
	my $var_obj = mysql_outvar::a_var->new($self->{tmp_out_var});
	
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
		$self->list->add($row,-at => "$row");
		$self->list->itemCreate(
			$row, 0,
			-text  => $self->gui_jchar('クラスター'.$i, 'euc'),
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
	open (MERGE,$self->{merge_files}{$self->{tmp_out_var}}) or
		gui_errormsg->open(
			type => 'file',
			file => $self->{merge_files}{$self->{tmp_out_var}},
		);
	
	my $merge;
	while (<MERGE>){
		chomp;
		push @{$merge}, [split /,/, $_ ];
	}
	close (MERGE);
	$self->{merge} = $merge;
	
	# 表示
	$self->{start} = 0;
	$self->fill_list2;
	
	# リモートウィンドウ
	if ($::main_gui->if_opened('w_doc_cls_height')){
		$::main_gui->get('w_doc_cls_height')->renew(
			$self->{tmp_out_var}
		);
	}
	
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
	
	# 選択箇所を取得
	my @selected = $self->list2->infoSelection;
	unless(@selected){
		return 0;
	}
	my $n = $self->gui_jg( $self->list2->itemCget($selected[0], 0, -text)) - 1;
	
	# 文書番号を探索
	my (@docs, @cls);
	
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
		my $msg = "$nの文書が選択されましたが、本機能で検索できる文書の数は200までです。\n検索を中止します。ご不便をおかけして申し訳ありません。";
		$msg = $self->gui_jchar($msg);
		gui_errormsg->open(
			type => 'msg',
			msg  => $msg
		);
		return 0;
	}
	
	my $q = '';
	foreach my $i (@docs){
		$q .= " | " if length($q);
		$q .= "No. == $i";
	}
	
	print "$q\n";
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
	my $query = $self->gui_jg( $self->list->itemCget($selected[0], 0, -text) );
	substr($query, 0, 10) = '';
	$query = '<>'.$self->{tmp_out_var}.'-->'.$query;
	
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
	my $query = $self->gui_jg( $self->list->itemCget($selected[0], 0, -text) );
	substr($query, 0, 10) = '';
	$query = '<>'.$self->{tmp_out_var}.'-->'.$query;
	
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
	$win->win_obj->focus;
	$win->search;
}

sub end{
	foreach my $i (@{mysql_outvar->get_list}){
		if ($i->[1] =~ /^_cluster_tmp_[wac]$/){
			mysql_outvar->delete(name => $i->[1]);
		}
	}
	# 「外部変数リスト」が開いている場合は更新
	my $win_list = $::main_gui->get('w_outvar_list');
	if ( defined($win_list) ){
		$win_list->_fill;
	}
	# 「併合水準」が開いている場合は閉じる
	if ($::main_gui->if_opened('w_doc_cls_height')){
		$::main_gui->get('w_doc_cls_height')->close;
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