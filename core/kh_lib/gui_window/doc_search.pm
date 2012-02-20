package gui_window::doc_search;
use base qw(gui_window);

use Tk;
use strict;

use gui_window::doc_search::linux;
use gui_window::doc_search::win32;
use gui_widget::optmenu;
use kh_cod::search;

#-------------#
#   GUI作製   #
#-------------#

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # 文書検索
	
	my $lf = $win->Frame(
		-borderwidth => 2,
	);

	my $adj = $win->Adjuster(
		-widget => $lf,
		-side   => 'top',
	);

	my $rf = $win->Frame(
		-borderwidth => 2,
	);

	$lf->Label(
		-text => 'Search Entry:'
	)->pack(-anchor => 'w');
	
	$rf->Label(
		-text => 'Result:'
	)->pack(-anchor => 'w');


	#--------------------#
	#   検索オプション   #

	my $left = $lf->Frame()->pack(-side => 'left', -fill => 'both', -expand => 1);
	my $right = $lf->Frame()->pack(-side => 'right', -anchor => 'nw');
	
	# コード選択
	#$left->Label(
	#	-text => kh_msg->get('1'), # ・コード選択
	#	-font => "TKFN"
	#)->pack(-anchor => 'w');
	
	$self->{clist} = $left->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => '0',
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => '1',
		-padx             => '2',
		-height           => '6',
		-width            => '20',
		-background       => 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		-selectmode       => 'extended',
		-command          => sub{ $self->search; },
		-browsecmd        => sub{ $self->clist_check; },
	)->pack(-anchor => 'w', -padx => '4',-pady => '2', -fill => 'both',-expand => 1);

	# コーディングルール・ファイル
	my %pack0 = (
			-anchor => 'w',
			-fill   => 'x',
			-expand => '1'
	);
	$self->{codf_obj} = gui_widget::codf->open(
		parent   => $right,
		command  => sub{$self->read_code;},
		#r_button => 1,
		pack     => \%pack0,
	);

	# 直接入力フレーム
	my $f3 = $right->Frame()->pack(-fill => 'x', -pady => 6);
	$self->{direct_w_l} = $f3->Label(
		-text => kh_msg->get('gui_window::word_ass->direct'), # 直接入力：
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{direct_w_o} = gui_widget::optmenu->open(
		parent  => $f3,
		pack    => {-side => 'left'},
		options =>
			[
				['and'  , 'and' ],
				['or'   , 'or'  ],
				['code' , 'code']
			],
		variable => \$self->{opt_direct},
	);

	$self->{direct_w_e} = $f3->Entry(
		-font       => "TKFN",
	)->pack(-side => 'left', -padx => 2,-fill => 'x',-expand => 1);
	$self->{direct_w_e}->bind(
		"<Key>",
		[\&gui_jchar::check_key_e,Ev('K'),\$self->{direct_w_e}]
	);
	$win->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$self->{direct_w_e}->bind("<Key-Return>",sub{$self->search;});

	# 各種オプション
	my $f2 = $right->Frame()->pack(-fill => 'x',-pady => 2);

	$self->{btn_search} = $f2->Button(
		-font    => "TKFN",
		-text    => kh_msg->get('run'), # 検索
		-command => sub{$self->search;}
	)->pack(-side => 'right',-padx => 4);
	$win->Balloon()->attach(
		$self->{btn_search},
		-balloonmsg => 'Shift + Enter',
		-font       => "TKFN"
	);

	my %pack = (
			-anchor => 'w',
			-pady   => 1,
			-side   => 'right'
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $f2,
		pack   => \%pack
	);
	$self->{l_c_2} = $f2->Label(
		-text => kh_msg->get('unit'), # 検索単位：
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'right');

	$self->{opt_w_method1} = gui_widget::optmenu->open(
		parent  => $f2,
		pack    => {-pady => '1', -side => 'left'},
		options =>
			[
				[kh_msg->get('gui_window::word_ass->and'), 'and'], # AND検索
				[kh_msg->get('gui_window::word_ass->or') , 'or'] # OR検索
			],
		variable => \$self->{opt_method1},
	);

	gui_widget::optmenu->open(
		parent  => $f2,
		pack    => {-padx => 8, -pady => 1},
		options =>
			[
				[kh_msg->get('no_sort')   , 'by'    ], # 出現順
				[kh_msg->get('tf')     , 'tf'    ], # tf順
				[kh_msg->get('tf_M_idf') , 'tf*idf'], # tf*idf順
				[kh_msg->get('tf_D_idf') , 'tf/idf'] # tf/idf順
			],
		variable => \$self->{opt_order},
	);

	#--------------#
	#   検索結果   #

	$self->{rlist} = $rf->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 0,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 1,
		-padx             => 2,
		-background       => 'white',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		-selectmode       => 'extended',
		-height           => 10,
		-command          => sub {$self->view_doc;}
	)->pack(-fill =>'both',-expand => 1);

	my $f5 = $rf->Frame()->pack(-fill => 'x', -pady => 2);
	
	$self->{status_label} = $f5->Label(
		-text       => 'Ready.',
		-font       => "TKFN",
		-foreground => 'blue'
	)->pack(-side => 'right');

	$self->{copy_btn} = $f5->Button(
		-font    => "TKFN",
		-text    => kh_msg->gget('copy'), # コピー
		-width   => 8,
		-command => sub{$self->copy;},
		-borderwidth => 1
	)->pack(-side => 'left');

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{copy_btn}->invoke; }
	);
	$self->win_obj->Balloon()->attach(
		$self->{copy_btn},
		-balloonmsg => 'Ctrl + C',
		-font => "TKFN"
	);

	$f5->Button(
		-font    => "TKFN",
		-width   => 8,
		-text    => kh_msg->get('gui_window::word_conc->viewDoc'), # 文書表示
		-command => sub{$self->view_doc;},
		-borderwidth => 1
	)->pack(-side => 'left',-padx => 2);

	$f5->Label(
		-text => ' ',
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{btn_prev} = $f5->Button(
		-text        => kh_msg->get('gui_window::word_conc->prev').kh_cod::search->docs_per_once,
		-font        => "TKFN",
		-command     =>
			sub{
				my $start =
					$self->{current_start} - kh_cod::search->docs_per_once;
				$self->display($start);
			},
		-borderwidth => 1,
		-state       => 'disable',
	)->pack(-side => 'left',-padx => 2);

	$self->{btn_next} = $f5->Button(
		-text        => kh_msg->get('gui_window::word_conc->next').kh_cod::search->docs_per_once,
		-font        => "TKFN",
		-command     =>
			sub{
				my $start =
					$self->{current_start} + kh_cod::search->docs_per_once;
				$self->display($start);
			},
		-borderwidth => 1,
		-state       => 'disable',
	)->pack(-side => 'left');

	$self->{hits_label} = $f5->Label(
		-text       => kh_msg->get('gui_window::word_conc->hits'), #   ヒット数：0
		-font       => "TKFN",
	)->pack(-side => 'left',);

	$self->win_obj->bind(
		'<FocusIn>',
		sub { $self->activate; }
	);

	$lf->pack(-side => 'top', -fill => 'x');
	$adj->pack(-side => 'top', -fill => 'x', -pady => 2, -padx => 4);
	$rf->pack(-side => 'top', -fill => 'both', -expand => 1);


	return $self;
}

