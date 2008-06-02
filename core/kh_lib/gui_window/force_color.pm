package gui_window::force_color;
use base qw(gui_window);
use strict;
use Tk;

#----------------------#
#   インターフェイス   #
#----------------------#

#------------------#
#   Windowの作成   #

sub _new{
	my $self = shift;
	my %args = @_;
	$self->{parent} = $args{parent};
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt('強調する言葉'));

	# リスト用フレーム
	my $lf = $win->LabFrame(
		-label => 'List',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both',-expand => 'y');

	$lf->Label(
		-text => $self->gui_jchar('■以下の言葉が常に強調されます。'),
		-font => "TKFN",
	)->pack(
		-anchor =>'w',
		-padx   => 2,
	);

	my $plis = $lf->Scrolled(
		'HList',
		-scrollbars=> 'osoe',
		-header => 1,
		-width => 30,
		#-command => sub{ $mw->after(10,sub{$self->_open;});},
		-itemtype => 'text',
		-font => 'TKFN',
		-columns => 2,
		-padx => 2,
		-background=> 'white',
		-selectforeground=> 'brown',
		-selectbackground=> 'cyan',
		-selectmode => 'extended',
	)->pack(-fill=>'both',-expand => 'yes',-pady => 2);
	$plis->header('create',0,-text => $self->gui_jchar('　言葉　'));
	$plis->header('create',1,-text => $self->gui_jchar('　種類　'));

	$lf->Button(
		-text => $self->gui_jchar('選択した言葉を削除'),
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->delete;});}
	)->pack(-anchor => 'e');

	# 追加用フレーム
	my $lf2 = $win->LabFrame(
		-label => 'Add',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	my $lf2a = $lf2->Frame()->pack(-fill => 'x',-expand => 'y');

	$lf2a->Label(
		-text => $self->gui_jchar('言葉：'),
		-font => "TKFN",
	)->pack(
		-side => 'left',
		-pady => 2
	);
	$self->{entry} = $lf2a->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-side => 'left',-fill => 'x',-expand => 'y');
	$self->{entry}->bind(
		"<Key>",
		[\&gui_jchar::check_key_e,Ev('K'),\$self->{entry}]
	);
	$self->{entry}->bind("<Key-Return>",sub{$self->add;});

	$lf2->Label(
		-text => $self->gui_jchar('種類：'),
		-font => "TKFN",
	)->pack(
		-side => 'left'
	);
	$self->{menu} = gui_widget::optmenu->open(
		parent  => $lf2,
		width   => 6,
		pack    => {-side => 'left'},
		options => [
			[$self->gui_jchar('抽出語'), '1'],
			[$self->gui_jchar('文字列'), '0'],
		],
		variable => \$self->{type},
	);
	$lf2->Button(
		-text => $self->gui_jchar('追加'),
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->add;});}
	)->pack(-anchor => 'e');

	$win->Button(
		-text => $self->gui_jchar('閉じる'),
		#-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-anchor => 'c',);
	
	$self->{list}    = $plis;
	#$self->{win_obj} = $win;
	
	$self->refresh;
	return $self;
}

#----------------------#
#   強調リストの更新   #

sub refresh{
	my $self = shift;
	$self->list->delete('all');
	my $row = 0;
	my $h = mysql_exec->select("
		SELECT name, type
		FROM d_force
		ORDER BY id
	",1)->hundle;
	while (my $i = $h->fetch){
		$self->list->add($row,-at => "$row");
		$self->list->itemCreate($row,0,-text => $self->gui_jchar($i->[0]));
		
		if ($i->[1]){
			$self->list->itemCreate(
				$row,
				1,
				-text => $self->gui_jchar('抽出語')
			);
		} else {
			$self->list->itemCreate(
				$row,
				1,
				-text => $self->gui_jchar('文字列')
			);
		}
		++$row;
	}
}

#--------------#
#   ロジック   #
#--------------#

#----------#
#   追加   #

sub add{
	my $self = shift;
	
	my ($word, $type) = (
		Jcode->new($self->gui_jg($self->{entry}->get),'sjis')->euc,
		$self->gui_jg($self->{type})
	);

	# 入力があるかどうかをチェック
	unless (length($word)){
		gui_errormsg->open(
			msg    => '言葉が入力されていません。',
			type   => 'msg',
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	# 同じものが既に無いかどうかチェック
	my $chk = mysql_exec->select("
		SELECT id FROM d_force WHERE name = \'$word\' AND type= $type
	",1)->hundle->rows;
	if ($chk){
		gui_errormsg->open(
			msg    => 'その言葉は既に登録されています。',
			type   => 'msg',
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	# 追加
	mysql_exec->do("
		INSERT INTO d_force (name, type) VALUES (\'$word\', $type)
	",1);
	
	# エントリのクリア
	$self->{entry}->delete(0,'end');

	# リスト更新
	$self->refresh;
	$self->{edited} = 1;
	
	$self->{parent}->refresh;
	return $self;
}

#----------#
#   削除   #
sub delete{
	my $self = shift;
	
	# 削除
	my @selected = $self->{list}->infoSelection;
	foreach my $i (@selected){
		my $word = Jcode->new(
			$self->gui_jg($self->list->itemCget($i,0,-text))
		)->euc;
		my $type = Jcode->new(
			$self->gui_jg($self->list->itemCget($i,1,-text))
		)->euc;
		if ($type eq '抽出語'){
			$type = 1;
		} else {
			$type = 0;
		}
		mysql_exec->do("
			DELETE FROM d_force
			WHERE
				name = \'$word\'
				AND type = $type
		",1);
		
	}
	
	# リスト更新
	$self->refresh;
	$self->{edited} = 1;
	
	$self->{parent}->refresh;
	return $self;
}

#--------------#
#   アクセサ   #
#--------------#

sub list{
	my $self = shift;
	return $self->{list};
}

sub win_name{
	return 'w_force_color'; 
}
1;