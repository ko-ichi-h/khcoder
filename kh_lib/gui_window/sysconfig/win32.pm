package gui_window::sysconfig::win32;
use base qw(gui_window::sysconfig);
use strict;
use Tk;

use gui_jchar;
use Gui_DragDrop;
use gui_window::sysconfig::win32::chasen;
use gui_window::sysconfig::win32::juman;

#------------------#
#   Windowを開く   #
#------------------#

sub __new{
	my $self = shift;
	my $mw   = $::main_gui->mw;
	my $inis = $mw->Toplevel;

	$self->{c_or_j}      = $::config_obj->c_or_j;
#	$self->{use_hukugo}  = $::config_obj->use_hukugo;
#	$self->{use_sonota}  = $::config_obj->use_sonota;
	$self->{win_obj}     = $inis;
	$self = $self->refine_cj;

	$inis->focus;
	$inis->grab;
	my $msg = Jcode::convert('KH Coderの設定','sjis','euc');
	$inis->title("$msg");
	my $lfra = $inis->LabFrame(-label => 'ChaSen',
		-labelside => 'acrosstop',
		-borderwidth => 2,)
		->pack(-expand=>'yes',-fill=>'both');
	my $fra0 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',expand=>'yes');
	my $fra0_5 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',expand=>'yes');
	my $fra0_7 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',expand=>'yes');
	my $fra1 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',expand=>'yes');
	my $fra2 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',expand=>'yes');
	
	$msg = '・茶筌の設定';
	Jcode::convert(\$msg,'sjis','euc');
	$fra0->Label(-text => "$msg",
		-font => 'TKFN'
	)->pack(-anchor => 'w');



	$msg = 'Chasen.exeのパス：'; Jcode::convert(\$msg,'sjis','euc');
	$self->{lb1} = $fra1->Label(-text => "$msg",
		-font => 'TKFN'
	)->pack(-side => 'left');

	my $entry1 = $fra1->Entry(-font => 'TKFN')->pack(side => 'right');
	$self->{entry1} = $entry1;

	$entry1->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $entry1,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
	);

	$msg = '参照'; Jcode::convert(\$msg,'sjis','euc');
	$self->{btn1} = $fra1->Button(-text => "$msg",-font => 'TKFN',
		-command => sub{ $mw->after
			(10,
				sub { $self->gui_get_exe(); }
			);
		}
	)->pack(-padx => '2',-side => 'right');

	$inis->Button(
		-text => Jcode->new('キャンセル')->sjis,
		-font => 'TKFN',
		-width => 8,
		-command => sub{
			$inis->after(10,sub{$self->close;})
		}
	)->pack(-anchor=>'e',-side => 'right',-padx => 2);

	$inis->Button(
		-text  => 'OK',
		-font  => 'TKFN',
		-width => 8,
		-command => sub{ $mw->after
			(
				10,
				sub {$self->ok }
			);
		}
	)->pack(-anchor => 'e',-side => 'right');

	# 文字化け回避用バインド
	$inis->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$entry1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$entry1]);
	$entry1->insert(0,$::config_obj->chasen_path);
	$self->gui_switch;

	return $self;
}

#--------------------#
#   ファンクション   #
#--------------------#

# OKボタン
sub ok{
	my $self = shift;
	
	$::config_obj->chasen_path($self->entry1->get());

	if ($::config_obj->save){
		$self->close;
	}
}


# ファイル・オープン・ダイアログ
sub gui_get_exe{
	my $self = shift;
	my $msg = $self->open_msg;

	Jcode::convert(\$msg,'sjis','euc');
	my @types =
		(["exe files",           [qw/.exe/]],
		["All files",		'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes => \@types,
		-title => "$msg",
		-initialdir => $::config_obj->cwd
	);
	
	my $entry = $self->entry;
	if ($path){
		$path =~ tr/\//\\/;
		$entry->delete('0','end');
		$entry->insert(0,$path);
	}
}

# chasenとjumanの切り替え
sub refine_cj{
	my $self = shift;
	bless $self, 'gui_window::sysconfig::win32::'.$self->{c_or_j};
	return $self;
}

#--------------#
#   アクセサ   #
#--------------#

sub entry1{
	my $self = shift; return $self->{entry1};
}
sub entry2{
	my $self = shift; return $self->{entry2};
}
sub btn1{
	my $self = shift; return $self->{btn1};
}
sub btn2{
	my $self = shift; return $self->{btn2};
}
sub chk{
	my $self = shift; return $self->{chk};
}
sub chk2{
	my $self = shift; return $self->{chk2};
}
sub lb1{
	my $self = shift; return $self->{lb1};
}
sub lb2{
	my $self = shift; return $self->{lb2};
}
1;