sub start{
	my $self = shift;
	$self->read_code;
	$self->clist_check;

}

#------------------------------------#
#   ルールファイルの更新をチェック   #

sub activate{
	my $self = shift;
	return 1 unless $self->{codf_obj};
	return 1 unless -e $self->cfile;
	return 1 unless $self->{timestamp};
	
	unless ( ( stat($self->cfile) )[9] == $self->{timestamp} ){
		print "reload: ".$self->cfile."\n";
		my @selected = $self->{clist}->infoSelection;
		$self->read_code;
		$self->{clist}->selectionClear;
		foreach my $i (@selected){
			$self->{clist}->selectionSet($i)
				if $self->{clist}->info('exists', $i);
		}
		$self->clist_check;
	}
	return $self;
}

#----------------------------#
#   ルールファイル読み込み   #

sub read_code{
	my $self = shift;
	
	$self->{clist}->delete('all');
	
	# 「直接入力」を追加
	$self->{clist}->add(0,-at => 0);
	$self->{clist}->itemCreate(
		0,
		0,
		-text  => kh_msg->get('gui_window::word_ass->direct_code'), # ＃直接入力
	);
	#$self->{clist}->selectionClear;
	$self->{clist}->selectionSet(0);

	# ルールファイルを読み込み
	unless (-e $self->cfile ){
		$self->{code_obj} = kh_cod::search->new;
		return 0;
	}
	
	$self->{timestamp} = ( stat($self->cfile) )[9];
	
	my $cod_obj = kh_cod::search->read_file($self->cfile);
	unless (eval(@{$cod_obj->codes})){
		$self->{code_obj} = kh_cod::search->new;
		return 0;
	}
	
	my $row = 1;
	foreach my $i (@{$cod_obj->codes}){
		$self->{clist}->add($row,-at => "$row");
		$self->{clist}->itemCreate(
			$row,
			0,
			-text  => $self->gui_jchar($i->name),
		);
		++$row;
	}
	$self->{code_obj} = $cod_obj;
	
	# 「コード無し」を付与
	$self->{clist}->add($row,-at => "$row");
	$self->{clist}->itemCreate(
		$row,
		0,
		-text  => kh_msg->get('gui_window::word_ass->no_code'), # ＃コード無し
	);
	gui_hlist->update4scroll($self->{clist});
	$self->clist_check;
	return $self;
}

