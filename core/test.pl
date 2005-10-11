#! /usr/bin/perl

#---------------------------------------------#
#   GUIを使わずにテスト処理を行うスクリプト   #
#---------------------------------------------#

#----------------#
#   決まり文句   #

use strict;
use vars qw($config_obj $project_obj $kh_version);
BEGIN{
	use Cwd qw(cwd);
	use lib cwd.'/kh_lib';
	use kh_sysconfig;
	$config_obj = kh_sysconfig->readin('./config/coder.ini',&cwd);
}

$config_obj->sqllog(1);       # デバッグ用

use kh_project;
use kh_projects;

#------------------------#
#   プロジェクトを開く   #

# 分析対象ファイルのパスとDB名を直接指定
kh_project->temp(
	target  => 'F:/home/Koichi/Study/perl/test_data/kokoro/kokoro.txt',
	dbname  => 'khc14',
)->open;

# テストプリント
use mysql_words;
print "project opened:\n";
print "\tkinds_all: ".mysql_words->num_kinds_all."\n";
print "\tkinds: ".mysql_words->num_kinds."\n";
print "\tall: ".mysql_words->num_all."\n\n";

#----------------#
#   テスト処理   #
#----------------#

# 時間計測(1)
use Benchmark;
my $t0 = new Benchmark;


# ここでテスト処理実行


# 時間計測(2)
my $t1 = new Benchmark;
print timestr(timediff($t1,$t0)),"\n";


__END__
