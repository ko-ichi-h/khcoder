#! /usr/bin/perl

#----------------#
#   決まり文句   #

use strict;
use vars qw($config_obj $project_obj $main_gui $splash $kh_version);

BEGIN{
	use Cwd qw(cwd);
	push @INC, cwd.'/kh_lib';
}

use mysql_ready;
use mysql_words;
use mysql_conc;
use mysql_morpho_check;
use kh_project;
use kh_projects;
use kh_morpho;
use kh_sysconfig;
use gui_window;

$config_obj = kh_sysconfig->readin('./config/coder.ini',&cwd);
$config_obj->sqllog(1);       # デバッグ用

#------------------------#
#   プロジェクトを開く   #

kh_project->temp(             # 分析対象ファイルのパスとDB名を直接指定
	target  =>
		'F:/home/Koichi/Study/perl/test_data/mainichi_small/DefaultFile.html',
#		'E:/home/higuchi/perl/core/data/test/ecom2.html',
	dbname  =>
		'khc8',
)->open;

# テストプリント
print "project opened:\n";
print "\tkinds_all: ".mysql_words->num_kinds_all."\n";
print "\tkinds: ".mysql_words->num_kinds."\n";
print "\tall: ".mysql_words->num_all."\n\n";

#----------------#
#   テスト処理   #

use Benchmark;                                    # 時間計測用
my $t0 = new Benchmark;                           # 時間計測用

# 処理実行
use mysql_doclength;
mysql_doclength->make("h5");

my $t1 = new Benchmark;                           # 時間計測用
print timestr(timediff($t1,$t0)),"\n";            # 時間計測用

# 結果を出力


