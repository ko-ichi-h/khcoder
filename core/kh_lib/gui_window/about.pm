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
	$wabtkh->focus;
	my $msg = Jcode->new('KH Coder II について','euc')->sjis;
	$wabtkh->title("$msg");

	$wabtkh->Label(
		-image => $wabtkh->Photo(-file => $::config_obj->logo_image_file),
		-borderwidth => 2,
		-relief => 'sunken',
		)->pack(-anchor => 'c');

	$msg = '　Version：  '."$::kh_version";
	$msg = Jcode->new($msg,'euc')->sjis;
	$wabtkh->Label(
		text => "$msg",
		font => "TKFN",
		)->pack(-anchor=>'w',-pady=>'2',-padx=>'2');

	my $fra1 = $wabtkh->Frame() ->pack(-anchor=>'w');

	$msg = Jcode->new('　Web page：','euc')->sjis;
	$fra1->Label(
		text => "$msg",
		font => "TKFN",
		)->pack(-anchor => 'w',-pady=>'0',-padx=>'2', -side=>'left');

	$fra1->Button(-text => 'http://koichi.nihon.to/psnl/khcoder',
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
					gui_OtherWin->open('http://koichi.nihon.to/psnl/khcoder');
				}
			);
		}
		)->pack(-side => 'right');

	my $fra2 = $wabtkh->Frame() ->pack(-anchor=>'w');


	$msg = Jcode->new('　Thanks to：  川端亮 ','euc')->sjis;
	$fra2->Label(
		text => "$msg",
		font => "TKFN",
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
						'http://risya3.hus.osaka-u.ac.jp/kawabata/'
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


	$msg = Jcode->new('　Copyright (C) 樋口耕一 2003','euc')->sjis;
	$wabtkh->Label(
		text => "$msg",
		font => "TKFN",
		)->pack(-anchor => 'w',-pady=>'2',-padx=>'2');

	$wabtkh->Button(
		-text => 'OK',
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