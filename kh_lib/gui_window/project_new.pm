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
	$mw->title($self->gui_jchar('新規プロジェクト','euc'));
	$self->{win_obj} = $mw;
	my $lfra = $mw->LabFrame(-label => 'Entry',-labelside => 'acrosstop',
		-borderwidth => 2,)
		->pack(-expand=>'yes',-fill=>'both');
	my $fra1 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra2 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$fra1->Label(
		-text => $self->gui_jchar('分析対象ファイル：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my $e1 = $fra1->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-side => 'right');

	$fra1->Button(
		-text => $self->gui_jchar('参照'),
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_sansyo;});}
	)->pack(-side => 'right',-padx => 2);

	$fra2->Label(
		-text => $self->gui_jchar('説明（メモ）：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my $e2 = $fra2->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-side => 'right');

	$mw->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$mw->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_make_new;});}
	)->pack(-side => 'right');

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
	my $new = kh_project->new(
		target  => $self->e1->get,
		comment => $self->e2->get,
	) or return 0;
	kh_projects->read->add_new($new) or return 0;
	$self->close;

	$new->open or die;
	$::main_gui->close_all;
	$::main_gui->menu->refresh;
	$::main_gui->inner->refresh;
}

sub _sansyo{
	my $self = shift;

	my @types = (
		[ "text/html files",[qw/.txt .htm .html/] ],
		["All files",'*']
	);

	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jchar('分析対象ファイルを選択してください'),
		-initialdir => $::config_obj->cwd
	);

	if ($path){
		$::config_obj->os_path($path);
		$self->e1->delete('0','end');
		$self->e1->insert(0,$path);
		#print "$path\n";
		#print Encode::encode('shiftjis',$path)."\n";
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
