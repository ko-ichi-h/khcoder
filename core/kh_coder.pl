#!/usr/local/bin/perl

use strict;
use vars qw($config_obj $project_obj $main_gui $splash $kh_version);

BEGIN {
	$kh_version = "2.alpha.7";
	use Cwd qw(cwd);
	use lib cwd.'/kh_lib';
	if ($^O eq 'MSWin32'){
		require Tk::Splash;
		$splash = Tk::Splash->Show(
			Tk->findINC('kh_logo.bmp'),
			400,
			109,
			'',
		);
	} else {
		push @INC, cwd.'/dummy_lib';
	}
	
	use kh_sysconfig;
	$config_obj = kh_sysconfig->readin('./config/coder.ini',&cwd);
}

use Tk;

use mysql_ready;
use mysql_words;
use mysql_conc;
use kh_project;
use kh_projects;
use kh_morpho;
use gui_window;

$main_gui = gui_window::main->open;
MainLoop;

#--------------------#
#   テスト用コード   #

# テスト用プロジェクトを開く
#kh_project->temp(
#	target  =>
#		'F:/home/Koichi/Study/perl/test_data/kokoro/kokoro.txt',
#	dbname  =>
#		'khc4',
#)->open;
#$::main_gui->close_all;
#$::main_gui->menu->refresh;
#$::main_gui->inner->refresh;

# 特定の（テスト用）Windowを開く
#gui_window::word_ass->open;
#
#MainLoop;