#----------------------------------#
#   「直接入力」のon/off切り替え   #

sub clist_check{
	my $self = shift;
	my @s = $self->{clist}->info('selection');
	
	if ( @s && $s[0] eq '0' ){
		$self->{direct_w_l}->configure(-foreground => 'black');
		$self->{direct_w_o}->configure(-state => 'normal');
		$self->{direct_w_e}->configure(-state => 'normal');
		$self->{direct_w_e}->configure(-background => 'white');
		$self->{direct_w_e}->focus;
	} else {
		$self->{direct_w_l}->configure(-foreground => 'gray');
		$self->{direct_w_o}->configure(-state => 'disable');
		$self->{direct_w_e}->configure(-state => 'disable');
		$self->{direct_w_e}->configure(-background => 'gray');
	}
	
	my $n = @s;
	if (  $n >= 2) {
		$self->{opt_w_method1}->configure(-state => 'normal');
	} else {
		$self->{opt_w_method1}->configure(-state => 'disable');
	}
}

#--------------#
#   文書表示   #
#--------------#

sub view_doc{
	my $self = shift;
	my @selected = $self->{rlist}->infoSelection;
	unless (@selected){
		return;
	}
	my $selected = $selected[0];
	
	my ($t,$w) = $self->{code_obj}->check_a_doc($self->{result}[$selected][0]);
	
	my $view_win = gui_window::doc_view->open;
	$view_win->view(
		doc_id   => $self->{result}[$selected][0],
		tani     => $self->tani,
		parent   => $self,
		kyotyo   => $self->last_words,
		kyotyo2  => $w,
		s_search => $self->{last_strings},
		foot     => $t,
	);
}

sub next{
	my $self = shift;
	my @selected = $self->{rlist}->infoSelection;
	unless (@selected){
		return -1;
	}
	my $selected = $selected[0] + 1;
	my $max = @{$self->{result}} - 1;
	if ($selected > $max){
		$selected = $max;
	}
	my $doc_id = $self->{result}[$selected][0];
	my ($t,$w) = $self->{code_obj}->check_a_doc($doc_id);
	
	$self->{rlist}->selectionClear;
	$self->{rlist}->selectionSet($selected);
	$self->{rlist}->yview($selected);
	my $n = @{$self->{result}};
	if ($n - $selected > 7){
		$self->{rlist}->yview(scroll => -5, 'units');
	}
	
	return (undef,$doc_id,$t,$w);
}

sub prev{
	my $self = shift;
	my @selected = $self->{rlist}->infoSelection;
	unless (@selected){
		return -1;
	}
	my $selected = $selected[0] - 1;
	if ($selected < 0){
		$selected = 0;
	}
	my $doc_id = $self->{result}[$selected][0];
	my ($t,$w) = $self->{code_obj}->check_a_doc($doc_id);
	
	$self->{rlist}->selectionClear;
	$self->{rlist}->selectionSet($selected);
	$self->{rlist}->yview($selected);
	my $n = @{$self->{result}};
	if ($n - $selected > 7){
		$self->{rlist}->yview(scroll => -5, 'units');
	}
	
	return (undef,$doc_id,$t,$w);
}

sub if_next{
	my $self = shift;
	my @selected = $self->{rlist}->infoSelection;
	unless (@selected){
		return 0;
	}
	my $selected = $selected[0] ;
	my $max = @{$self->{result}} - 1;
	if ($selected < $max){
		return 1;
	} else {
		return 0;
	}
}

