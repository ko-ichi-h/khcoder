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

	my $mw = $self->{win_obj};
	$mw->title($self->gui_jt('新規プロジェクト','euc'));
	#$self->{win_obj} = $mw;
	my $lfra = $mw->LabFrame(-label => 'Entry',-labelside => 'acrosstop',
		-borderwidth => 2,)
		->pack(-expand=>'yes',-fill=>'both');
	my $fra1 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra3 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra2 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$fra1->Label(
		-text => $self->gui_jchar('分析対象ファイル：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	my $e1 = $fra1->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-side => 'right');

	$fra3->Label(
		-text => $self->gui_jchar('分析対象ファイルの文字コード：'),
		-font => "TKFN"
	)->pack(-side => 'left');

	$self->{icode_menu} = gui_widget::optmenu->open(
		parent  => $fra3,
		pack    => { -side => 'right', -padx => 2},
		options =>
			[
				[$self->gui_jchar('自動判別')  => 0],
				[$self->gui_jchar('EUC') => 'euc'],
				[$self->gui_jchar('JIS') => 'jis'],
				[$self->gui_jchar('Shift-JIS') => 'sjis']
			],
		variable => \$self->{icode},
	);

	$fra1->Button(
		-text => $self->gui_jchar('参照'),
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->_sansyo;});}
	)->pack(-side => 'right',-padx => 2);

	$fra2->Label(
		-text => $self->gui_jchar('説明（メモ）：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my $e2 = $fra2->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-side => 'right',-pady => 2);

	$mw->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$self->{ok_btn} = $mw->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_make_new;});}
	)->pack(-side => 'right');

	# ENTRYのバインド
	$e1->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $e1,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	$mw->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e2->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e2]);
	$e2->bind("<Key-Return>",sub{$self->_make_new;});
	
	$self->{e1}  = $e1;
	$self->{e2}  = $e2;

	#MainLoop;
	return $self;
}

#--------------------#
#   ファンクション   #

sub _make_new{
	my $self = shift;

	my $t = $::config_obj->os_path(
		$self->gui_jg(
			$self->e1->get
		)
	);
	
	my $new = kh_project->new(
		target  => $t,
		comment => $self->gui_jg($self->e2->get),
		icode   => $self->gui_jg($self->{icode}),
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

	#print $::config_obj->cwd, "\n";
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt('分析対象ファイルを選択してください'),
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);

	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$::config_obj->os_path($path);
		$self->e1->delete('0','end');
		$self->e1->insert(0,$self->gui_jchar($path));
		#print Jcode->new($path)->euc, "\n";
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
