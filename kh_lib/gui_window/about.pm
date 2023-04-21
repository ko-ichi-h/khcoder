package gui_window::about;
use strict;
use base qw(gui_window);

use kh_msg;

use utf8;

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	my $self = shift;
	use Tk::Balloon;

	my $mw = $::main_gui->mw;
	my $wabtkh = $self->{win_obj};

	$wabtkh->title( $self->gui_jt( kh_msg->get('win_title') ) );

	# logo image file
	$self->{img} = $wabtkh->Photo(-file => $::config_obj->logo_image_file);
	$wabtkh->Label(
		-image => $self->{img},
		-borderwidth => 2,
		-relief => 'sunken',
	)->grid( -row => 0, -columnspan => 2, -padx => 3, -pady => 3);

	# print detailed versions to console
	my $version_perl = $];
	my $version_tk = $Tk::VERSION;
	print "Perl ".$version_perl.", Perl/Tk $version_tk\n";

	# Version
	$wabtkh->Label(
		-text => '  Version:',
		-font => "TKFN",
	)->grid( -row => 1, -column => 0, -sticky => 'w');

	my $fra_r0 = $wabtkh->Frame();
	
	$fra_r0->Label(
		-text => kh_about->version,
		-font => "TKFN",
	)->pack( -side => 'left');

	$fra_r0->Label(
		-text => ' ',
		-font => "TKFN",
	)->pack( -side => 'left');

	$self->{copy_btn} = $fra_r0->Button(
		-text    => kh_msg->gget('copy'),
		-font    => "TKFN",
		-command => sub {
			use kh_clipboard;
			kh_clipboard->string( kh_about->version );
		},
	)->pack(-side => 'left');

	$fra_r0->grid( -row => 1, -column => 1, -sticky => 'w');

	$self->win_obj->bind(
		'<Control-Key-c>',
		sub{ $self->{copy_btn}->invoke; }
	);

	# Web page
	$wabtkh->Label(
		-text => '  Web page:',
		-font => "TKFN",
	)->grid( -row => 2, -column => 0, -sticky => 'w');

	gui_widget::url_lab->open(
		label  => $self->gui_jchar('https://khcoder.net'),
		url    => 'https://khcoder.net',
		parent => $wabtkh,
		grid   => { -row => 2, -column => 1, -sticky => 'w' },
	);

	# Powered by
	$wabtkh->Label(
		-text => '  Powered by:',
		-font => "TKFN",
	)->grid( -row => 3, -column => 0, -sticky => 'w');

	my $fra_r1 = $wabtkh->Frame();

	gui_widget::url_lab->open(
		label  => $self->gui_jchar('ChaSen'),
		url    => 'http://chasen-legacy.sourceforge.jp/',
		parent => $fra_r1,
		pack   => {-side => 'left', -anchor => 'nw',-pady=>'2'},
	);

	#$fra_r1->Label(
	#	-text => '+',
	#	-font => "TKFN",
	#	)->pack(-anchor => 'nw',-pady=>'2',-side=>'left');

	#gui_widget::url_lab->open(
	#	label  => $self->gui_jchar('MeCab'),
	#	url    => 'http://mecab.sourceforge.net/',
	#	parent => $fra_r1,
	#	pack   => {-side => 'left', -anchor => 'nw',-pady=>'2'},
	#);

	$fra_r1->Label(
		-text => '+',
		-font => "TKFN",
		)->pack(-anchor => 'nw',-pady=>'2',-side=>'left');

	gui_widget::url_lab->open(
		label  => $self->gui_jchar('MySQL'),
		url    => 'http://www.mysql.com/',
		parent => $fra_r1,
		pack   => {-side => 'left', -anchor => 'nw',-pady=>'2'},
	);

	$fra_r1->Label(
		-text => '+',
		-font => "TKFN",
		)->pack(-anchor => 'nw',-pady=>'2',-side=>'left');

	gui_widget::url_lab->open(
		label  => $self->gui_jchar('Perl'),
		url    => 'http://www.cpan.org/',
		parent => $fra_r1,
		pack   => {-side => 'left', -anchor => 'nw',-pady=>'2'},
	);

	$fra_r1->Label(
		-text => '+',
		-font => "TKFN",
		)->pack(-anchor => 'nw',-pady=>'2',-side=>'left');

	gui_widget::url_lab->open(
		label  => $self->gui_jchar('R'),
		url    => 'http://www.r-project.org/',
		parent => $fra_r1,
		pack   => {-anchor => 'nw',-pady=>'2', -side => 'left'},
	);

	$fra_r1->Label(
		-text => '+',
		-font => "TKFN",
		)->pack(-anchor => 'nw',-pady=>'2',-side=>'left');

	gui_widget::url_lab->open(
		label  => $self->gui_jchar('more'),
		url    => 'https://khcoder.net/link.html',
		parent => $fra_r1,
		pack   => {-anchor => 'nw',-pady=>'2'},
	);

	$fra_r1->grid( -row => 3, -column => 1, -sticky => 'w');

	# Thanks to
	$wabtkh->Label(
		-text => '  Thanks to:',
		-font => "TKFN",
	)->grid( -row => 4, -column => 0, -sticky => 'w');

	gui_widget::url_lab->open(
		label  => kh_msg->get('kawabata'),
		url    => 'https://researchmap.jp/KA010203',
		parent => $wabtkh,
		grid   => { -row => 4, -column => 1, -sticky => 'w' },
	);

	# Copyright (c)
	$wabtkh->Label(
		-text => '  Copyright:',
		-font => "TKFN",
	)->grid( -row => 5, -column => 0, -sticky => 'w');

	my $fra_r2 = $wabtkh->Frame();
	
	my $copy_mark;
	if( $] > 5.008 ){
		$copy_mark = '©';
	} else {
		$copy_mark = '(C) ';
	}

	$fra_r2->Label(
		-text => $self->gui_jchar($copy_mark.'2001-'.kh_about->current_year),
		-font => "TKFN",
	)->pack(-anchor => 'nw', -pady=>'2', -side => 'left');

	gui_widget::url_lab->open(
		label  => kh_msg->get('higuchi'),
		url    => 'https://research-db.ritsumei.ac.jp/rithp/k03/resid/S000577',
		parent => $fra_r2,
		pack   => {-anchor => 'w',-side => 'left', -pady=>'2'},
	);

	$fra_r2->Label(
		-text => '+',
		-font => "TKFN",
	)->pack(-anchor => 'nw', -pady=>'2', -side => 'left');

	gui_widget::url_lab->open(
		label  => 'Contributors',
		url    => 'https://github.com/ko-ichi-h/khcoder/graphs/contributors',
		parent => $fra_r2,
		pack   => {-anchor => 'w',-side => 'left', -pady=>'2'},
	);
	$fra_r2->grid( -row => 5, -column => 1, -sticky => 'w');

	# Close button
	$wabtkh->Button(
		-text => kh_msg->get('close'),
		-font => "TKFN",
		-width => 8,
		-command => 
			sub {
				$self->close();
			}
	)->grid( -row => 6, -columnspan => 2, -pady => 3)->focus;

	return $self;
}

sub end{
	my $self = shift;
	$self->{img}->delete;
}

#--------------#
#   Window名   #

sub win_name{
	return 'w_about';
}

1;