sub if_prev{
	my $self = shift;
	my @selected = $self->{rlist}->infoSelection;
	unless (@selected){
		return 0;
	}
	my $selected = $selected[0] ;
	if ($selected > 0){
		return 1;
	} else {
		return 0;
	}
}
sub end{
	my $check = 0;
	if ($::main_gui){
		$check = $::main_gui->if_opened('w_doc_view');
	}
	if ( $check ){
		$::main_gui->get('w_doc_view')->close;
	}
}



#--------------#
#   検索実行   #
#--------------#

sub search{
	my $self = shift;
	$self->activate;
	
	# 選択のチェック
	my @selected = $self->{clist}->info('selection');
	unless (@selected){
		my $win = $self->win_obj;
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('error_no_code'), # コードが選択されていません'
			window => \$win,
		);
		return 0;
	}
	
	# ラベルの変更
	$self->{hits_label}->configure(-text => kh_msg->get('gui_window::word_conc->hits').'0'); #   ヒット数： 0
	$self->{status_label}->configure(
		-foreground => 'red',
		-text => 'Searching...'
	);
	$self->{rlist}->delete('all');
	$self->win_obj->update;
	sleep (0.01);
	
	
	# 直接入力部分の読み込み
	$self->{code_obj}->add_direct(
		mode => $self->gui_jg( $self->{opt_direct}      ),
		raw  => $self->gui_jg( $self->{direct_w_e}->get ),
	);
	
	# 検索ロジックの呼び出し（検索実行）
	my $query_ok = $self->{code_obj}->search(
		selected => \@selected,
		tani     => $self->tani,
		method   => $self->{opt_method1},
		order    => $self->{opt_order},
	);
	
	$self->{status_label}->configure(
		-foreground => 'blue',
		-text => 'Ready.'
	);
	
	if ($query_ok){
		$self->{last_words}   = $self->{code_obj}->last_search_words;
		$self->{last_strings} = $self->{code_obj}->last_search_strings;
		$self->display(1);
	}
	return $self;
}

#------------------------#
#   検索結果の書き出し   #

sub display{
	my $self = shift;
	my $start = shift;
	$self->{current_start} = $start;

	# HListの更新
	unless ( $self->{code_obj} ){return undef;}
	$self->{result}     = $self->{code_obj}->fetch_results($start);
	$self->{rlist}->delete('all');
	if ($self->{result}){
		my $row = 0;
		foreach my $i (@{$self->{result}}){
			$self->{rlist}->add($row,-at => "$row");
			$self->{rlist}->itemCreate(
				$row,
				0,
				-text  => $self->gui_jchar($i->[1]),
			);
			++$row;
		}
	} else {
		$self->{result} = [];
	}
	
	gui_hlist->update4scroll($self->{rlist});

	# ラベルの更新
	my $num_total = $self->{code_obj}->total_hits;
	my $num_disp  = $start + kh_cod::search->docs_per_once - 1;
	my $num_disp2;
	if ($num_total > $num_disp){
		$num_disp2 = $num_disp;
	} else {
		$num_disp2 = $num_total;
	}
	if ($num_total == 0){$start = 0;}
	$self->{hits_label}->configure(
		-text => kh_msg->get('gui_window::word_conc->hits')
			.$num_total
			.kh_msg->get('gui_window::word_conc->viewing')
			."$start"
			."-$num_disp2"
	);

	# ボタンの更新
	if ($start > 1){
		$self->{btn_prev}->configure(-state => 'normal');
	} else {
		$self->{btn_prev}->configure(-state => 'disable');
	}
	if ($num_total > $num_disp){
		$self->{btn_next}->configure(-state => 'normal');
	} else {
		$self->{btn_next}->configure(-state => 'disable');
	}
	
	return $self;
}

#------------------#
#   文書のコピー   #
#------------------#
sub copy{
	my $self = shift;
	my $class = "gui_window::doc_search::".$::config_obj->os;
	bless $self, $class;
	
	$self->_copy;
}

#--------------#
#   アクセサ   #
#--------------#

sub last_words{
	my $self = shift;
	return $self->{last_words};
}

sub cfile{
	my $self = shift;
	$self->{codf_obj}->cfile;
}

sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}

sub win_name{
	return 'w_doc_search';
}

1;
