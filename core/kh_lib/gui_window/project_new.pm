package gui_window::project_new;
use base qw(gui_window);
use strict;
use Tk;

use gui_jchar;

#----------------------------#
#   新規プロジェクトWindow   #
#----------------------------#

sub _new{
	my $self = shift;

	my $mw = $::main_gui->mw->Toplevel;
#	$mw->resizable(0, 0);
	$mw->focus();
#	$mw->grab();
	my $msg = Jcode->new('新規プロジェクト')->sjis;
	$mw->title("$msg");

	$self->{win_obj} = $mw;

	my $lfra = $mw->LabFrame(-label => 'Entry',-labelside => 'acrosstop',
		-borderwidth => 2,)
		->pack(-expand=>'yes',-fill=>'both');
	my $fra1 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',expand=>'yes');
	my $fra2 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',expand=>'yes');


	$msg = Jcode->new('分析対象ファイル：')->sjis;
	$fra1->Label(
		-text => "$msg",
		-font => "TKFN"
	)->pack(-side => 'left');
	my $e1 = $fra1->Entry(-font => "TKFN")->pack(-side => 'right');

	$msg = Jcode->new('参照')->sjis;
	$fra1->Button(
		-text => "$msg",
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_sansyo;});}
	)->pack(-side => 'right');

	$msg = Jcode->new('説明（メモ）：')->sjis;
	$fra2->Label(
		-text => "$msg",
		-font => "TKFN"
	)->pack(-side => 'left');
	my $e2 = $fra2->Entry(
		-font => "TKFN"
	)->pack(-side => 'right');

	$mw->Button(
		-text => Jcode->new('キャンセル')->sjis,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 3);

	$mw->Button(
		-text => 'OK',
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_make_new;});}
	)->pack(-side => 'right',-padx => 3);

	# ENTRYのバインド
	$e1->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $e1,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
	);
	$mw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e2->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e2]);

	$self->{e1}  = $e1;
	$self->{e2}  = $e2;

	MainLoop;
	return $self;
}

#--------------------#
#   ファンクション   #

sub _make_new{
	my $self = shift;
	print "1 ";
	my $new = kh_project->new(
		target  => $self->e1->get,
		comment => $self->e2->get,
	) or return 0;
	print "2 ";
	kh_projects->read->add_new($new) or return 0;
	print "3 ";
	$self->close;

	$new->open or die;
	print "4 ";
	$::main_gui->close_all;
	print "5 ";
	$::main_gui->menu->refresh;
	print "6 ";
	$::main_gui->inner->refresh;
	print "7 ";
}

sub _sansyo{
	my $self = shift;

	my @types = (
		[ "text/html files",[qw/.txt .htm .html/] ],
		["All files",'*']
	);

	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => Jcode->new('分析対象ファイルを選択してください')->sjis,
		-initialdir => $::config_obj->cwd
	);

	if ($path){
		$::config_obj->os_path($path);
		$self->e1->delete('0','end');
		$self->e1->insert(0,$path);
	}
}

#--------------#
#   アクセサ   #

sub e1{
	my $self = shift;
	return $self->{e1};
}
sub e2{
	my $self = shift;
	return $self->{e2};
}

sub win_name{
	return 'w_new_pro';
}


1;
