package gui_window::sql_select;
use base qw(gui_window);
use gui_jchar;
#use gui_airborne;
use gui_hlist;
use mysql_exec;

use strict;
use Tk;
use Tk::HList;
use Tk::Adjuster;
use DBI;
use Jcode;

#----------------#
#   Window描画   #
#----------------#

sub _new{
	
#--------------#
#   入力部分   #

	my $self = shift;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt( kh_msg->get('win_title') ));
	#$self->{win_obj} = $win;

	my $lf = $win->Frame(
		#-label => 'Entry',
		#-labelside => 'acrosstop',
		-borderwidth => 2,
		-height      => 200,
	);

	my $adj = $win->Adjuster(
		-widget => $lf,
		-side   => 'top',
		#-restore => 0,
	);

	my $lf2 = $win->Frame(
		#-label       => 'Result',
		#-labelside   => 'acrosstop',
		-borderwidth => 2,
	);

	$lf->Label(
		-text => 'SQL Statement:'
	)->pack(-anchor => 'w');
	
	$lf2->Label(
		-text => 'Result:'
	)->pack(-anchor => 'w');

	my $t = $lf->Scrolled(
		'Text',
		-spacing1 => 0,
		-spacing2 => 0,
		-spacing3 => 0,
		-scrollbars=> 'osoe',
		-height => 10,
		-width => 48,
		-wrap => 'none',
		-font => "TKFN",
	)->pack(-fill=>'both',-expand=>'yes',-pady => 2);
	#$t->bind("<Key>",[\&gui_jchar::check_key,Ev('K'),\$t]);
	$t->bind("<Shift-Key-Return>", sub {$self->exec;});
	$t->bind("Tk::Text", "<Shift-Key-Return>", sub {});
	$t->bind("Tk::Text", "<Shift-KeyRelease-Return>", sub {});
	$t->focus;
	
	# ドラッグ＆ドロップ
	$t->DropSite(
		-dropcommand => [\&Gui_DragDrop::read_TextFile_droped,$t],
		-droptypes => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);

	$lf->Label(
		-text => kh_msg->get('max_rows'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	my $e = $lf->Entry(
		-font  => "TKFN",
		-width => 5,
	)->pack(-side => 'left');
	$e->insert(0,'1000');


	my $server = 'MySQL '
		.mysql_exec->select("show variables like \"version\"")
		->hundle->fetch->[1];

	$lf->Label(
		-text => 
			kh_msg->get('Server')
			.$server
			.', '
			.$::project_obj->dbname
		,
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	my $sbutton = $lf->Button(
		-text    => kh_msg->get('exec'),
		-command => sub {$self->exec;},
		-font    => "TKFN"
	)->pack(-side => "right");

	my $blhelp = $win->Balloon();
	$blhelp->attach(
		$sbutton,
		-balloonmsg => '"Shift + Enter" key',
		-font => "TKFN"
	);

#----------------#
#   結果表示部   #

#	my $plane = gui_airborne->make(
#		parent      => $win,
#		parent_name => $self->win_name,
#		tower       => $lf,
#		title       => $self->gui_jchar('SQL文の実行結果'),
#	);

	my $field = $lf2->Frame()->pack(-fill => 'both', -expand => 1);

	my $list = $field->Scrolled('HList',
		-scrollbars       => 'osoe',
		-header           => '0',
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => '1',
		-padx             => '2',
		-background       => 'white',
		-height           => '15',
	)->pack(-fill=>'both',-expand => 1);

	my $frame = $lf2->Frame()->pack(-fill => 'x', -expand => '0');

	$frame->Button(
		-text    => kh_msg->gget('copy'),
		-command => sub {gui_hlist->copy($self->list);},
		-font    => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	my $label = $frame->Label(
		-text => kh_msg->get('rows'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	#$plane->make_control($frame);

	$lf->pack(-side => 'top', -fill => 'x');
	$adj->pack(-side => 'top', -fill => 'x', -pady => 2, -padx => 4);
	$lf2->pack(-side => 'top', -fill => 'both', -expand => 1);

	$self->{entry} = $e;
	$self->{text}  = $t;
	$self->{list}  = $list;
	$self->{label} = $label;
	#$self->{plane} = $plane;
	$self->{field} = $field;
	
	return $self;
}

#--------------#
#   イベント   #
#--------------#

#--------------#
#   検索実行   #

sub exec{
	my $self = shift;
	
	my $all = $self->gui_jg( $self->text->get("1.0","end"),'reserve_rn');
	$all =~ s/\r\n/\n/g;
	my @temp = split /\;\n\n/, $all;
	
	my $t;
	foreach my $i (@temp){
		# SQL実行
		my $tc = mysql_exec->select($i);
		# エラーチェック
		if ( $tc->err ){
			my $msg = kh_msg->get('sql_error')."\n\n".$self->gui_jchar($tc->err);
			my $w = $self->win_obj;
			gui_errormsg->open(
				type   => 'msg',
				msg    => $msg,
				window => \$w
			);
			return 0;
		}
		$t = $tc;
	}
	
	# 書き出すべき結果があるかどうかをチェック
	unless ($t->hundle->{'NUM_OF_FIELDS'}){
		$self->label->configure(
			-text, kh_msg->get('rows').'n/a'
		);
		return 1;
	}
	
	# 結果の書き出し
	$self->list->destroy;                                   # 入れ物
	$self->{list} = $self->field->Scrolled('HList',
		-scrollbars       => 'osoe',
		-header           => '1',
		-itemtype         => 'text',
		-font             => 'TKFN',
		-columns          => $t->hundle->{NUM_OF_FIELDS},
		-padx             => '2',
		-background       => 'white',
		-height           => '4',
		-selectforeground   => $::config_obj->color_ListHL_fore,
		-selectbackground   => $::config_obj->color_ListHL_back,
		-selectborderwidth  => 0,
		-highlightthickness => 0,
		-selectmode       => 'extended'
	)->pack(-fill=>'both',-expand => 'yes');
	my $n = 0;
	foreach my $i (@{$t->hundle->{NAME}}){
		$self->list->header('create',$n,-text => $self->gui_jchar($i) );
		++$n;
	}
	
	my $row = 0;                                            # 中身
	my $max = $self->max; my $frag = 0;
	while (my $i = $t->hundle->fetch){
		$self->list->add($row,-at => "$row");
		my $col = 0;
		foreach my $h (@{$i}){
			$self->list->itemCreate($row,$col,-text => $self->gui_jchar($h)); # nkf('-s -E',$h)
			++$col;
		}
		++$row;
		if ($row == $max){
			$frag = 1;
			last;
		}
	}
	if ($frag){                                             # 出力行数カウント
		while (my $i = $t->hundle->fetch){
			++$row;
		}
	}
	$self->label->configure(-text,kh_msg->get('rows')."$row");
	
	#$self->plane->frame->focus;
}


#sub close{
#	my $self = shift;
#	$self->plane->close;
#}

#sub start{
#	my $self = shift;
#	$self->plane->start;
#	$self->text->focus;
#}

#--------------#
#   アクセサ   #
#--------------#

sub max{
	my $self = shift;
	return $self->{entry}->get;
}

sub text{
	my $self = shift;
	return $self->{text};
}

sub list{
	my $self = shift;
	return $self->{list};
}

sub field{
	my $self = shift;
	return $self->{field};
}

sub label{
	my $self = shift;
	return $self->{label};
}


sub win_name{
	return 'w_tool_sql_select';
}

#sub plane{
#	my $self = shift;
#	return $self->{plane};
#}


1;
