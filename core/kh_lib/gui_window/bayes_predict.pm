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
	$win->title($self->gui_jt('学習結果を用いた自動分類'));

	my $lf = $win->LabFrame(
		-label => 'Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');

	# 分類単位の指定
	my $f2 = $lf->Frame()->pack(-expand => 'y', -fill => 'x', -pady => 3);
	$f2->Label(
		-text => $self->gui_jchar('・分類の単位：'),
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
		-text => $self->gui_jchar('・学習結果ファイル：'),
		-font => "TKFN",
	)->pack(-side => 'left');
	
	$fra4e->Button(
		-text    => $self->gui_jchar('参照'),
		-font    => "TKFN",
		-command => sub {$mw->after(10,sub { $self->file; });},
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
		-text => $self->gui_jchar('・変数名：'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	$self->{entry_ovn} = $fra4g->Entry(
		-font  => "TKFN",
		-width => 20,
		-background => 'white'
	)->pack(-padx => 2, -fill => 'x', -expand => 1);

	$self->{entry_ovn}->bind("<Key-Return>",sub{$self->_calc;});

	$lf->Label(
		-text => $self->gui_jchar('    （分類の結果は外部変数として保存されます）'),
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $lff = $win->Frame()->pack(-fill => 'x', -expand => 0);
	$self->{chkw_savelog} = $lff->Checkbutton(
			-text     => $self->gui_jchar('分類ログをファイルに保存','euc'),
			-variable => \$self->{check_savelog},
			-anchor => 'w',
	)->pack(-anchor => 'w');


	$win->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$win->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_calc;});}
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
		-title      => $self->gui_jt('学習結果ファイルを選択してください'),
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

#----------------#
#   処理の実行   #

sub _calc{
	my $self = shift;

	# 入力チェック
	unless (-e $self->gui_jg( $self->{entry}->get ) ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => 'ファイルを正しく指定して下さい。',
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	unless ( length( $self->gui_jg($self->{entry_ovn}->get) ) ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => '変数名を指定して下さい。',
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	my $var_new = $self->gui_jg($self->{entry_ovn}->get);
	$var_new = Jcode->new($var_new, 'sjis')->euc;
	
	my $chk = mysql_outvar::a_var->new($var_new);
	if ( defined($chk->{id}) ){
		gui_errormsg->open(
			type   => 'msg',
			msg    => '指定された名前の変数がすでに存在します。',
			window => \$self->{win_obj},
		);
		return 0;
	}

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
	my $path;
	if ($self->{check_savelog}) {
		my @types = (
			[ "KH Coder: Naive Bayes logs",[qw/.log/] ],
			["All files",'*']
		);

		$path = $self->win_obj->getSaveFile(
			-defaultextension => '.log',
			-filetypes        => \@types,
			-title            =>
				$self->gui_jt('分類ログをファイルに保存'),
			-initialdir       => $self->gui_jchar($::config_obj->cwd),
		);
	}
	if ($path){
		$path = gui_window->gui_jg_filename_win98($path);
		$path = gui_window->gui_jg($path);
		$path = $::config_obj->os_path($path);
	}

	use kh_nbayes;

	kh_nbayes->predict(
		path      => $self->gui_jg( $self->{entry}->get ),
		tani      => $self->tani,
		outvar    => $var_new,
		save_log  => $self->{check_savelog},
		save_path => $path,
	);

	# 「外部変数リスト」が開いている場合は更新
	my $win_list = $::main_gui->get('w_outvar_list');
	if ( defined($win_list) ){
		$win_list->_fill;
	}

	$self->close;
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
