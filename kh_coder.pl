#!/usr/local/bin/perl

=head1 COPYRIGHT

Copyright (C) 2001- 樋口耕一 <http://koichi.nihon.to/psnl>

本プログラムはフリー・ソフトウェアです。

あなたは、Free Software Foundation が公表したGNU一般公有使用許諾書（The GNU General Public License）の「バージョン2」或いはそれ以降の各バージョンの中からいずれかを選択し、そのバージョンが定める条項に従って本プログラムを使用、再頒布、または変更することができます。

本プログラムは有用とは思いますが、頒布に当たっては、市場性及び特定目的適合性についての暗黙の保証を含めて、いかなる保証も行いません。

詳細についてはGNU一般公有使用許諾書をお読み下さい。GNU一般公有使用許諾書は本プログラムのマニュアルの末尾に添付されています。あるいは<http://www.gnu.org/licenses/>でも、GNU一般公有使用許諾書を閲覧することができます。

=cut

$| = 1;

use strict;

use vars qw($config_obj $project_obj $main_gui $splash $kh_version);

BEGIN {
	# open (STDERR,">stderr.txt") or die; # for debug

	# for macOS
	if ($^O eq 'darwin'){
		# Un-minimize Terminal window
		system 'osascript -e \'tell application "Terminal" to set miniaturized of front window to false\'';
	}

	# Encoding configurations
	use Jcode;
	push @INC, '.';
	require kh_lib::Jcode_kh if $] > 5.008 && eval 'require Encode::EUCJPMS';

	my $locale_fs = 1;
	eval { require Encode::Locale; };
	if ( $@ ){
		warn $@;
		print "Fatal error detected! Please report the content of this window to the developper. Thanks!\n";
		$locale_fs = 0;
	}
	if ($locale_fs){
		print "Encoding of this Console: $Encode::Locale::ENCODING_CONSOLE_OUT";
		unless ( Encode::find_encoding('console_out') ) {
			$Encode::Locale::ENCODING_CONSOLE_OUT = $Encode::Locale::ENCODING_LOCALE;
			$Encode::Locale::ENCODING_CONSOLE_IN  = $Encode::Locale::ENCODING_LOCALE;
			eval{ Encode::Locale::_flush_aliases(); };
			print " -> $Encode::Locale::ENCODING_LOCALE";
		}
		print "\n";

		print "Encoding of this file system: $Encode::Locale::ENCODING_CONSOLE_OUT";
		unless  ( Encode::find_encoding('locale_fs') ) {
			$Encode::Locale::ENCODING_LOCALE_FS = $Encode::Locale::ENCODING_LOCALE;
			eval{ Encode::Locale::_flush_aliases(); };
			print " -> $Encode::Locale::ENCODING_LOCALE";
		}
		print "\n";

		eval {
			binmode STDOUT, ":encoding(console_out)";
		};
	}

	# for Windows [1]
	use Cwd;
	if ($^O eq 'MSWin32'){
		# Cwd.pmの上書き
		no warnings 'redefine';
		sub Cwd::_win32_cwd {
			if (defined &DynaLoader::boot_DynaLoader) {
				$ENV{'PWD'} = Win32::GetCwd();
			}
			else { # miniperl
				chomp($ENV{'PWD'} = `cd`);
			}
			$ENV{'PWD'} = Encode::decode('locale_fs', $ENV{'PWD'}) if $locale_fs;
			$ENV{'PWD'} =~ s:\\:/:g ;
			$ENV{'PWD'} = Encode::encode('locale_fs', $ENV{'PWD'}) if $locale_fs;
			return $ENV{'PWD'};
		};
		*cwd = *Cwd::cwd = *Cwd::getcwd = *Cwd::fastcwd = *Cwd::fastgetcwd = *Cwd::_NT_cwd = \&Cwd::_win32_cwd;
		use warnings 'redefine';
	}

	# モジュールのパスを追加
	unshift @INC, cwd.'/kh_lib';

	# for Windows [2]
	if ($^O eq 'MSWin32'){
		# コンソールを最小化
		require Win32::Console;
		Win32::Console->new->Title('Console of KH Coder');
		Win32::Sleep(50);
		if (
			   (defined($PerlApp::VERSION) && substr($PerlApp::VERSION,0,1) >= 7)
			|| (defined($main::ENV{KHCPUB}) && $main::ENV{KHCPUB} == 2)
		){
			require Win32::API;
			my $FindWindow = new Win32::API('user32', 'FindWindow', 'PP', 'N');
			my $ShowWindow = new Win32::API('user32', 'ShowWindow', 'NN', 'N');
			my $hw = $FindWindow->Call( 0, 'Console of KH Coder' );
			$ShowWindow->Call( $hw, 7 );
		}
		$SIG{TERM} = $SIG{QUIT} = sub{ exit; };
		# スプラッシュ
		#require Tk::Splash;
		#$splash = Tk::Splash->Show(
		#	Tk->findINC('kh_logo.bmp'),
		#	400,
		#	109,
		#	'',
		#);
		# TkをInvokeしないマルチスレッド用のスプラッシュ
		if (eval 'require Win32::GUI::SplashScreen'){
			require Tk::Splash; # findINC関数を得るため
			Win32::GUI::SplashScreen::Show(
				-file => Tk->findINC('kh_logo.bmp'),
				-mintime => 3,
			);
		}
		# 設定
		require Tk::Clipboard;
		require Tk::Clipboard_kh;
	} 
	# for Linux & Others
	else {
		use Tk;
		my $version_tk = $Tk::VERSION;
		if (length($version_tk) > 7){
			$version_tk = substr($version_tk,0,7);
		}
		print "Perl/Tk: $version_tk\n";
		if ($] > 5.008 && $version_tk <= 804.034){
			require Tk::FBox;
			require Tk::FBox_kh2;
		}
	}

	# 設定の読み込み
	require kh_sysconfig;
	$config_obj = kh_sysconfig->readin('./config/coder.ini',&cwd);
}

