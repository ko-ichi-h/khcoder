#!/usr/bin/perl

use strict;
use vars qw($config_obj $project_obj $main_gui $splash $kh_version);

BEGIN {
	$kh_version = "2.pa.2";
	use Cwd qw(cwd);
	push @INC, cwd.'/kh_lib';
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
}

use Tk;

use mysql_ready;
use mysql_words;
use mysql_conc;
use kh_project;
use kh_projects;
use kh_morpho;
use kh_sysconfig;
use gui_window;

$config_obj = kh_sysconfig->readin('./config/coder.ini',&cwd);
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

#-----------------#
#   for perlapp   #
#
# use Tk::DragDrop::Win32Drop;
# use Tk::DragDrop::Win32Site;
# use SQL::Dialects::CSV;
