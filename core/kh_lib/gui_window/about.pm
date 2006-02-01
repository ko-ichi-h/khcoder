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
	my $wabtkh = $self->{win_obj};
	#$wabtkh->resizable(0, 0);
	$wabtkh->title($self->gui_jchar('KH Coderについて','euc'));

	$wabtkh->Label(
		-image => $wabtkh->Photo(-file => $::config_obj->logo_image_file),
		-borderwidth => 2,
		-relief => 'sunken',
		)->pack(-anchor => 'c');

	my $fra_m = $wabtkh->Frame()->pack(-anchor=>'w');
	my $fra_r = $fra_m->Frame()->pack(-anchor=>'w', -side => 'right');
	my $fra_l = $fra_m->Frame()->pack(-anchor=>'w', -side => 'left');

	$fra_l->Label(
		-text => '  Version:',
		-font => "TKFN",
		)->pack(-anchor=>'w',-pady=>'2',-padx=>'2');

	$fra_r->Label(
		-text => "$::kh_version  [Perl ".$].", Perl/Tk $Tk::VERSION]",
		-font => "TKFN",
		)->pack(-anchor=>'w',-pady=>'2',-padx=>'2');

	$fra_l->Label(
		-text => '  Web page:',
		-font => "TKFN",
		)->pack(-anchor => 'w',-pady=>'2',-padx=>'2');

	$fra_r->Button(-text => 'http://khc.sourceforge.net',
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
	)->pack(-anchor => 'w');

	$fra_l->Label(
		-text => '  Powered by:',
		-font => "TKFN",
		)->pack(-anchor => 'w',-pady=>'2',-padx=>'2');

	my $fra_r1 = $fra_r->Frame()->pack(-anchor=>'w');


	$fra_r1->Button(
		-text => 'ChaSen',
		-font => "TKFN",
		-foreground => 'blue',
		-activeforeground => 'red',
		-borderwidth => '0',
		-relief => 'flat',
		-cursor => 'hand2',
		-width => 6,
		-command => sub{
			$mw->after(
				10,
				sub {
					gui_OtherWin->open('http://chasen.naist.jp/');
				}
			);
		}
	)->pack(-side => 'left', -anchor => 'nw');

	$fra_r1->Label(
		-text => '+',
		-font => "TKFN",
		)->pack(-anchor => 'nw',-pady=>'2',-side=>'left');

	$fra_r1->Button(
		-text => 'MySQL',
		-font => "TKFN",
		-foreground => 'blue',
		-activeforeground => 'red',
		-borderwidth => '0',
		-relief => 'flat',
		-cursor => 'hand2',
		-command => sub{
			$mw->after(
				10,
				sub {
					gui_OtherWin->open('http://www.mysql.com/');
				}
			);
		}
	)->pack(-anchor => 'nw' , -side => 'left');

	$fra_r1->Label(
		-text => '+',
		-font => "TKFN",
		)->pack(-anchor => 'nw',-pady=>'2',-side=>'left');

	$fra_r1->Button(
		-text => 'Perl',
		-font => "TKFN",
		-foreground => 'blue',
		-activeforeground => 'red',
		-borderwidth => '0',
		-relief => 'flat',
		-cursor => 'hand2',
		-command => sub{
			$mw->after(
				10,
				sub {
					gui_OtherWin->open('http://www.perl.com/');
				}
			);
		}
	)->pack(-anchor => 'nw');


	$fra_l->Label(
		-text => '  Thanks to:',
		-font => "TKFN",
		)->pack(-anchor => 'w',-pady=>'2',-padx=>'2');

	$fra_r->Button(
		-text => $self->gui_jchar('川端亮','euc'),
		-font => "TKFN",
		-foreground => 'blue',
		-activeforeground => 'red',
		-borderwidth => '0',
		-relief => 'flat',
		-cursor => 'hand2',
		-command => sub{
			$mw->after(
				10,
				sub {
					gui_OtherWin->open('http://keisya.hus.osaka-u.ac.jp/kawabata/');
				}
			);
		}
	)->pack(-anchor => 'nw');

	$fra_l->Label(
		-text => '  Copyright:',
		-font => "TKFN",
	)->pack(-anchor => 'w',-pady=>'2',-padx=>'2');

	$fra_r->Label(
		-text => $self->gui_jchar('(C) 2001-2006 樋口耕一','euc'),
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
	#$self->{win_obj} = $wabtkh;
	return $self;
}

#--------------#
#   Window名   #

sub win_name{
	return 'w_about';
}

1;
