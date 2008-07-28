#!/usr/local/bin/perl

use strict;
use Cwd;
use vars qw($config_obj $project_obj $main_gui $splash $kh_version);

$kh_version = "2.x Tester";

BEGIN {
	use Jcode;
	require kh_lib::Jcode_kh if $] > 5.008;

	# for Windows [1]
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
			$ENV{'PWD'} = Jcode->new($ENV{'PWD'},'sjis')->euc;
			$ENV{'PWD'} =~ s:\\:/:g ;
			$ENV{'PWD'} = Jcode->new($ENV{'PWD'},'euc')->sjis;
			#print "hoge\n";
			return $ENV{'PWD'};
		};
		*cwd = *Cwd::cwd = *Cwd::getcwd = *Cwd::fastcwd = *Cwd::fastgetcwd = *Cwd::_NT_cwd = \&Cwd::_win32_cwd;
		use warnings 'redefine';
	}

	# モジュールのパスを追加
	push @INC, cwd.'/kh_lib';
	push @INC, cwd.'/plugin';

	# for Windows [2]
	if ($^O eq 'MSWin32'){
		# コンソールを最小化
		require Win32::Console;
		Win32::Console->new->Title('Console of KH Coder');
		if (defined($PerlApp::VERSION) && substr($PerlApp::VERSION,0,1) >= 7 ){
			require Win32::API;
			my $win = Win32::API->new(
				'user32.dll',
				'FindWindow',
				'NP',
				'N'
			)->Call(
				0,
				"Console of KH Coder"
			);
			Win32::API->new(
				'user32.dll',
				'ShowWindow',
				'NN',
				'N'
			)->Call(
				$win,
				2
			);
		}
		# スプラッシュ
		require Tk::Splash;
		$splash = Tk::Splash->Show(
			Tk->findINC('kh_logo.bmp'),
			400,
			109,
			'',
		);
	} 
	# for Linux & Others
	else {
		push @INC, cwd.'/dummy_lib';
		if ($] > 5.008){
			require Tk::FBox;
			require Tk::FBox_kh;
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


# GUIの開始
$main_gui = gui_window::main->open;


#--------------------#
#   テスト用コード   #

use Cwd qw(cwd);
use lib cwd.'/auto_test/lib';
use kh_at;
use Benchmark;

print "Starting test procedures...\n";
open (STDOUT,">stdout.txt") or die;
my $t0 = new Benchmark;

kh_at::project_new->exec_test('project_new');      # テストファイル登録&前処理
#kh_at->open_test_project;

kh_at::pretreatment->exec_test('pretreatment');    # 前処理メニュー
kh_at::words->exec_test('words');                  # 抽出語メニュー
kh_at::out_var->exec_test('out_var');              # 外部変数メニュー
kh_at::cod->exec_test('cod');                      # コーディング
kh_at::transf->exec_test('transf');                # テキストファイル

kh_at->close_test_project;                         # プロジェクトを閉じる
kh_at->delete_test_project;                        # プロジェクトを削除

my $t1 = new Benchmark;

close (STDOUT);
open(STDOUT,'>&STDERR') or die;
print "Tests complete: ",timestr(timediff($t1,$t0)),"\n";

MainLoop;
