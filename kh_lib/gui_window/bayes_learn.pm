package gui_window::bayes_learn;
use base qw(gui_window);
use strict;
use Tk;

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt('外部変数から学習'));

	my $lf_w = $win->LabFrame(
		-label => 'Setting',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	$self->{words_obj} = gui_widget::words_bayes->open(
		parent => $lf_w,
		verb   => '学習に使用',
	);

	$win->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->calc;});}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se');

	return $self;
}

sub calc{
	my $self = shift;
	
	#------------------#
	#   入力チェック   #

	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}

	if ( $self->outvar == -1 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '外部変数の設定が不正です。。',
		);
		return 0;
	}

	unless ( $self->{words_obj}->check > 0 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '現在の設定内容では、使用できる語がありません。',
		);
		return 0;
	}

	$self->{words_obj}->settings_save;

	my $ans = $self->win_obj->messageBox(
		-message => $self->gui_jchar
			(
			   "この処理には時間がかかることがあります。\n".
			   "続行しますか？"
			),
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	unless ($ans =~ /ok/i){ return 0; }

	# 保存先の参照
	my @types = (
		[ "KH Coder: Naive Bayes",[qw/.knb/] ],
		["All files",'*']
	);
	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.knb',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt('学習データの保存先'),
		-initialdir       => $self->gui_jchar($::config_obj->cwd),
	);
	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);

	#----------#
	#   実行   #

	use kh_nbayes;

	kh_nbayes->learn_from_ov(
		tani   => $self->tani,
		outvar => $self->outvar,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		path   => $path,
	);

	$self->close;
	return 1;
}

#--------------#
#   アクセサ   #

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
sub tani{
	my $self = shift;
	return $self->{words_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{words_obj}->hinshi;
}
sub outvar{
	my $self = shift;
	return $self->{words_obj}->outvar;
}

sub win_name{
	return 'w_bayes_learn';
}

1;