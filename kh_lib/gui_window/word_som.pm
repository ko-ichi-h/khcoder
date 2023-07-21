package gui_window::word_som;
use base qw(gui_window);

use strict;
use Tk;

use gui_widget::words;
use mysql_crossout;
use kh_r_plot;
use plotR::som;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));

	my $lf_w = $win->LabFrame(
		-label       => kh_msg->get('u_w'), # 集計単位と抽出語の選択
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-fill => 'both', -expand => 1, -side => 'left');

	my $lf = $win->LabFrame(
		-label       => kh_msg->get('opt'), # SOMのオプション
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-fill => 'both', -expand => 0);

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		verb   => kh_msg->get('cluster'), # 分類
		sampling     => 1,
		command      => sub{
			$self->calc;
		},
		tani_gt_1    => 1,
	);

	# SOMのオプション
	$self->{som_obj} = gui_widget::r_som->open(
		parent       => $lf,
		command      => sub{ $self->calc; },
		pack    => { -anchor   => 'w'},
	);

	# フォントサイズ
	$self->{font_obj} = gui_widget::r_font->open(
		parent    => $lf,
		command   => sub{ $self->calc; },
		pack      => { -anchor   => 'w' },
		show_bold => 1,
	);
	$self->{font_obj}->bold;

	$win->Checkbutton(
			-text     => kh_msg->gget('r_dont_close'),
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$win->Label(
		-text    => kh_msg->get('time_warn'),
		-justify => 'left'
	)->pack(-anchor => 'w');

	$win->Button(
		-text => kh_msg->gget('cancel'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se')->focus;

	return $self;
}

sub start_raise{
	my $self = shift;
	$self->{words_obj}->settings_load;
}

sub start{
	my $self = shift;

	# Windowを閉じる際のバインド
	$self->win_obj->bind(
		'<Control-Key-q>',
		sub{ $self->withd; }
	);
	$self->win_obj->bind(
		'<Key-Escape>',
		sub{ $self->withd; }
	);
	$self->win_obj->protocol('WM_DELETE_WINDOW', sub{ $self->withd; });
}

#----------#
#   実行   #

sub calc{
	my $self = shift;
	
	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::word_corresp->select_pos'), # '品詞が1つも選択されていません。',
		);
		return 0;
	}

	# number of cases
	my $cases = mysql_exec->select("select count(*) from ".$self->tani,1)->hundle->fetch->[0];
	unless ( $cases > 1 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('to_few_cases')." [$cases]",
		);
		return 0;
	}

	my $check_num = mysql_crossout::r_com->new(
		tani     => $self->tani,
		tani2    => $self->tani,
		hinshi   => $self->hinshi,
		max      => $self->max,
		min      => $self->min,
		max_df   => $self->max_df,
		min_df   => $self->min_df,
	)->wnum;
	
	$check_num =~ s/,//g;
	#print "$check_num\n";

	if ($check_num < 3){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('select_3words'), #'少なくとも3つ以上の抽出語を選択して下さい。',
		);
		return 0;
	}

	if ($check_num > 500){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					kh_msg->get('gui_window::word_corresp->too_many1')
					.$check_num
					.kh_msg->get('gui_window::word_corresp->too_many2')
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many3')
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many4')
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
	}

	$self->{words_obj}->settings_save;

	my $wait_window = gui_wait->start;

	# データの取り出し
	my $r_command = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		rownames => 0,
		sampling => $self->{words_obj}->sampling_value,
	)->run;

	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	# SOMの実行
	use plotR::som;
	my $plotR = plotR::som->new(
		$self->{som_obj}->params,
		font_size      => $self->{font_obj}->font_size,
		font_bold      => $self->{font_obj}->check_bold_text,
		plot_size      => $self->{font_obj}->plot_size,
		r_command      => $r_command,
		plotwin_name   => 'word_som',
		data_number    => $check_num,
	);

	# プロットWindowを開く
	$wait_window->end(no_dialog => 1);
	$wait_window = undef;
	return 0 unless $plotR;
	
	if ($::main_gui->if_opened('w_word_som_plot')){
		$::main_gui->get('w_word_som_plot')->close;
	}

	return 0 unless $plotR;

	gui_window::r_plot::word_som->open(
		plots       => $plotR->{result_plots},
		msg         => $plotR->{result_info},
		msg_long    => $plotR->{result_info_long},
		coord       => $plotR->{coord},
		#no_geometry => 1,
	);

	$plotR = undef;

	unless ( $self->{check_rm_open} ){
		$self->withd;
	}

	return 1;
}

#--------------#
#   アクセサ   #


sub label{
	return kh_msg->get('win_title'); # 抽出語・クラスター分析：オプション
}

sub win_name{
	return 'w_word_som';
}

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

1;