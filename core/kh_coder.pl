#! /usr/bin/perl

use strict;
use vars qw($config_obj $project_obj $main_gui $splash $kh_version);

BEGIN {
	$kh_version = "2.a";

	use Cwd qw(cwd);
	push @INC, cwd.'/kh_lib';
	if ($^O eq 'MSWin32'){
		require Tk::Splash;
		$splash = Tk::Splash->Show(
			Tk->findINC('kh_logo.bmp'),
			400,
			122,
			'',
		);
	} else {
		push @INC, cwd.'/dummy_lib';
	}
}

use Tk;
use mysql_ready;
use mysql_words;
use kh_project;
use kh_projects;
use kh_morpho;
use kh_sysconfig;
use gui_window;

$config_obj = kh_sysconfig->readin('./config/coder.ini',&cwd);
$main_gui = gui_window::main->open;

MainLoop;