use Tk;
use mysql_ready;
use mysql_words;
use mysql_conc;
use kh_about;
use kh_project;
use kh_projects;
use kh_morpho;
use gui_window;

$kh_version = kh_about->version;

# Say hello
print "This is KH Coder $kh_version on $^O.\n";
print "CWD: ", $config_obj->uni_path( $config_obj->cwd ), "\n";

# Windows版パッケージ用の初期化
if (
	   ($::config_obj->os eq 'win32')
	&& $::config_obj->all_in_one_pack
){
	use kh_all_in_one;
	kh_all_in_one->init;
}

# Mac OS X版パッケージ用の初期化
if (
	   ($^O eq 'darwin')
	&& $::config_obj->all_in_one_pack
){
	use kh_all_in_mac;
	kh_all_in_mac->init;
}

# Rの初期化
use Statistics::R;

no  warnings 'redefine';
*Statistics::R::output_chk = sub {return 1};
use warnings 'redefine';

if (
	   (
			   length($::config_obj->r_path)
			&& -e $::config_obj->os_path( $::config_obj->r_path )
		)
	|| ( not length($::config_obj->r_path) )
){
	$::config_obj->{R} = Statistics::R->new(
		r_bin   => $::config_obj->os_path( $::config_obj->r_path ),
		#r_dir   => $::config_obj->os_path( $::config_obj->r_dir  ),
		log_dir => $::config_obj->{cwd}.'/config/R-bridge',
		tmp_dir => $::config_obj->{cwd}.'/config/R-bridge',
	);
}

if ($::config_obj->{R}){
	$ENV{LANGUAGE} = 'EN';
	$::config_obj->{R}->startR;

	if ($::config_obj->os ne 'win32'){
		$::config_obj->{R}->send('Sys.setlocale(category="LC_ALL",locale="ja_JP.UTF-8")');
	}

	$::config_obj->{R}->send('dummy_d <- matrix(1:9, nrow=3, ncol=3)');
	$::config_obj->{R}->send('dummy_r <- cmdscale(dist(dummy_d), k=1)');
	$::config_obj->{R}->read();
	$::config_obj->{R}->output_chk(1);
	$::config_obj->ram;
} else {
	$::config_obj->{R} = 0;
}

chdir ($::config_obj->{cwd});
$::config_obj->R_version;

# マルチスレッド処理の準備
use my_threads;
my_threads->init;

# GUIの開始
$main_gui = gui_window::main->open;
gui_window::suggest->open if $::config_obj->show_suggest_on_startup;

# for macOS
if (
	   ($^O eq 'darwin')
	&& $::config_obj->all_in_one_pack
){
	# Minimize Terminal window
	system 'osascript -e \'tell application "Terminal" to set miniaturized of front window to true\'';
}

MainLoop;

__END__

# テスト用プロジェクトを開く
kh_project->temp(
	target  =>
		'F:/home/Koichi/Study/perl/test_data/STATS_News-IT-2004/2004p.txt',
	#	'E:/home/higuchi/perl/core/data/SalaryMan/both_all.txt',
	dbname  =>
		'khc13',
	#	'khc2',
)->open;
$::main_gui->close_all;
$::main_gui->menu->refresh;
$::main_gui->inner->refresh;

# 共起ネットワーク作成
my $win_net = gui_window::word_netgraph->open;
$win_net->calc;

# 共起ネットワークの「調整」を繰り返す
my $n = 0;
while (1){
	my $c = $::main_gui->get('w_word_netgraph_plot');

	my $cc = gui_window::r_plot_opt::word_netgraph->open(
		command_f => $c->{plots}[$c->{ax}]->command_f,
		size      => $c->original_plot_size,
	);
	
	my $en = 100 + int( rand(50) );
	$cc->{entry_edges_number}->delete(0,'end');
	$cc->{entry_edges_number}->insert(0,$en);
	
	$cc->calc;
	
	++$n;
	print "#### $n ####\n";
	
	my $sn = int(rand(5));
	sleep $sn;
}

MainLoop;

