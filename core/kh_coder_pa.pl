#!/usr/local/bin/perl

=head1 COPYRIGHT

Copyright (C) 2008 樋口耕一 <http://koichi.nihon.to/psnl>

本プログラムはフリー・ソフトウェアです。

あなたは、Free Software Foundation が公表したGNU一般公有使用許諾書（The GNU General Public License）の「バージョン2」或いはそれ以降の各バージョンの中からいずれかを選択し、そのバージョンが定める条項に従って本プログラムを使用、再頒布、または変更することができます。

本プログラムは有用とは思いますが、頒布に当たっては、市場性及び特定目的適合性についての暗黙の保証を含めて、いかなる保証も行いません。

詳細についてはGNU一般公有使用許諾書をお読み下さい。GNU一般公有使用許諾書は本プログラムのマニュアルの末尾に添付されています。あるいは<http://www.gnu.org/licenses/>でも、GNU一般公有使用許諾書を閲覧することができます。

=cut

use strict;
use vars qw($config_obj $project_obj $main_gui $splash $kh_version);

BEGIN {
	$kh_version = "2.beta.12";
	use Cwd qw(cwd);
	use lib cwd.'/kh_lib';
	use lib cwd.'/plugin';
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

# Windows版パッケージ用の初期化
if (
	   ($::config_obj->os eq 'win32')
	&& $::config_obj->all_in_one_pack
){
	use kh_all_in_one;
	kh_all_in_one->init;
}

# Rの初期化
use Statistics::R;
$::config_obj->{R} = Statistics::R->new(
	log_dir => $::config_obj->{cwd}.'/config/R-bridge'
);
if ($::config_obj->{R}){
	$::config_obj->{R}->startR;
	$::config_obj->{R}->output_chk(1);
} else {
	$::config_obj->{R} = 0;
}
chdir ($::config_obj->{cwd});

$main_gui = gui_window::main->open;
MainLoop;

#-----------------#
#   for PerlApp   #

use Tk::DragDrop::Win32Drop;
use Tk::DragDrop::Win32Site;
use SQL::Dialects::CSV;
