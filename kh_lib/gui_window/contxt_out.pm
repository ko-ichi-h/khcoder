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
	$win->title($self->gui_jt($self->label));
	#$self->{win_obj} = $win;

	# 各種フレーム
	my $wf = $win->Frame()->pack(-fill => 'both', -expand => 1);
	my $lf = $wf->LabFrame(
		-label => kh_msg->get('words'), # 抽出語
		-labelside => 'acrosstop',
		-foreground => 'blue',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1, -side => 'left');
	my $rf = $wf->LabFrame(
		-label => kh_msg->get('words4cntxt'), # 文脈ベクトルの計算に用いる抽出語
		-labelside => 'acrosstop',
		-foreground => 'blue',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1, -side => 'left');
	my $of = $win ->LabFrame(
		-label => kh_msg->get('options'), # 集計単位と重み付け
		-labelside => 'acrosstop',
		-foreground => 'blue',
		-borderwidth => 2,
	)->pack(-anchor => 'w', -side => 'left');
	my $bf = $win ->Frame(
		-borderwidth => 2
	)->pack(-anchor => 'se', -side => 'right');

	#--------------------#
	#   集計オプション   #

	$of->Label(
		-text => '    ',
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

	
	# 最小・最大出現数
	$right->Label(
		-text => kh_msg->get('gui_widget::words->by_tf'), # 最小/最大 出現数による語の選択
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 5);
	
	my $r2 = $right->Frame()->pack(-fill => 'x');
	$r2->Label(
		-text => kh_msg->get('gui_widget::words->min_tf'), #      最小出現数：
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min2} = $r2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->config_entry_focusin($self->{ent_min2});
	
	$r2->Label(
		-text => kh_msg->get('gui_widget::words->max_tf'), # 　 最大出現数：
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max2} = $r2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min2}->insert(0,'1');
	$self->config_entry_focusin($self->{ent_max2});

	# 最小・最大 文書数による選択
	$right->Label(
		-text => kh_msg->get('gui_widget::words->by_df'), # ・最小/最大 文書数による語の選択
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 5);
	my $r5 = $right->Frame()->pack(-fill => 'x');
	$r5->Label(
		-text => kh_msg->get('gui_widget::words->min_df'), # 　 　最小文書数：
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min_df2} = $r5->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->config_entry_focusin($self->{ent_min_df2});
	$r5->Label(
		-text => kh_msg->get('gui_widget::words->max_df'), # 　 最大文書数：
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max_df2} = $r5->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min_df2}->insert(0,'1');
	$self->config_entry_focusin($self->{ent_max_df2});
	my $r6 = $right->Frame()->pack(-fill => 'x');
	$r6->Label(
		-text => kh_msg->get('gui_widget::words->df_unit'), # 　 　文書と見なす単位：
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
		-text => kh_msg->get('gui_widget::words->by_pos'), # ・品詞による語の選択
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 5);
	my $r3 = $right->Frame()->pack(-fill => 'both',-expand => 1);
	$r3->Label(
		-text => '    ',
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left',-fill => 'y',-expand => 1);
	%pack = (
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
	$self->{hinshi_obj2}->select_all;
	my $r4 = $r3->Frame()->pack(-fill => 'x', -expand => 'y',-side => 'left');
	$r4->Button(
		-text => kh_msg->gget('all'), # すべて
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->{hinshi_obj2}->select_all;}
	)->pack(-pady => 3);
	$r4->Button(
		-text => kh_msg->gget('clear'), # クリア
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->{hinshi_obj2}->select_none;}
	)->pack();

	$right->Label(
		-text => 
			 kh_msg->get('gui_widget::words->check_desc1')
			.kh_msg->get('use') # 使用
			.kh_msg->get('gui_widget::words->check_desc2'),
		-font => "TKFN"
	)->pack(-anchor => 'w');
	my $cf2 = $right->Frame->pack(-fill => 'x',  -pady => 2);
	$cf2->Label(
		-text => '   ',
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');
	$cf2->Button(
		-text => kh_msg->get('gui_widget::words->check'), # チェック
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->check2;}
	)->pack(-side => 'left', -padx => 2);
	$self->{ent_check2} = $cf2->Entry(
		-font       => "TKFN",
		-background => 'gray',
		-foreground  => 'black',
		-state      => 'disable',
	)->pack(-side => 'left',-fill => 'x', -expand => 1);
	$self->disabled_entry_configure($self->{ent_check2});


	#------------------#
	#   抽出語の選択   #
	
	$self->{words_obj} = gui_widget::words->open(
		parent => $lf,
		verb   => kh_msg->get('use'),
		type   => 'corresp',
	);

	#----------------#
	#   実行ボタン   #

	$bf->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2);

	$bf->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{
			$self->check or return;
			my $file = $self->file_name or return;
			my $ans = $self->win_obj->messageBox(
				-message => kh_msg->gget('cont_big_pros'),
				-icon    => 'question',
				-type    => 'OKCancel',
				-title   => 'KH Coder'
			);
			unless ( $ans =~ /ok/i ){ return 0; }
			my $w = gui_wait->start;
			$self->go($file);
			$w->end;
			$self->close;
		}
	)->pack(-side => 'right');

	return $self;
}

#------------------------#
#   抽出語数のチェック   #

sub check2{
	my $self = shift;
	unless ( eval(@{$self->hinshi2}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_widget::words->no_pos_selected'),
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
			msg  => kh_msg->get('gui_widget::words->no_pos_selected'),
		);
		return 0;
	}
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_widget::words->no_pos_selected'),
		);
		return 0;
	}
	
	my $list = $self->{tani_obj}->value;
	my $n = @{$list};
	unless ($n){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_widget::words->no_pos_selected'),
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
	return $self->{words_obj}->min;
}
sub max{
	my $self = shift;
	return $self->{words_obj}->max;
}
sub min_df{
	my $self = shift;
	return $self->{words_obj}->min_df;
}
sub max_df{
	my $self = shift;
	return $self->{words_obj}->max_df;
}
sub tani_df{
	my $self = shift;
	return $self->{words_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{words_obj}->hinshi;
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
