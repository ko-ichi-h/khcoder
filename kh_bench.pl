#!/usr/local/bin/perl

# ベンチマーク用の分析対象ファイル
use Cwd qw(cwd);
my $target = cwd."/bench/kokoro.txt";

#-----------------------------#
#   GUI無しのKH Coderを起動   #

use strict;
use vars qw($config_obj $project_obj $main_gui $splash $kh_version);

BEGIN {
	$kh_version = "2.alpha.7";
	use Cwd qw(cwd);
	use lib cwd.'/kh_lib';
	push @INC, cwd.'/dummy_lib' unless $^O eq 'MSWin32';
	use kh_sysconfig;
	$config_obj = kh_sysconfig->readin('./config/coder.ini',&cwd);
}

use mysql_ready;
use mysql_words;
use mysql_conc;
use kh_project;
use kh_projects;
use kh_morpho;

print "This is KH Coder.\n";

#------------------#
#   ベンチマーク   #

# プロジェクト登録
print "Registering $target...\n\t";
my $new = kh_project->new(
	target  => $target,
	comment => 'Benchmark',
) or return 0;
kh_projects->read->add_new($new) or die;
$new->open or die;
print "\tok\n";

# 前処理
use Benchmark;
my $t0 = new Benchmark;
  mysql_ready->first;
  $::project_obj->status_morpho(1);
my $t1 = new Benchmark;
  mysql_ready->first;
  $::project_obj->status_morpho(1);
my $t2 = new Benchmark;

print timestr(timediff($t1,$t0)),"\n";
print timestr(timediff($t2,$t1)),"\n";

# 簡易チェック1: 抽出語検索
use mysql_words;
my $result = mysql_words->search(
	query  => '死 殺 亡',
	method => 'OR',
	kihon  => '1',
	katuyo => '1',
	mode   => 'p'
);
foreach my $i (@{$result}){
	print "@{$i}\n";
}

# プロジェクト削除
my $p_n = @{kh_projects->read->list} - 1;
kh_projects->read->delete($p_n);


