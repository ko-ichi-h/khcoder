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

#------------------------#
#   プロジェクトを開く   #

kh_project->temp(             # 分析対象ファイルのパスとDB名を直接指定
	target  =>
		'F:/home/Koichi/Study/perl/CVSS/core/data/big_test/inet_and_hp.html',
	dbname  => 'khc36',
)->open;

# テストプリント
print "kinds_all: ".mysql_words->num_kinds_all."\n";
print "all: ".mysql_words->num_all."\n";
print "kinds: ".mysql_words->num_kinds."\n\n";

#----------------#
#   テスト処理   #

use Benchmark;                                    # 時間計測用
my $t0 = new Benchmark;                           # 時間計測用

my $result = mysql_conc->a_word(
	query  => '人',
	kihon => '1'
);

my $t1 = new Benchmark;                           # 時間計測用
print timestr(timediff($t1,$t0)),"\n";            # 時間計測用

open (OUT,">test.txt");
foreach my $i (@{$result}){
	print OUT "$i->[0]  $i->[1]  $i->[2]\n";
}

