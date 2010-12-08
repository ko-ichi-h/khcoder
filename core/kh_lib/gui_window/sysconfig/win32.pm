package gui_window::sysconfig::win32;
use base qw(gui_window::sysconfig);
use strict;
use Tk;

use gui_jchar;
use Gui_DragDrop;
use gui_window::sysconfig::win32::chasen;
use gui_window::sysconfig::win32::mecab;

#------------------#
#   Windowを開く   #
#------------------#

sub __new{
	my $self = shift;
	my $mw   = $::main_gui->mw;
	my $inis = $self->{win_obj};

	$self->{c_or_j}      = $::config_obj->c_or_j;

	# $inis->focus;
	# $inis->grab;
	$inis->title($self->gui_jt('KH Coderの設定'));

	my $lfra = $inis->LabFrame(
		-label => $self->gui_jchar('[語を抽出する方法]'),
		-labelside => 'acrosstop',
		-borderwidth => 2,)
		->pack(-expand=>'yes',-fill=>'both');
	#my $fra0 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra0_5 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra0_7 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$lfra->Radiobutton(
		-text     => $self->gui_jchar('茶筌を利用／日本語データ'),
		-font     => 'TKFN',
		-variable => \$self->{c_or_j},
		-value    => 'chasen',
		-command  => sub{ $self = $self->refine_cj },
	)->pack(-anchor => 'w');

	my $fra1 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$self->{lb1} = $fra1->Label(
		-text => $self->gui_jchar('chasen.exeのパス：'),
		-font => 'TKFN'
	)->pack(-side => 'left');

	my $entry1 = $fra1->Entry(-font => 'TKFN')->pack(-side => 'right');
	$self->{entry1} = $entry1;

	$entry1->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $entry1,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
	);

	$self->{btn1} = $fra1->Button(
		-text => $self->gui_jchar('参照'),
		-font => 'TKFN',
		-command => sub{ $mw->after
			(10,
				sub { $self->gui_get_exe( $self->{entry1} ); }
			);
		}
	)->pack(-padx => '2',-side => 'right');

	
	my $msg = 'MeCabを利用／日本語データ';
	if ($::config_obj->all_in_one_pack && ! -e $::config_obj->mecab_path){
		$msg .= '／要・別途インストール';
	}

	$lfra->Radiobutton(
		-text     => $self->gui_jchar($msg),
		-font     => 'TKFN',
		-variable => \$self->{c_or_j},
		-value    => 'mecab',
		-command  => sub{ $self = $self->refine_cj },
	)->pack(-anchor => 'w');

	my $fra2 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$self->{lb2} = $fra2->Label(
		-text => $self->gui_jchar('mecab.exeのパス：'),
		-font => 'TKFN'
	)->pack(-side => 'left');

	my $entry2 = $fra2->Entry(-font => 'TKFN')->pack(-side => 'right');
	$self->{entry2} = $entry2;

	$entry2->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $entry2,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
	);

	$self->{btn2} = $fra2->Button(
		-text => $self->gui_jchar('参照'),
		-font => 'TKFN',
		-command => sub{ $mw->after
			(10,
				sub { $self->gui_get_exe( $self->{entry2} ); }
			);
		}
	)->pack(-padx => '2',-side => 'right');
	
	$entry1->insert(0,$self->gui_jchar($::config_obj->chasen_path));
	$entry2->insert(0,$self->gui_jchar($::config_obj->mecab_path));
	
	$self = $self->refine_cj;

	$self->{mail_obj} = gui_widget::mail_config->open(
		parent => $inis,
	);


	$inis->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => 'TKFN',
		-width => 8,
		-command => sub{
			$inis->after(10,sub{$self->close;})
		}
	)->pack(-anchor=>'e',-side => 'right',-padx => 2, -pady => 2);

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
	)->pack(-anchor => 'e',-side => 'right',  -pady => 2);

	# 文字化け回避用バインド
	$inis->bind('Tk::Entry', '<Key-Delete>', \&gui_jchar::check_key_e_d);
	$entry1->bind("<Key>",[\&gui_jchar::check_key_e,Ev('K'),\$entry1]);
	
	
	#$self->gui_switch;

	return $self;
}

#--------------------#
#   ファンクション   #
#--------------------#

# OKボタン
sub ok{
	my $self = shift;
	
	my $oldfont = $::config_obj->font_main;
	
	$::config_obj->chasen_path( $self->gui_jg( $self->entry1->get() ) );
	$::config_obj->mecab_path(  $self->gui_jg( $self->entry2->get() ) );
	$::config_obj->c_or_j(      $self->gui_jg( $self->{c_or_j}      ) );
	
	$::config_obj->use_heap(    $self->{mail_obj}->if_heap );
	$::config_obj->mail_if(     $self->{mail_obj}->if      );
	$::config_obj->mail_smtp(   $self->{mail_obj}->smtp    );
	$::config_obj->mail_from(   $self->{mail_obj}->from    );
	$::config_obj->mail_to(     $self->{mail_obj}->to      );
	$::config_obj->font_main(   Jcode->new($self->{mail_obj}->font)->euc );
	
	if ($::config_obj->save){
		$self->close;
	}
	
	unless ($oldfont eq $::config_obj->font_main){
		$::main_gui->close_all;
		$::main_gui->remove_font;
		$::main_gui->make_font;
		$::config_obj->ClearGeometries;
		gui_errormsg->open(
			type => 'msg',
			msg  => "フォントが変更されました。\n変更を有効にするために、KH Coderを再起動してください。",
		);
		
	}

}


# ファイル・オープン・ダイアログ
sub gui_get_exe{
	my $self  = shift;
	my $entry = shift;

	my @types =
		(["exe files",           [qw/.exe/]],
		["All files",		'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => $self->gui_jt($self->open_msg),
		-initialdir => $self->gui_jchar($::config_obj->cwd),
	);
	
	if ($path){
		$path = $self->gui_jg_filename_win98($path);
		$path = $self->gui_jg($path);
		$path = $::config_obj->os_path($path);
		$entry->delete('0','end');
		$entry->insert(0,$self->gui_jchar($path));
	}
}

# chasenとjumanの切り替え
sub refine_cj{
	my $self = shift;
	bless $self, 'gui_window::sysconfig::win32::'.$self->{c_or_j};
	$self->gui_switch;
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
