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
		'F:/home/Koichi/Study/perl/CVSS/core/data/big_test/test.html',
#		'E:/home/higuchi/perl/core/data/test_big/test.html',
	dbname  =>
		'khc36',
#		'khc20',
)->open;

# テストプリント
print "kinds_all: ".mysql_words->num_kinds_all."\n";
print "all: ".mysql_words->num_all."\n";
print "kinds: ".mysql_words->num_kinds."\n\n";

#----------------#
#   テスト処理   #

use Benchmark;                                    # 時間計測用
my $t0 = new Benchmark;                           # 時間計測用

# 処理実行
my $result = mysql_conc->a_word(
	query   => '使う',
	kihon   => 1,
	context => 10,
	limit   => 1000,
	sort1   => "k",
	sort2   => "1l",
	sort3   => "1r",
);

my $t1 = new Benchmark;                           # 時間計測用
print timestr(timediff($t1,$t0)),"\n";            # 時間計測用

# 結果を出力
open (OUT,">test.txt");
foreach my $i (@{$result}){
	print OUT "$i->[0]  $i->[1]  $i->[2]\n";
}

