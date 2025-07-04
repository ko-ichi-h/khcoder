package gui_window::main::inner;
use strict;

#----------------------#
#   Windowの中身作成   #
#----------------------#

sub make{
	my $class = shift;
	my $mw   = shift;
	my $self;

	# プロジェクト情報
	my $lab_fra1 = $mw->LabFrame(
		-label       => 'Project',
		-labelside   => 'acrosstop',
		-borderwidth => 2,
	);

	# データベース情報
	my $lab_fra2 = $mw->LabFrame(
		-label       => 'Database Stats',
		-labelside   => 'acrosstop',
		-borderwidth => '2'
	);

	# 言語の切り替え（これらのフレームは後でpack()する）
	my $fra3 = $mw->Frame();


	# プロジェクト情報
	my $fra1 = $lab_fra1->Frame()->pack(
		-expand => 1,
		-fill => 'both',
	);
	
	$fra1->Label(
		-text => kh_msg->get('target'),#gui_window->gui_jchar('現在のプロジェクト：','euc'),
		-font => "TKFN"
	)->grid(
		-column => 0,
		-row    => 0,
		-sticky => 'w',
		-in     => $fra1,
	);
	
	my $cupro = $fra1->Entry(
		-width      => $::config_obj->mw_entry_length,
		-background => 'gray',
		-font       => 'TKFN',
		-state      => 'disable',
	)->grid(
		-column => 1,
		-row    => 0,
		-sticky => 'ew',
		-in     => $fra1,
		-pady   => 1,
	);
	gui_window->disabled_entry_configure($cupro);
	
	$fra1->Label(
		-text => kh_msg->get('memo'),#gui_window->gui_jchar('説明（メモ）：','euc'),
		-font => "TKFN"
	)->grid(
		-column => 0,
		-row    => 1,
		-sticky => 'w',
		-in     => $fra1,
	);

	my $cuprom = $fra1->Entry(
		-width      => $::config_obj->mw_entry_length,
		-background => 'gray',
		-font       => 'TKFN',
		-state      => 'disable',
	)->grid(
		-column => 1,
		-row    => 1,
		-sticky => 'ew',
		-in     => $fra1,
		-pady   => 1,
	);
	gui_window->disabled_entry_configure($cuprom);
	$fra1->gridColumnconfigure(1, -weight => 1);


	# データベース情報
	my $fra2 = $lab_fra2->Frame()->pack(
		-fill => 'both',
		-expand => 1,
	);

	$fra2->Label(
		-text => kh_msg->get('tokens'),#gui_window->gui_jchar('総抽出語数：','euc'),
		-font => "TKFN"
	)->grid(
		-column => 0,
		-row    => 0,
		-sticky => 'w',
	);
	$self->{ent_num1} = $fra2->Entry(
		-width      => $::config_obj->mw_entry_length,
		-background => 'gray',
		-font       => 'TKFN',
		-state      => 'disable',
	)->grid(
		-column => 1,
		-row    => 0,
		-sticky => 'we',
		-pady   => 1,
	);
	gui_window->disabled_entry_configure($self->{ent_num1});

	$fra2->Label(
		-font => "TKFN",
		-text => kh_msg->get('types'),#gui_window->gui_jchar('異なり語数（使用）：','euc')
	)->grid(
		-column => 0,
		-row    => 1,
		-sticky => 'w',
	);
	$self->{ent_num2} = $fra2->Entry(
		-width      => $::config_obj->mw_entry_length,
		-background => 'gray',
		-font       => 'TKFN',
		-state      => 'disable',
	)->grid(
		-column => 1,
		-row    => 1,
		-sticky => 'ew',
		-pady   => 1,
	);
	gui_window->disabled_entry_configure($self->{ent_num2});

	$fra2->Label(
		-font => "TKFN",
		-text => kh_msg->get('docs'),#gui_window->gui_jchar('文書の単純集計：','euc')
	)->grid(
		-column => 0,
		-row    => 2,
		-sticky => 'w',
	);

	my $hlist = $fra2->Scrolled(
		'HList',
		-scrollbars         => 'osoe',
		-font               => 'TKFN',
		-selectmode         => 'none',
		-indicator          => 0,
		-command            => sub{$self->unselect;},
		-highlightthickness => 0,
		-columns            => 2,
		-borderwidth        => 2,
		-height             => 4,
		-header             => 1,
		-width      => $::config_obj->mw_entry_length - 2,
	)->grid(
		-column => 1,
		-row    => 2,
		-sticky => 'nswe',
		-pady   => 1,
	);

	$hlist->header(
		'create',
		0,
		-text=>kh_msg->get('units'),#gui_window->gui_jchar('集計単位','euc')
	);
	$hlist->header(
		'create',
		1,
		-text => kh_msg->get('cases'),#gui_window->gui_jchar('ケース数','euc')
	);

	$fra2->gridColumnconfigure(1, -weight => 1, -minsize => 30);
	$fra2->gridRowconfigure(2, -weight => 1);

	# 言語の切り替え
	$self->{optmenu_lg_v} = $::config_obj->msg_lang;
	$self->{optmenu_lg} = gui_widget::optmenu->open(
		parent  => $fra3,
		pack    => {-side => 'right'},
		options =>
			[
				[ 'Chinese'  => 'cn'],
				[ 'English'  => 'en'],
				[ 'French'   => 'fr'],
				[ 'Japanese' => 'jp'],
				[ 'Korean'   => 'kr'],
				[ 'Spanish'  => 'es'],
			],
		variable => \$self->{optmenu_lg_v},
		command  => sub {$self->switch_lang;},
	);

	$fra3->Label(
		-text => 'Interface Language: '
	)->pack(-side => 'right');

	$lab_fra1->pack(
		-fill => 'x',
	);
	$lab_fra2->pack(
		-fill => 'both',
		-expand => 1,
	);
	$fra3->pack(
		-fill => 'x',
	);

	$self->{e_curent_project} = $cupro;
	$self->{e_project_memo}   = $cuprom;
	$self->{hlist}            = $hlist;
	bless $self, $class;
	
#	$self->refresh;
	
	return $self;
}

