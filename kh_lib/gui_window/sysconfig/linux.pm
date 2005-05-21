package gui_window::sysconfig::linux;
use base qw(gui_window::sysconfig);
use strict;
use Tk;
use Tk::HList;

use gui_jchar;
use Gui_DragDrop;
use gui_window::sysconfig::linux::chasen;
use gui_window::sysconfig::linux::juman;

#------------------#
#   Windowを開く   #
#------------------#

sub __new{

#------------------#
#   Chasenの設定   #

	my $self = shift;
	my $mw   = $::main_gui->mw;
	my $inis = $mw->Toplevel;

	$self->{c_or_j}      = $::config_obj->c_or_j;
#	$self->{use_hukugo}  = $::config_obj->use_hukugo;
#	$self->{use_sonota}  = $::config_obj->use_sonota;
	$self->{win_obj}     = $inis;
#	$self = $self->refine_cj;

	$inis->focus;
#	$inis->grab;
	$inis->title( $self->gui_jchar('KH Coderの設定','euc') );
	my $lfra = $inis->LabFrame(
		-label => 'ChaSen',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-expand=>'yes',-fill=>'both');
	my $fra0 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra0_5 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra0_7 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra1 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');
	my $fra2 = $lfra->Frame() ->pack(-anchor=>'c',-fill=>'x',-expand=>'yes');

	$fra0->Label(
		-text => $self->gui_jchar('・茶筌の利用に必要な情報','euc'),
		-font => 'TKFN'
	)->pack(-anchor => 'w');

	$self->{lb1} = $fra1->Label(
		-text => $self->gui_jchar('"chasenrc"のパス：'),
		-font => 'TKFN'
	)->pack(-side => 'left');

	my $entry1 = $fra1->Entry(
		-font => 'TKFN',
		-background => 'white'
	)->pack(-side => 'right');
	$self->{entry1} = $entry1;

	$entry1->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $entry1,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);

	$self->{btn1} = $fra1->Button(
		-text => $self->gui_jchar('参照'),
		-font => 'TKFN',
		-command => sub{ $mw->after
			(10,
				sub { $self->gui_get_exe('chasenrc','entry1'); }
			);
		}
	)->pack(-padx => '2',-side => 'right');

	$self->{lb2} = $lfra->Label(
		-text => $self->gui_jchar('"grammar.cha"のパス：','euc'),
		-font => 'TKFN'
	)->pack(-side => 'left');

	my $entry2 = $lfra->Entry(
		-font => 'TKFN',
		-background => 'white'
	)->pack(-side => 'right');
	$self->{entry2} = $entry2;

	$entry2->DropSite(
		-dropcommand => [\&Gui_DragDrop::get_filename_droped, $entry2,],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);

	$self->{btn2} = $lfra->Button(
		-text => $self->gui_jchar('参照'),
		-font => 'TKFN',
		-command => sub{ $mw->after
			(
				10,
				sub { $self->gui_get_exe('grammar.cha','entry2'); }
			);
		}
	)->pack(-padx => '2',-side => 'right');



#----------------------#
#   外部アプリの設定   #

	my $afra = $inis->LabFrame(
		-label       => 'External Apps',
		-labelside   => 'acrosstop',
		-borderwidth => 2,
	)->pack(-expand=>'yes',-fill=>'both');

	$afra->Label(
		-text => $self->gui_jchar('・その他の外部アプリケーション'),
		-font => 'TKFN'
	)->pack(-anchor => 'w');
	$afra->Label(
		-text => $self->gui_jchar('　（%sはファイル名やURLで置き換えられます）'),
		-font => 'TKFN'
	)->pack(-anchor => 'w');



	# Webブラウザ
	my $appf1 = $afra->Frame()->pack(-expand => 1, -fill => 'x');
	$appf1->Label(
		-text => $self->gui_jchar('Webブラウザ：'),
		-font => 'TKFN'
	)->pack(-side => 'left');
	my $ent_html = $appf1->Entry(
		-font => 'TKFN',
		-background => 'white',
		-width => 26
	)->pack( -side => 'right' );

	# 表計算
	my $appf2 = $afra->Frame()->pack(-expand => 1, -fill => 'x');
	$appf2->Label(
		-text => $self->gui_jchar('表計算（CSVビューア）：'),
		-font => 'TKFN'
	)->pack(-side => 'left');
	my $ent_csv = $appf2->Entry(
		-font => 'TKFN',
		-background => 'white',
		-width => 26
	)->pack( -side => 'right' );

	# PDFビューア
	my $appf2 = $afra->Frame()->pack(-expand => 1, -fill => 'x');
	$appf2->Label(
		-text => $self->gui_jchar('PDFビューア'),
		-font => 'TKFN'
	)->pack(-side => 'left');
	my $ent_pdf = $appf2->Entry(
		-font => 'TKFN',
		-background => 'white',
		-width => 26
	)->pack( -side => 'right' );

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
	)->pack(-anchor=>'e',-side => 'right',-padx => 2);

	$inis->Button(
		-text => 'OK',
		-font => 'TKFN',
		-width => 8,
		-command => sub{ $mw->after
			(
				10,
				sub {$self->ok }
			);
		}
	)->pack(-side => 'right');

	$entry1->insert(0,$::config_obj->chasenrc_path);
	$entry2->insert(0,$::config_obj->grammarcha_path);
	$ent_html->insert(0,$::config_obj->app_html);
	$ent_csv->insert(0,$::config_obj->app_csv);
	$ent_pdf->insert(0,$::config_obj->app_pdf);

	$self->{e_html} = $ent_html;
	$self->{e_csv} = $ent_csv;
	$self->{e_pdf} = $ent_pdf;

	return $self;
}

#--------------------#
#   ファンクション   #
#--------------------#

sub unselect{
	my $self = shift;
	$self->hlist->selectionClear();
#	print "fuck\n";
}


# OKボタン
sub ok{
	my $self = shift;
	
	my $oldfont = $::config_obj->font_main;
	
	$::config_obj->chasenrc_path($self->entry1->get());
	$::config_obj->grammarcha_path($self->entry2->get());
	$::config_obj->app_html($self->e_html->get());
	$::config_obj->app_pdf($self->e_pdf->get());
	$::config_obj->app_csv($self->e_csv->get());

	$::config_obj->use_heap(  $self->{mail_obj}->if_heap );
	$::config_obj->mail_if(   $self->{mail_obj}->if      );
	$::config_obj->mail_smtp( $self->{mail_obj}->smtp    );
	$::config_obj->mail_from( $self->{mail_obj}->from    );
	$::config_obj->mail_to(   $self->{mail_obj}->to      );
	$::config_obj->font_main( Jcode->new($self->{mail_obj}->font)->euc );

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
	my $self = shift;
	my $file = shift;
	my $ent  = shift;

	my @types = (
		["All files", '*']
	);

	my $path = $self->win_obj->getOpenFile(
		-filetypes => \@types,
		-title => $self->gui_jchar("「$file」を開いてください"),
		-initialdir => $::config_obj->cwd
	);

	my $entry = $self->{$ent};
	if ($path){
		$path = $::config_obj->os_path($path);
		$entry->delete('0','end');
		$entry->insert(0,$path);
	}
}

# chasenとjumanの切り替え
#sub refine_cj{
#	my $self = shift;
#	bless $self, 'gui_window::sysconfig::linux::'.$self->{c_or_j};
#	return $self;
#}

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
sub e_html{
	my $self = shift; return $self->{e_html};
}
sub e_csv{
	my $self = shift; return $self->{e_csv};
}
sub e_pdf{
	my $self = shift; return $self->{e_pdf};
}
1;
