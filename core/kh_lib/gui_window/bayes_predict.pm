package gui_window::bayes_predict;
use base qw(gui_window);

use strict;
use Jcode;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt(kh_msg->get('win_title'))); # 学習結果を用いた自動分類

	my $lf = $win->LabFrame(
		-label => 'Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');

	# 分類単位の指定
	my $f2 = $lf->Frame()->pack(-expand => 'y', -fill => 'x', -pady => 3);
	$f2->Label(
		-text => kh_msg->get('unit'), # 分類の単位：
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');
	my %pack = (
			-anchor => 'e',
			-pady   => 1,
			-side   => 'left'
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $f2,
		pack   => \%pack
	);

	# ファイル名の指定
	my $fra4e = $lf->Frame()->pack(-expand => 'y', -fill => 'x',-pady => 3);
	
	$fra4e->Label(
		-text => kh_msg->get('model_file'), # 学習結果ファイル：
		-font => "TKFN",
	)->pack(-side => 'left');
	
	$fra4e->Button(
		-text    => kh_msg->gget('browse'), # 参照
		-font    => "TKFN",
		-command => sub { $self->file; },
	)->pack(-side => 'left');
	
	$self->{entry} = $fra4e->Entry(
		-font  => "TKFN",
		-width => 20,
		-background => 'white'
	)->pack(-side => 'left',-padx => 2, -fill => 'x', -expand => 1);

	$self->{entry}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	

	# 変数名の指定
	my $fra4g = $lf->Frame()->pack(-expand => 'y', -fill => 'x', -pady =>3);
	$fra4g->Label(
		-text => kh_msg->get('var_name'), # 変数名：
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	$self->{entry_ovn} = $fra4g->Entry(
		-font  => "TKFN",
		-width => 20,
		-background => 'white'
	)->pack(-padx => 2, -fill => 'x', -expand => 1);

	$self->{entry_ovn}->bind("<Key-Return>",sub{$self->_calc;});
	$self->{entry_ovn}->bind("<KP_Enter>",sub{$self->_calc;});

	$lf->Label(
		-text => kh_msg->get('var_desc'), #     （分類の結果は外部変数として保存されます）
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $lff = $win->Frame()->pack(-fill => 'x', -expand => 0);
	$self->{chkw_savelog} = $lff->Checkbutton(
			-text     => kh_msg->get('save_log'), # 分類ログをファイルに保存
			-variable => \$self->{check_savelog},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$win->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2);

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->_calc;}
	)->pack(-side => 'right');
	
	return $self;
}

sub file{
	my $self = shift;

	my @types = (
		[ "KH Coder: Naive Bayes Moldels",[qw/.knb/] ],
		["All files",'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt(kh_msg->get('opening_model')), # 学習結果ファイルを選択してください
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$self->{entry}->delete(0, 'end');
		$self->{entry}->insert('0',$self->gui_jchar("$path"));
	}
	return 1;
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

#----------------#
#   処理の実行   #

sub _calc{
	my $self = shift;

	# 入力チェック
	my $path_i = $self->gui_jg( $self->{entry}->get );
	$path_i= $::config_obj->os_path($path_i);
	unless (-e $path_i ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('er_no_such_file'), # ファイルを正しく指定して下さい。
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	unless ( length( $self->gui_jg($self->{entry_ovn}->get) ) ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('er_specify_name'), # 変数名を指定して下さい。
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	my $var_new = $self->gui_jg($self->{entry_ovn}->get);
	#$var_new = Jcode->new($var_new, 'sjis')->euc;
	
	my $chk = mysql_outvar::a_var->new($var_new);
	if ( defined($chk->{id}) ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => kh_msg->get('er_exists'), # 指定された名前の変数がすでに存在します。
			window => \$self->{win_obj},
		);
		return 0;
	}

	# 保存先の参照
	my $path;
	if ($self->{check_savelog}) {
		my @types = (
			[ "KH Coder: Naive Bayes logs",[qw/.nbl/] ],
			["All files",'*']
		);

		$path = $self->win_obj->getSaveFile(
			-defaultextension => '.nbl',
			-filetypes        => \@types,
			-title            =>
				$self->gui_jt(kh_msg->get('saving_log')), # 分類ログをファイルに保存
			-initialdir       => $self->gui_jchar($::config_obj->cwd),
		);
	}
	if ($path){
		$path = gui_window->gui_jg_filename_win98($path);
		$path = gui_window->gui_jg($path);
		$path = $::config_obj->os_path($path);
	}

	my $ans = $self->win_obj->messageBox(
		-message => kh_msg->gget('cont_big_pros'),
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	unless ($ans =~ /ok/i){ return 0; }

	my $wait_window = gui_wait->start;

	use kh_nbayes;

	kh_nbayes->predict(
		path      => $path_i,
		tani      => $self->tani,
		outvar    => $var_new,
		save_log  => $self->{check_savelog},
		save_path => $path,
	);

	$wait_window->end(no_dialog => 1);

	# 「外部変数リスト」を開く
	my $win_list = gui_window::outvar_list->open;
	$win_list->_fill;

	$self->withd;
}



#--------------#
#   アクセサ   #


sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}

sub win_name{
	return 'w_bayes_predict';
}

1;