sub switch_lang{
	my $self = shift;
	
	my $v = gui_window->gui_jg( $self->{optmenu_lg_v} );
	
	unless ($::config_obj->msg_lang eq $v){
		$::config_obj->msg_lang($v);
		$::config_obj->msg_lang_set($v);
		$::config_obj->save;
		gui_errormsg->open(
			type => 'msg',
			icon => 'info',
			msg  => "The user interface language has been changed.\nPlease restart KH Coder for the change to take effect.",
		);
	}
}

sub unselect{
	my $self = shift;
	$self->hlist->selectionClear();
}

#--------------------#
#   中身の書き換え   #
#--------------------#
sub refresh{
	my $self = shift;
	my %args = @_;
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
			$title = $::project_obj->file_short_name_mw;
		}
		$title .= ' - KH Coder';
		$mw->title(gui_window->gui_jt($title));
		$self->entry('e_curent_project', gui_window->gui_jchar($::project_obj->file_short_name_mw));
		$self->entry('e_project_memo', gui_window->gui_jchar($::project_obj->comment));
		
		if ($::project_obj->status_morpho){       # 前処理が完了している場合
			# 抽出語数
			$self->entry('ent_num1', num_format(mysql_words->num_all)." (".num_format(mysql_words->num).")");
			$self->entry('ent_num2', num_format(mysql_words->num_kinds_all." (".mysql_words->num_kinds.")") );
			# 集計単位
			my %name = (
				"bun" => kh_msg->gget('sentence'),
				"dan" => kh_msg->gget('paragraph'),
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
					push @list, [gui_window->gui_jchar($name{$i}), num_format($num)];
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

	# refresh Suggest window
	if ($::main_gui->if_opened('suggest') &! $args{-dont_refresh_suggest} == 1){
		my $suggest = $::main_gui->get('suggest');
		$suggest->refresh;
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
