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
	
	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};

	$wmw->title($self->gui_jt('文書・クラスター分析'));
	
	$wmw->Label(
		-text => $self->gui_jchar('■各クラスターに含まれる文書数'),
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $fh = $wmw->Frame()->pack(-fill =>'both',-expand => 'yes');

	my $lis2 = $fh->Scrolled(
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
		#-selectmode       => 'extended',
		-height           => 10,
		-width            => 10,
	)->pack(-fill =>'both',-expand => 'yes',-side => 'left');
	$lis2->header('create',0,-text => $self->gui_jchar('クラスター番号'));
	$lis2->header('create',1,-text => $self->gui_jchar('文書数'));

	$lis2->bind("<Shift-Double-1>",sub{$self->cls_words;});
	
	$lis2->bind("<Double-1>",sub{$self->cls_docs;});
	$lis2->bind("<Key-Return>",sub{$self->cls_docs;});

	my $fhl = $fh->Frame->pack(-fill => 'x', -side => 'left');

	$fhl->Button(
		-text        => $self->gui_jchar('文書'),
		-font        => "TKFN",
		-borderwidth => '1',
		-width       => 4,
		-command     => sub{ $mw->after(10,sub {$self->cls_docs;}); }
	)->pack(-padx => 2, -pady => 2, -anchor => 'c');

	$fhl->Button(
		-text        => $self->gui_jchar('特徴'),
		-font        => "TKFN",
		-borderwidth => '1',
		-width       => 4,
		-command     => sub{ $mw->after(10,sub {$self->cls_words;}); }
	)->pack(-padx => 2, -pady => 2, -anchor => 'c');
	
	$self->{copy_btn} = $fhl->Button(
		-text        => $self->gui_jchar('コピー'),
		-font        => "TKFN",
		-borderwidth => '1',
		-width       => 4,
		-command     => sub{ $mw->after(10,sub {gui_hlist->copy($self->list);});} 
	)->pack(-padx => 2, -pady => 10, -anchor => 'c');

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{copy_btn}->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$self->{copy_btn},
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);
	
	$wmw->Label(
		-text => $self->gui_jchar('方法：',),
		-font => "TKFN",
	)->pack(-side => 'left');
	
	my @opt = (
		[$self->gui_jchar('Ward法','euc'), '_cluster_tmp_w'],
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
	
	$self->{copy_btn} = $wmw->Button(
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

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{copy_btn}->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$self->{copy_btn},
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);

	$wmw->Button(
		-text => $self->gui_jchar('保存'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after(10,sub {
			gui_window::doc_cls_res_sav->open(
				var_from => $self->{tmp_out_var}
			);
		});} 
	)->pack(-side => 'right');

	$self->{list} = $lis2;

	$self->renew;
	return $self;
}

sub renew{
	my $self = shift;
	
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
	
	gui_hlist->update4scroll($self->list);
	return 1;
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


1;