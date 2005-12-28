package gui_window::outvar_read;
use base qw(gui_window);
use strict;
use Tk;

use gui_errormsg;

use gui_window::outvar_read::tab;
use gui_window::outvar_read::csv;

#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $wmw= $self->{win_obj};
	#$wmw->focus;
	$wmw->title($self->win_title);

	my $fra4 = $wmw->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');

	# ファイル名指定のフレーム
	my $fra4e = $fra4->Frame()->pack(-expand => 'y', -fill => 'x',-pady => 3);
	
	$fra4e->Label(
		-text => $self->file_label,
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
	)->pack(-side => 'left',-padx => 2);
	
	$self->{entry}->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $self->{entry},],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	

	# 読み込み単位の指定
	my $fra4f = $fra4->Frame()->pack(-expand => 'y', -fill => 'x', -pady =>3);
	
	$fra4f->Label(
		-text => $self->gui_jchar('読み込み単位：'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	my %pack = (
			-anchor => 'w',
			-pady   => 1,
#			-side   => 'right'
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $fra4f,
		pack   => \%pack
	);

	$wmw->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$wmw->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_read;});}
	)->pack(-side => 'right');

	MainLoop;
	
	#$self->{win_obj} = $wmw;
	return $self;
}

#--------------#
#   読み込み   #
#--------------#

sub _read{
	my $self = shift;

	# 入力チェック
	unless (-e $self->{entry}->get){
		gui_errormsg->open(
			type   => 'msg',
			msg    => $self->gui_jchar('ファイルを正しく指定して下さい。'),
			window => \$self->{win_obj},
		);
		return 0;
	}

	# 読み込みの実行
	$self->__read or return 0;

	# 以下は完了処理
	
	# 変数リストWindowをオープン
	$self->close;
	my $list = gui_window::outvar_list->open;
	$list->_fill;
	
	# 「コーディング・外部変数とのクロス集計」Windowが開いていた場合
	if ( $::main_gui->if_opened('w_cod_outtab') ){
		$::main_gui->get('w_cod_outtab')->fill;
	}
}

1;
