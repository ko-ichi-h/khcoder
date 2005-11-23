package gui_window::project_edit;
use base qw(gui_window);
use strict;
use Tk;

sub _new{
	my $self = shift;
	$self->{projects} = $_[0];
	$self->{num}      = $_[1];
	$self->{mother}   = $_[2];

	$self->{project}  = $self->projects->a_project($self->num);

	# 開く
	my $mw = $::main_gui->mw;
	my $npro = $self->{win_obj};
	#$npro->resizable(0, 0);
	$npro->focus();
	$npro->grab();

	$npro->title( $self->gui_jchar('説明（メモ）の編集') );

	# $self->{win_obj} = $npro;

	my $lfra = $npro->LabFrame(
		-label => 'Entry',
		-labelside => 'acrosstop',
		-borderwidth => 2
	)->pack(-expand=>'yes',-fill=>'both');
	my $fra1 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra2 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$fra1->Label(
		-text => $self->gui_jchar('分析対象ファイル：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my $e1 = $fra1->Entry(
		-font => "TKFN",
		-background => 'gray',
	)->pack(-side => 'right');

	$fra1->Button(
		-text => $self->gui_jchar('参照'),
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_sansyo;});},
		-state => 'disable'
	)->pack(-side => 'right',-padx => 2);

	$fra2->Label(
		-text => $self->gui_jchar('説明（メモ）：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my $e2 = $fra2->Entry(
		-font => "TKFN",
		-background => 'white'
	)->pack(-side => 'right');

	$npro->Button(
		-text => $self->gui_jchar('キャンセル'),
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->close();});}
	)->pack(-side => 'right',-padx => 2);

	$self->{ok_btn} = $npro->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_edit;});},
	)->pack(-side => 'right');

	# ENTRYのバインド
	#$e1->DropSite(
	#	-dropcommand => [\&Gui_DragDrop::get_filename_droped, $e1,],
	#	-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
	#);
	$npro->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$e2->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$e2]);
	
	# ENTRYへの挿入
	$e1->insert(0,$self->gui_jchar($self->project->file_target));
	$e2->insert(0,$self->gui_jchar($self->project->comment));
	$e1->configure(-state => 'disable');
	$self->{e2}  = $e2;
	#MainLoop;
	return $self;
}

sub _edit{
	my $self = shift;
	$self->projects->edit($self->num,$self->gui_jg($self->e2->get));
	$self->close();
	$self->mother->refresh;
}


#--------------#
#   アクセサ   #
#--------------#

sub e2{
	my $self = shift;
	return $self->{e2};
}
sub num{
	my $self = shift;
	return $self->{num};
}
sub project{
	my $self = shift;
	return $self->{project};
}
sub projects{
	my $self = shift;
	return $self->{projects};
}
sub mother{
	my $self = shift;
	return $self->{mother};
}
sub win_name{
	return 'w_edit_pro';
}
1;
