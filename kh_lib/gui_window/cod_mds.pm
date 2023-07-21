package gui_window::cod_mds;
use base qw(gui_window);

use strict;
use utf8;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # コーディング・多次元尺度法：オプション

	my $lf = $win->LabFrame(
		-label => 'Codes',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 0, -side => 'left',-anchor => 'w');

	#my $rf = $win->Frame()
	#	->pack(-fill => 'both', -expand => 1);

	my $lf2 = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0, -anchor => 'n');

	# ルール・ファイル
	my %pack0 = (
		-anchor => 'w',
		#-padx => 2,
		#-pady => 2,
		-fill => 'x',
		-expand => 0,
	);
	$self->{codf_obj} = gui_widget::codf->open(
		parent  => $lf,
		pack    => \%pack0,
		command => sub{$self->read_cfile;},
	);
	
	# コーディング単位
	my $f1 = $lf->Frame()->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 4
	);
	$f1->Label(
		-text => kh_msg->get('gui_window::cod_corresp->coding_unit'), # コーディング単位：
		-font => "TKFN",
	)->pack(-side => 'left');
	my %pack1 = (
		-anchor => 'w',
		-padx => 2,
		-pady => 2,
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $f1,
		pack   => \%pack1,
		tani_gt_1 => 1,
	);

	# コード選択
	$lf->Label(
		-text => kh_msg->get('gui_window::cod_corresp->select_codes'), # コード選択：
		-font => "TKFN",
	)->pack(-anchor => 'nw', -padx => 2, -pady => 0);

	my $f2 = $lf->Frame()->pack(
		-fill   => 'both',
		-expand => 1,
		-padx   => 2,
		-pady   => 2
	);

	$f2->Label(
		-text => '    ',
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);

	my $f2_1 = $f2->Frame(
		-borderwidth        => 2,
		-relief             => 'sunken',
	)->pack(
			-anchor => 'w',
			-side   => 'left',
			-pady   => 2,
			-padx   => 2,
			-fill   => 'both',
			-expand => 1
	);

	# コード選択用HList
	$self->{hlist} = $f2_1->Scrolled(
		'HList',
		-scrollbars         => 'osoe',
		#-relief             => 'sunken',
		-font               => 'TKFN',
		-selectmode         => 'none',
		-indicator => 0,
		-highlightthickness => 0,
		-columns            => 1,
		-borderwidth        => 0,
		-height             => 12,
	)->pack(
		-fill   => 'both',
		-expand => 1
	);

	my $f2_2 = $f2->Frame()->pack(
		-fill   => 'x',
		-expand => 0,
		-side   => 'left'
	);
	$f2_2->Button(
		-text => kh_msg->gget('all'), # すべて
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->select_all;}
	)->pack(-pady => 3);
	$f2_2->Button(
		-text => kh_msg->gget('clear'), # クリア
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->select_none;}
	)->pack();

	$lf->Label(
		-text => kh_msg->get('sel5'), #     ※コードを5つ以上選択して下さい。
		-font => "TKFN",
	)->pack(
		-anchor => 'w',
		-padx   => 4,
	);

	# アルゴリズム選択
	$self->{mds_obj} = gui_widget::r_mds->open(
		parent       => $lf2,
		command      => sub{ $self->_calc; },
		pack    => { -anchor   => 'w'},
	);

	# フォントサイズ
	$self->{font_obj} = gui_widget::r_font->open(
		parent    => $lf2,
		command   => sub{ $self->_calc; },
		pack      => { -anchor   => 'w' },
		show_bold => 1,
		plot_size => $::config_obj->plot_size_codes,
	);

	$win->Checkbutton(
			-text     => kh_msg->gget('r_dont_close'), # 実行時にこの画面を閉じない
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	# OK・キャンセル
	$win->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$self->{ok_btn} = $win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		#-state => 'disable',
		-command => sub{$self->_calc;}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se');
	$self->{ok_btn}->focus;

	$self->read_cfile;

	return $self;
}



# コーディングルール・ファイルの読み込み
sub read_cfile{
	my $self = shift;
	
	$self->{hlist}->delete('all');
	
	unless (-e $self->cfile ){
		return 0;
	}
	
	my $cod_obj = kh_cod::func->read_file($self->cfile);
	
	unless (eval(@{$cod_obj->codes})){
		return 0;
	}

	my $left = $self->{hlist}->ItemStyle('window',-anchor => 'w');

	my $row = 0;
	$self->{checks} = undef;
	foreach my $i (@{$cod_obj->codes}){
		
		$self->{checks}[$row]{check} = 1;
		$self->{checks}[$row]{name}  = $i->name;
		
		my $c = $self->{hlist}->Checkbutton(
			-text     => $i->name,
			-variable => \$self->{checks}[$row]{check},
			-command  => sub{ $self->check_selected_num; },
			-anchor => 'w',
		);
		
		$self->{checks}[$row]{widget} = $c;
		
		$self->{hlist}->add($row,-at => "$row");
		$self->{hlist}->itemCreate(
			$row,0,
			-itemtype  => 'window',
			-style     => $left,
			-widget    => $c,
		);
		++$row;
	}
	
	$self->check_selected_num;
	
	return $self;
}

