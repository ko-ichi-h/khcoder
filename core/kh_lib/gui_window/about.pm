package gui_window::about;
use strict;
use base qw(gui_window);

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	my $self = shift;
	use Tk::Balloon;
	
	my $mw = $::main_gui->mw;
	my $wabtkh = $mw->Toplevel;
	$wabtkh->resizable(0, 0);
	$wabtkh->title($self->gui_jchar('KH Coderについて','euc'));

	$wabtkh->Label(
		-image => $wabtkh->Photo(-file => $::config_obj->logo_image_file),
		-borderwidth => 2,
		-relief => 'sunken',
		)->pack(-anchor => 'c');

	$wabtkh->Label(
		-text => $self->gui_jchar('　Version：  '."$::kh_version  (".$].")",'euc'),
		-font => "TKFN",
		)->pack(-anchor=>'w',-pady=>'2',-padx=>'2');

	my $fra1 = $wabtkh->Frame() ->pack(-anchor=>'w');

	$fra1->Label(
		-text => $self->gui_jchar('　Web page：','euc'),
		-font => "TKFN",
		)->pack(-anchor => 'w',-pady=>'0',-padx=>'2', -side=>'left');

	$fra1->Button(-text => 'http://khc.sourceforge.net',
		-font => "TKFN",
		-foreground => 'blue',
		-activeforeground => 'red',
		-borderwidth => '0',
		-relief => 'flat',
		-cursor => 'hand2',
		-command => sub{ $mw->after
			(
				10,
				sub {
					gui_OtherWin->open('http://khc.sourceforge.net');
				}
			);
		}
		)->pack(-side => 'right');

	my $fra2 = $wabtkh->Frame() ->pack(-anchor=>'w');

	$fra2->Label(
		-text => $self->gui_jchar('　Thanks to：  川端亮 ','euc'),
		-font => "TKFN",
		)->pack(-anchor => 'w',-pady=>'2',-padx=>'2',-side=>'left');

	my $kwebbutton = $fra2->Button(-image => $fra2->Photo(-file => $::config_obj->icon_image_file),
		-font => "TKFN",
	#	-activebackground => 'white',
	#	-background => 'white',
		-borderwidth => '1',
		-command => sub{ $mw->after
			(
				10,
				sub {
					gui_OtherWin->open(
						'http://keisya.hus.osaka-u.ac.jp/kawabata/'
					);
				}
			);
		}
	)->pack(-side => 'right',-pady => '0');

	my $blhelp = $wabtkh->Balloon();
	$blhelp->attach($kwebbutton,
		-balloonmsg => "Visit his Web page.",
		-font => "TKFN"
		);

	$wabtkh->Label(
		-text => $self->gui_jchar('　Copyright (C)2001-2005 樋口耕一','euc'),
		-font => "TKFN",
		)->pack(-anchor => 'w',-pady=>'2',-padx=>'2');

	$wabtkh->Button(
		-text => $self->gui_jchar('閉じる'),
		-font => "TKFN",
		-width => 8,
	#	-borderwidth => '1',
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->close();
				}
			);
		}
	)->pack(-anchor => 'c',-pady => '0');
	$self->{win_obj} = $wabtkh;
	return $self;
}

#--------------#
#   Window名   #

sub win_name{
	return 'w_about';
}

1;
