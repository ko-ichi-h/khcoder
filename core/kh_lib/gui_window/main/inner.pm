package gui_window::main::inner;
use strict;

#----------------------#
#   Windowの中身作成   #
#----------------------#

sub make{
	my $class = shift;
	my $gui   = shift;
	my $self;
	my $mw = ${$gui}->mw;

	# プロジェクト情報
	my $fra1 = $mw->LabFrame(
		-label       => 'Project',
		-labelside   => 'acrosstop',
		-borderwidth => 2,
	)->pack(
		-fill   => 'x',
		-expand => '0',
		-anchor => 'n',
		-side   => 'top'
	);

	my $fra1a = $fra1->Frame(-borderwidth => 2) ->pack(-fill => 'x');
	my $fra1b = $fra1->Frame(-borderwidth => 2) ->pack(-fill => 'x');
	
	my $msg = gui_window->gui_jchar('現在のプロジェクト：','euc');
	$fra1a->Label(
		-text => "$msg",
		-font => "TKFN"
	)->pack(-anchor=>'w',-side=>'left');
	
	my $cupro = $fra1a->Entry(
		-width      => $::config_obj->mw_entry_length,
		-background => 'gray',
		-font       => 'TKFN',
		-state      => 'disable',
	)->pack(-anchor=>'e',-side=>'right');
	gui_window->disabled_entry_configure($cupro);
	
	$msg = gui_window->gui_jchar('説明（メモ）：','euc');
	$fra1b->Label(
		-text => "$msg",
		-font => "TKFN"
	)->pack(-anchor=>'w',-side=>'left');

	my $cuprom = $fra1b->Entry(
		-width      => $::config_obj->mw_entry_length,
		-background => 'gray',
		-font       => 'TKFN',
		-state      => 'disable',
	)->pack(-anchor=>'e',-side=>'right');
	gui_window->disabled_entry_configure($cuprom);

	# データベース情報
	my $fra2 = $mw->LabFrame(
		-label       => 'Database Stats',
		-labelside   => 'acrosstop',
		-borderwidth => '2'
	)->pack(
		-fill   => 'both',
		-expand => 'yes',
		-anchor => 'n'
	);

	my $fra2_1 = $fra2->Frame(-borderwidth => 2)->pack(-fill => 'x');
	$fra2_1->Label(
		-text => gui_window->gui_jchar('総抽出語数：','euc'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_num1} = $fra2_1->Entry(
		-width      => $::config_obj->mw_entry_length,
		-background => 'gray',
		-font       => 'TKFN',
		-state      => 'disable',
	)->pack(-anchor=>'e',-side=>'right');
	gui_window->disabled_entry_configure($self->{ent_num1});

	my $fra2_2 = $fra2->Frame(-borderwidth => 2)->pack(-fill => 'x');
	$fra2_2->Label(
		-font => "TKFN",
		-text => gui_window->gui_jchar('異なり語数（使用）：','euc')
	)->pack(-side => 'left');
	$self->{ent_num2} = $fra2_2->Entry(
		-width      => $::config_obj->mw_entry_length,
		-background => 'gray',
		-font       => 'TKFN',
		-state      => 'disable',
	)->pack(-anchor=>'e',-side=>'right');
	gui_window->disabled_entry_configure($self->{ent_num2});

	my $fra2_3 = $fra2->Frame(-borderwidth => 2)->pack(-fill => 'both', -expand => 'y');
	$fra2_3->Label(
		-font => "TKFN",
		-text => gui_window->gui_jchar('文書の単純集計：','euc')
	)->pack(-side => 'left');

	my $hlist = $fra2_3->Scrolled(
		'HList',
		-scrollbars         => 'osoe',
		-font               => 'TKFN',
		-selectmode         => 'none',
		-indicator          => 0,
		-command            => sub{$mw->after(10,sub{$self->unselect;});},
		#-highlightthickness => 0,
		-columns            => 2,
		#-borderwidth        => 0,
		-height             => 3,
		-header             => 1,
		-width      => $::config_obj->mw_entry_length - 2,
	)->pack(-side => 'right', -anchor => 'e', -fill => 'y');

	$hlist->header('create',0,-text => gui_window->gui_jchar('集計単位','euc'));
	$hlist->header('create',1,-text => gui_window->gui_jchar('ケース数','euc'));

	sub unselect{
		my $self = shift;
		$self->hlist->selectionClear();
		#print "fuck\n";
	}

	$self->{e_curent_project} = $cupro;
	$self->{e_project_memo}   = $cuprom;
	$self->{hlist}            = $hlist;
	bless $self, $class;
	
#	$self->refresh;
	
	return $self;
}

#--------------------#
#   中身の書き換え   #
#--------------------#
sub refresh{
	my $self = shift;
	my $mw = $::main_gui->mw;
	
	# 初期化
	$self->hlist->delete('all');
	$mw->title('KH Coder');
	$self->entry('e_curent_project', '');
	$self->entry('e_project_memo', '');
	$self->entry('ent_num1', '');
	$self->entry('ent_num2', '');
	
	my @list = ();

	if ($::project_obj){                    # プロジェクトを開いている場合
		my $title;
		if ( length($::project_obj->comment) ){
			$title = $::project_obj->comment;
		} else {
			$title = $::project_obj->file_short_name;
		}
		$title .= ' - KH Coder';
		$mw->title(gui_window->gui_jt($title));
		$self->entry('e_curent_project', gui_window->gui_jchar($::project_obj->file_short_name));
		$self->entry('e_project_memo', gui_window->gui_jchar($::project_obj->comment));
		
		if ($::project_obj->status_morpho){       # 前処理が完了している場合
			# 抽出語数
			$self->entry('ent_num1', num_format(mysql_words->num_all));
			$self->entry('ent_num2', num_format(mysql_words->num_kinds_all." (".mysql_words->num_kinds.")") );
			# 集計単位
			my %name = (
				"bun" => "文",
				"dan" => "段落",
				"h5"  => "H5",
				"h4"  => "H4",
				"h3"  => "H3",
				"h2"  => "H2",
				"h1"  => "H1",
			);
			my @list0 = ("bun","dan","h5","h4","h3","h2","h1");
			foreach my $i (@list0){
				if (
					mysql_exec->select(
						"select status from status where name = \'$i\'",1
					)->hundle->fetch->[0]
				){
					my $num = mysql_exec->select(
						"SELECT count(*) FROM $i"
					)->hundle->fetch->[0];
					push @list, [gui_window->gui_jchar($name{$i},'euc'), num_format($num)];
				}
			}
		}
	}
	
	# 「文書の単純集計：」の更新
	my $right = $self->hlist->ItemStyle('text',-anchor => 'e',-font => "TKFN");
	my $row = 0;
	foreach my $i (@list){
		$self->hlist->add($row,-at => $row);
		$self->hlist->itemCreate(
			$row,0,
			-itemtype  => 'text',
			-text      => $i->[0]
		);
		$self->hlist->itemCreate(
			$row,1,
			-itemtype  => 'text',
			-style     => $right,
			-text      => $i->[1]
		);
		++$row;
	}
}

#--------------#
#   アクセサ   #
#--------------#

# エントリー関係
# $obj->entry('entry_name','content');
# entry names: e_curent_project, e_project_memo, e_words_num

sub entry{
	my $self = shift;
	my $entry_name = shift;
	my $entry_cont = shift;
	
	my $ent = $self->{$entry_name};
	$ent->configure(-state,'normal');
	$ent->delete(0, 'end');
	$ent->insert('0',"$entry_cont");
	$ent->configure(-state,'disable');
}

sub hlist{
	my $self = shift;
	return $self->{hlist};
}

# 数字の3桁ごとにコンマを・・・
sub num_format{
	$_ = shift;
	1 while s/(.*\d)(\d\d\d)/$1,$2/;
	return $_;
}

1;