sub start_raise{
	my $self = shift;
	
	# コード選択を読み取り
	my %selection = ();
	foreach my $i (@{$self->{checks}}){
		if ($i->{check}){
			$selection{$i->{name}} = 1;
		} else {
			$selection{$i->{name}} = -1;
		}
	}
	
	# ルールファイルを再読み込み
	$self->read_cfile;
	
	# 選択を適用
	foreach my $i (@{$self->{checks}}){
		if ($selection{$i->{name}} == 1 || $selection{$i->{name}} == 0){
			$i->{check} = 1;
		} else {
			$i->{check} = 0;
		}
	}
	
	$self->{hlist}->update;
	return 1;
}


# コードが5つ以上選択されているかチェック
sub check_selected_num{
	my $self = shift;
	
	my $selected_num = 0;
	foreach my $i (@{$self->{checks}}){
		++$selected_num if $i->{check};
	}
	
	if ($selected_num >= 5){
		$self->{ok_btn}->configure(-state => 'normal');
	} else {
		$self->{ok_btn}->configure(-state => 'disable');
	}
	return $self;
}

# すべて選択
sub select_all{
	my $self = shift;
	foreach my $i (@{$self->{checks}}){
		$i->{widget}->select;
	}
	$self->check_selected_num;
	return $self;
}

# クリア
sub select_none{
	my $self = shift;
	foreach my $i (@{$self->{checks}}){
		$i->{widget}->deselect;
	}
	$self->check_selected_num;
	return $self;
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

# プロット作成＆表示
sub _calc{
	my $self = shift;

	# number of cases
	my $cases = mysql_exec->select("select count(*) from ".$self->tani,1)->hundle->fetch->[0];
	unless ( $cases > 1 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('to_few_cases')." [$cases]",
		);
		return 0;
	}

	my @selected = ();
	foreach my $i (@{$self->{checks}}){
		push @selected, $i->{name} if $i->{check};
	}
	my $selected_num = @selected;
	if ($selected_num < 5){
		gui_errormsg->open(
			type   => 'msg',
			window  => \$self->win_obj,
			msg    => kh_msg->get('sel5_e'), # コードを5つ以上選択してください。
		);
		return 0;
	}

	my $wait_window = gui_wait->start;

	# データ取得
	my $r_command;
	unless ( $r_command =  kh_cod::func->read_file($self->cfile)->out2r_selected($self->tani,\@selected) ){
		gui_errormsg->open(
			type   => 'msg',
			window  => \$self->win_obj,
			msg    => kh_msg->get('gui_window::cod_corresp->er_zero'),
		);
		#$self->close();
		$wait_window->end(no_dialog => 1);
		return 0;
	}
	
	# データ整理
	$r_command .= "\n";
	$r_command .= "d <- t(d)\n";
	$r_command .= "row.names(d) <- c(";
	foreach my $i (@{$self->{checks}}){
		if ( $i->{check} ){
			my $name = $i->{name};
			if ( index($name,'＊') == 0 || index($name,'*') == 0){
				substr($name, 0, 1) = '';
			}
			$name = kh_r_plot->quote($name);
			$r_command .= $name.',';
		}
	}
	chop $r_command;
	$r_command .= ")\n";
	$r_command .= "d <- subset(d, rowSums(d) > 0)\n";
	$r_command .= "# END: DATA\n";

	my $plot = &gui_window::word_mds::make_plot(
		font_size         => $self->{font_obj}->font_size,
		font_bold         => $self->{font_obj}->check_bold_text,
		plot_size         => $self->{font_obj}->plot_size,
		$self->{mds_obj}->params,
		r_command      => $r_command,
		plotwin_name   => 'cod_mds',
	);

	$wait_window->end(no_dialog => 1);
	return 0 unless $plot;
	
	# プロットWindowを開く
	if ($::main_gui->if_opened('w_cod_mds_plot')){
		$::main_gui->get('w_cod_mds_plot')->close;
	}
	return 0 unless $plot;

	gui_window::r_plot::cod_mds->open(
		plots       => $plot->{result_plots},
		msg         => $plot->{result_info},
		#ax          => $self->{ax},
	);
	$plot = undef;
	
	
	unless ( $self->{check_rm_open} ){
		$self->withd;
	}

}

#--------------#
#   アクセサ   #

sub cfile{
	my $self = shift;
	return $self->{codf_obj}->cfile;
}
sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}

sub win_name{
	return 'w_cod_mds';
}
1;