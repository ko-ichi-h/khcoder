package gui_window::word_ass;
use base qw(gui_window);
use vars qw($filter);

use Tk;
use strict;

use gui_widget::optmenu;
use kh_cod::asso;

#-------------#
#   GUI作製   #
#-------------#

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $mw->Toplevel;
	$win->focus;
	$win->title(Jcode->new('抽出語 連関規則')->sjis);
	$self->{win_obj} = $win;
	
	#--------------------#
	#   検索オプション   #
	
	my $lf = $win->LabFrame(
		-label => 'Search Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');

	my $left = $lf->Frame()->pack(-side => 'left', -fill => 'x', -expand => 1);
	my $right = $lf->Frame()->pack(-side => 'right');
	
	# コード選択
	$left->Label(
		-text => Jcode->new('・コード選択')->sjis,
		-font => "TKFN"
	)->pack(-anchor => 'w');
	
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
		-selectforeground => 'brown',
		-selectbackground => 'cyan',
		-selectmode       => 'extended',
		-command          => sub{ $self->search; },
		-browsecmd        => sub{ $self->clist_check; },
	)->pack(-anchor => 'w', -padx => '4',-pady => '2', -fill => 'both',-expand => 1);

	# コーディングルール・ファイル
	my %pack0 = (
			-anchor => 'w',
	);
	$self->{codf_obj} = gui_widget::codf->open(
		parent   => $right,
		command  => sub{$self->read_code;},
		r_button => 1,
		pack     => \%pack0,
	);

	# 直接入力フレーム
	my $f3 = $right->Frame()->pack(-fill => 'x', -pady => 6);
	$self->{direct_w_l} = $f3->Label(
		text => Jcode->new('直接入力：')->sjis,
		font => "TKFN"
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
		-text    => Jcode->new('集計')->sjis,
		-command => sub{ $win->after(10,sub{$self->search;});}
	)->pack(-side => 'right',-padx => 4);
	$win->Balloon()->attach(
		$self->{btn_search},
		-balloonmsg => '"Shinf + Enter"',
		-font       => "TKFN"
	);

	$f2->Label(-text => '   ')->pack(-side => 'right');

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
		text => Jcode->new('集計単位：')->sjis,
		font => "TKFN"
	)->pack(anchor => 'w', side => 'right');

	$f2->Label(-text => '  ')->pack(-side => 'right');

	$self->{opt_w_method1} = gui_widget::optmenu->open(
		parent  => $f2,
		pack    => {-pady => '1', -side => 'right'},
		options =>
			[
				[Jcode->new('AND検索')->sjis, 'and'],
				[Jcode->new('OR検索')->sjis , 'or']
			],
		variable => \$self->{opt_method1},
	);

	#--------------#
	#   検索結果   #
	
	my $rf = $win->LabFrame(
		-label => 'Result',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both',-expand => 'yes',-anchor => 'n');

	$self->{rlist} = $rf->Scrolled(
		'HList',
		-scrollbars       => 'osoe',
		-header           => 1,
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => 7,
		-padx             => 2,
		-background       => 'white',
		-selectforeground => 'brown',
		-selectbackground => 'cyan',
		-selectmode       => 'extended',
		-height           => 10,
		-command          => sub {$self->conc;}
	)->pack(-fill =>'both',-expand => 'yes');

	$self->{rlist}->header('create',0,-text => Jcode->new('順位')->sjis);
	$self->{rlist}->header('create',1,-text => Jcode->new('単語')->sjis);
	$self->{rlist}->header('create',2,-text => Jcode->new('品詞')->sjis);
	$self->{rlist}->header('create',3,-text => Jcode->new('全体')->sjis);
	$self->{rlist}->header('create',4,-text => Jcode->new('共起')->sjis);
	$self->{rlist}->header('create',5,-text => Jcode->new('条件付き確立')->sjis);
	$self->{rlist}->header('create',6,-text => Jcode->new(' ソート')->sjis);

	my $f5 = $rf->Frame()->pack(-fill => 'x', -pady => 2);
	
	$self->{status_label} = $f5->Label(
		text       => 'Ready.',
		font       => "TKFN",
		foreground => 'blue'
	)->pack(side => 'right');

	$f5->Button(
		-font    => "TKFN",
		-text    => Jcode->new('コピー')->sjis,
		#-width   => 8,
		-command => sub{ $win->after(10,sub{gui_hlist->copy($self->{rlist});});},
		-borderwidth => 1
	)->pack(-side => 'left');

	$f5->Button(
		-font    => "TKFN",
		#-width   => 8,
		-text    => Jcode->new('コンコーダンス')->sjis,
		-command => sub{ $win->after(10,sub{$self->conc;});},
		-borderwidth => 1
	)->pack(-side => 'left',-padx => 2);

	$f5->Label(
		-text => Jcode->new(' ソート：')->sjis,
		-font => "TKFN",
	)->pack(-side => 'left');

	gui_widget::optmenu->open(
		parent  => $f5,
		pack    => {-side => 'left'},
		options =>
			[
				[Jcode->new('確率差')->sjis , 'sa'],
				[Jcode->new('確率比')->sjis , 'hi'],
				[Jcode->new('χ2乗')->sjis , 'chi'],
			],
		variable => \$self->{opt_order},
		command  => sub{$self->display;}
	);

	$f5->Label(
		-text => Jcode->new(' ')->sjis,
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{btn_prev} = $f5->Button(
		-text        => Jcode->new('フィルタ設定')->sjis,
		-font        => "TKFN",
		-command     =>
			sub{
				gui_window::word_ass_opt->open;
			},
		-borderwidth => 1,
		-state       => 'normal',
	)->pack(-side => 'left',-padx => 2);

	$self->{hits_label} = $f5->Label(
		text       => Jcode->new('  文書数：0')->sjis,
		font       => "TKFN",
	)->pack(side => 'left',);

	#--------------------------#
	#   フィルタ設定の初期化   #

	$filter = undef;
	$filter->{limit}   = 200;                  # LIMIT数
	$filter->{min_doc} = 1;                    # 最低文書数
	my $h = mysql_exec->select("               # 品詞によるフィルタ
		SELECT khhinshi_id
		FROM   hselection
		WHERE  ifuse = 1
	",1)->hundle;
	while (my $i = $h->fetch){
		$filter->{hinshi}{$i->[0]} = 1;
	}

	$self->read_code;
	$self->clist_check;
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
		-text  => Jcode->new('＃直接入力')->sjis,
	);
	$self->{clist}->selectionClear;
	$self->{clist}->selectionSet(0);

	# ルールファイルを読み込み
	unless (-e $self->cfile ){
		$self->{code_obj} = kh_cod::asso->new;
		return 0;
	}
	
	my $cod_obj = kh_cod::asso->read_file($self->cfile);
	unless (eval(@{$cod_obj->codes})){
		$self->{code_obj} = kh_cod::asso->new;
		return 0;
	}
	
	my $row = 1;
	foreach my $i (@{$cod_obj->codes}){
		$self->{clist}->add($row,-at => "$row");
		$self->{clist}->itemCreate(
			$row,
			0,
			-text  => Jcode->new($i->name)->sjis,
		);
		++$row;
	}
	$self->{code_obj} = $cod_obj;
	
	# 「コード無し」を付与
	$self->{clist}->add($row,-at => "$row");
	$self->{clist}->itemCreate(
		$row,
		0,
		-text  => Jcode->new('＃コード無し')->sjis,
	);
	
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
#   検索実行   #
#--------------#

sub search{
	my $self = shift;
	
	# 選択のチェック
	my @selected = $self->{clist}->info('selection');
	unless (@selected){
		my $win = $self->win_obj;
		gui_errormsg->open(
			type   => 'msg',
			msg    => Jcode->new('コードが選択されていません')->sjis,
			window => \$win,
		);
		return 0;
	}
	
	# ラベルの変更
	$self->{hits_label}->configure(-text => Jcode->new('  文書数： 0')->sjis);
	$self->{status_label}->configure(
		-foreground => 'red',
		-text => 'Searcing...'
	);
	$self->{rlist}->delete('all');
	$self->win_obj->update;
	sleep (0.01);
	
	
	# 直接入力部分の読み込み
	$self->{code_obj}->add_direct(
		mode => $self->{opt_direct},
		raw  => $self->{direct_w_e}->get,
	);
	
	# 検索ロジックの呼び出し（検索実行）
	my $query_ok = $self->{code_obj}->asso(
		selected => \@selected,
		tani     => $self->tani,
		method   => $self->{opt_method1},
	);
	
	$self->{status_label}->configure(
		-foreground => 'blue',
		-text => 'Ready.'
	);
	
	if ($query_ok){
		$self->display;
	}
	return $self;
}

#------------------------#
#   検索結果の書き出し   #

sub display{
	my $self = shift;
	
	unless ( $self->{code_obj}          ) {return undef;}
	unless ( $self->{code_obj}->doc_num ) {return undef;}
	
	# HListの更新
	$self->{result} = $self->{code_obj}->fetch_results(
		order  => $self->{opt_order},
		filter => $filter,
	);

	my $numb_style = $self->{rlist}->ItemStyle(
		'text',
		-anchor => 'e',
		-background => 'white',
		-font => "TKFN"
	);

	$self->{rlist}->delete('all');
	if ($self->{result}){
		my $row = 0;
		foreach my $i (@{$self->{result}}){
			$self->{rlist}->add($row,-at => "$row");
			$self->{rlist}->itemCreate(           # 順位
				$row,
				0,
				-text  => $row + 1,
				-style => $numb_style
			);
			$self->{rlist}->itemCreate(           # 単語
				$row,
				1,
				-text  => Jcode->new($i->[0])->sjis,
			);
			$self->{rlist}->itemCreate(           # 品詞
				$row,
				2,
				-text  => Jcode->new($i->[1])->sjis,
			);
			$self->{rlist}->itemCreate(           # 全体
				$row,
				3,
				-text  => "$i->[2]"." ("."$i->[3]".")",
				-style => $numb_style
			);
			$self->{rlist}->itemCreate(           # 共起
				$row,
				4,
				-text  => "$i->[4]",
				-style => $numb_style
			);
			$self->{rlist}->itemCreate(           # 条件付き確立
				$row,
				5,
				-text  => "$i->[5]",
				-style => $numb_style
			);
			$self->{rlist}->itemCreate(           # Sort
				$row,
				6,
				-text  => " ".sprintf("%.4f",$i->[6]),
				-style => $numb_style
			);
			++$row;
		}
	} else {
		$self->{result} = [];
	}
	
	# ラベルの更新
	my $num_total = $self->{code_obj}->doc_num;
	$self->{rlist}->yview(0);
	$self->{hits_label}->configure(-text => Jcode->new("  文書数： $num_total")->sjis);

	return $self;
}

#----------------------------#
#   コンコーダンス呼び出し   #
#----------------------------#
sub conc{
	use gui_window::word_conc;
	my $self = shift;

	# 変数取得
	my @selected = $self->{rlist}->infoSelection;
	unless(@selected){
		return;
	}
	my $selected = $selected[0];
	my ($query, $hinshi);
	$query = Jcode->new($self->{result}->[$selected][0])->sjis;
	$hinshi = Jcode->new($self->{result}->[$selected][1])->sjis;
	
	# コンコーダンスの呼び出し
	my $conc = gui_window::word_conc->open;
	$conc->entry->delete(0,'end');
	$conc->entry4->delete(0,'end');
	$conc->entry2->delete(0,'end');
	$conc->entry->insert('end',$query);
	$conc->entry4->insert('end',$hinshi);
	$conc->search;

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
	return 'w_doc_ass';
}

1;