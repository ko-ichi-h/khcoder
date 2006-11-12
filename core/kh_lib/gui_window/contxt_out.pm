package gui_window::contxt_out;
use base qw(gui_window);
use strict;

use gui_widget::tani_and_o;
use gui_widget::hinshi;
use mysql_crossout;
use mysql_contxt;

use gui_window::contxt_out::spss;
use gui_window::contxt_out::csv;
use gui_window::contxt_out::tab;

#-------------#
#   GUI作製   #
#-------------#

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jchar($self->label));
	#$self->{win_obj} = $win;

	# 各種フレーム
	my $wf = $win->Frame()->pack(-fill => 'both', -expand => 1);
	my $lf = $wf->LabFrame(
		-label => 'Words',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1, -side => 'left');
	my $rf = $wf->LabFrame(
		-label => 'Words for Context',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1, -side => 'left');
	my $of = $win ->LabFrame(
		-label => 'Optins',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-anchor => 'w', -side => 'left');
	my $bf = $win ->Frame(
		-borderwidth => 2
	)->pack(-anchor => 'se', -side => 'right');

	#--------------------#
	#   集計オプション   #

	$of->Label(
		-text       => $self->gui_jchar('・集計単位と重み付けの設定'),
		-font       => "TKFN",
	)->pack(-anchor => 'w');

	$of->Label(
		-text => $self->gui_jchar('　　'),
		-font => "TKFN"
	)->pack(-side => 'left',-fill => 'y',-expand => 1);

	$self->{tani_obj} = gui_widget::tani_and_o->open(
		parent => $of,
		pack   => {
			-anchor => 'w',
			-pady   => 2,
			-side   => 'left'
		}
	);

	#--------------------------------#
	#   文脈計算に使用する語の選択   #

	my $right = $rf->Frame()->pack(-fill => 'both', -expand => 1);
	$right->Label(
		-text       => $self->gui_jchar('■文脈ベクトルの計算に使用する語の取捨選択'),
		-font       => "TKFN",
		-foreground => 'blue'
	)->pack(-anchor => 'w');
	
	# 最小・最大出現数
	$right->Label(
		-text => $self->gui_jchar('・最小/最大 出現数による語の選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 5);
	
	my $r2 = $right->Frame()->pack(-fill => 'x');
	$r2->Label(
		-text => $self->gui_jchar('　 　最小出現数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min2} = $r2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$r2->Label(
		-text => $self->gui_jchar('　 最大出現数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max2} = $r2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min2}->insert(0,'1');

	# 最小・最大 文書数による選択
	$right->Label(
		-text => $self->gui_jchar('・最小/最大 文書数による語の選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 5);
	my $r5 = $right->Frame()->pack(-fill => 'x');
	$r5->Label(
		-text => $self->gui_jchar('　 　最小文書数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min_df2} = $r5->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$r5->Label(
		-text => $self->gui_jchar('　 最大文書数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max_df2} = $r5->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min_df2}->insert(0,'1');
	my $r6 = $right->Frame()->pack(-fill => 'x');
	$r6->Label(
		-text => $self->gui_jchar('　 　集計単位：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my %pack = (
		-side => 'left',
		-pady => 2,
	);
	$self->{tani_obj_df2} = gui_widget::tani->open(
		parent        => $r6,
		pack          => \%pack,
		dont_remember => 1,
	);
	$self->{tani_obj_df2}->{raw_opt} = 'bun';
	$self->{tani_obj_df2}->mb_refresh;

	# 品詞による単語の取捨選択
	$right->Label(
		-text => $self->gui_jchar('・品詞による語の選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 5);
	my $r3 = $right->Frame()->pack(-fill => 'both',-expand => 1);
	$r3->Label(
		-text => $self->gui_jchar('　　'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left',-fill => 'y',-expand => 1);
	my %pack = (
			-anchor => 'w',
			-side   => 'left',
			-pady   => 1,
			-fill   => 'y',
			-expand => 1
	);
	$self->{hinshi_obj2} = gui_widget::hinshi->open(
		parent => $r3,
		pack   => \%pack
	);
	my $r4 = $r3->Frame()->pack(-fill => 'x', -expand => 'y',-side => 'left');
	$r4->Button(
		-text => $self->gui_jchar('全て選択'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->{hinshi_obj2}->select_all;});}
	)->pack(-pady => 3);
	$r4->Button(
		-text => $self->gui_jchar('クリア'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->{hinshi_obj2}->select_none;});}
	)->pack();

	$right->Label(
		-text => $self->gui_jchar('・現在の設定で計算に使用される語の数'),
		-font => "TKFN"
	)->pack(-anchor => 'w');
	my $cf2 = $right->Frame->pack(-fill => 'x', -expand => '1');
	$cf2->Label(
		-text => $self->gui_jchar('　 　'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');
	$cf2->Button(
		-text => $self->gui_jchar('チェック'),
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->check2;});}
	)->pack(-side => 'left', -padx => 2);
	$self->{ent_check2} = $cf2->Entry(
		-font       => "TKFN",
		-background => 'gray',
		-state      => 'disable'
	)->pack(-side => 'left',-fill => 'x', -expand => '1');

	#------------------#
	#   抽出語の選択   #

	my $left = $lf->Frame()->pack(-fill => 'both', -expand => 1);
	$left->Label(
		-text       => $self->gui_jchar('■抽出語の取捨選択'),
		-font       => "TKFN",
		-foreground => 'blue'
	)->pack(-anchor => 'w');
	
	# 最小・最大出現数
	$left->Label(
		-text => $self->gui_jchar('・最小/最大 出現数による語の選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 5);
	my $l2 = $left->Frame()->pack(-fill => 'x');
	$l2->Label(
		-text => $self->gui_jchar('　 　最小出現数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min} = $l2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$l2->Label(
		-text => $self->gui_jchar('　 最大出現数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max} = $l2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min}->insert(0,'1');

	# 最小・最大文書数
	$left->Label(
		-text => $self->gui_jchar('・最小/最大 文書数による語の選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 5);
	my $l5 = $left->Frame()->pack(-fill => 'x');
	$l5->Label(
		-text => $self->gui_jchar('　 　最小文書数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min_df} = $l5->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$l5->Label(
		-text => $self->gui_jchar('　 最大文書数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max_df} = $l5->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min_df}->insert(0,'1');
	my $l6 = $left->Frame()->pack(-fill => 'x');
	$l6->Label(
		-text => $self->gui_jchar('　 　集計単位：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my %pack = (
		-side => 'left',
		-pady => 2,
	);
	$self->{tani_obj_df} = gui_widget::tani->open(
		parent        => $l6,
		pack          => \%pack,
		dont_remember => 1,
	);
	$self->{tani_obj_df}->{raw_opt} = 'bun';
	$self->{tani_obj_df}->mb_refresh;
	
	
	# 品詞による単語の取捨選択
	$left->Label(
		-text => $self->gui_jchar('・品詞による語の選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 5);
	my $l3 = $left->Frame()->pack(-fill => 'both',-expand => 1);
	$l3->Label(
		-text => $self->gui_jchar('　　'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left',-fill => 'y',-expand => 1);
	#%pack = (
	#		-anchor => 'w',
	#		-side   => 'left',
	#		-pady   => 1,
	#		-fill   => 'y',
	#		-expand => 1
	#);
	$self->{hinshi_obj} = gui_widget::hinshi->open(
		parent => $l3,
		pack   => \%pack
	);
	my $l4 = $l3->Frame()->pack(-fill => 'x', -expand => 'y',-side => 'left');
	$l4->Button(
		-text => $self->gui_jchar('全て選択'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->{hinshi_obj}->select_all;});}
	)->pack(-pady => 3);
	$l4->Button(
		-text => $self->gui_jchar('クリア'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->{hinshi_obj}->select_none;});}
	)->pack();

	$left->Label(
		-text => $self->gui_jchar('・現在の設定で出力される語の数'),
		-font => "TKFN"
	)->pack(-anchor => 'w');
	my $cf = $left->Frame->pack(-fill => 'x', -expand => '1');
	$cf->Label(
		-text => $self->gui_jchar('　 　'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');
	$cf->Button(
		-text => $self->gui_jchar('チェック'),
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->check1;});}
	)->pack(-side => 'left', -padx => 2);
	$self->{ent_check} = $cf->Entry(
		-font       => "TKFN",
		-background => 'gray',
		-state      => 'disable'
	)->pack(-side => 'left',-fill => 'x', -expand => '1');

	#----------------#
	#   実行ボタン   #

	$bf->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$bf->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{
			$self->check or return;
			my $file = $self->file_name or return;
			my $ans = $self->win_obj->messageBox(
				-message => $self->gui_jchar
					(
					   "この処理には時間がかかることがあります。\n".
					   "続行してよろしいですか？"
					),
				-icon    => 'question',
				-type    => 'OKCancel',
				-title   => 'KH Coder'
			);
			unless ( $ans =~ /ok/i ){ return 0; }
			my $w = gui_wait->start;
			$self->go($file);
			$w->end;
			$self->close;
		});}
	)->pack(-side => 'right');

	return $self;
}

#------------------------#
#   抽出語数のチェック   #

sub check1{
	my $self = shift;
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}
	my $check = mysql_crossout->new(
		tani   => $self->tani_df,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
	)->wnum;
	
	$self->{ent_check}->configure(-state => 'normal');
	$self->{ent_check}->delete(0,'end');
	$self->{ent_check}->insert(0,$check);
	$self->{ent_check}->configure(-state => 'disable');
}
sub check2{
	my $self = shift;
	unless ( eval(@{$self->hinshi2}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}
	my $check = mysql_crossout->new(
		tani   => $self->tani_df2,
		hinshi => $self->hinshi2,
		max    => $self->max2,
		min    => $self->min2,
		max_df => $self->max_df2,
		min_df => $self->min_df2,
	)->wnum;
	
	$self->{ent_check2}->configure(-state => 'normal');
	$self->{ent_check2}->delete(0,'end');
	$self->{ent_check2}->insert(0,$check);
	$self->{ent_check2}->configure(-state => 'disable');
}



#--------------------------#
#   入力チェックルーチン   #

sub check{
	my $self = shift;
	unless ( eval(@{$self->hinshi2}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}
	
	my $list = $self->{tani_obj}->value;
	my $n = @{$list};
	unless ($n){
		gui_errormsg->open(
			type => 'msg',
			msg  => '集計単位が1つも選択されていません。',
		);
		return 0;
	}
	return 1;
}


#--------------#
#   アクセサ   #
#--------------#

sub min{
	my $self = shift;
	return $self->gui_jg( $self->{ent_min}->get );
}
sub max{
	my $self = shift;
	return $self->gui_jg( $self->{ent_max}->get );
}
sub hinshi{
	my $self = shift;
	return $self->{hinshi_obj}->selected;
}
sub tani_df{
	my $self = shift;
	return $self->{tani_obj_df}->tani;
}
sub min_df{
	my $self = shift;
	return $self->gui_jg( $self->{ent_min_df}->get );
}
sub max_df{
	my $self = shift;
	return $self->gui_jg( $self->{ent_max_df}->get );
}

sub min2{
	my $self = shift;
	return $self->gui_jg( $self->{ent_min2}->get );
}
sub max2{
	my $self = shift;
	return $self->gui_jg( $self->{ent_max2}->get );
}
sub hinshi2{
	my $self = shift;
	return $self->{hinshi_obj2}->selected;
}
sub tani_df2{
	my $self = shift;
	return $self->{tani_obj_df2}->tani;
}
sub min_df2{
	my $self = shift;
	return $self->gui_jg( $self->{ent_min_df2}->get );
}
sub max_df2{
	my $self = shift;
	return $self->gui_jg( $self->{ent_max_df2}->get );
}

1;
