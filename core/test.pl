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
#------------------------#

kh_project->temp(             # 分析対象ファイルのパスとDB名を直接指定
	target  =>
		'F:/home/Koichi/Study/perl/test_data/kokoro/kokoro.txt',
#		'E:/home/higuchi/perl/core/data/big_test/mainichi2.txt',
	dbname  =>
		'khc4',
)->open;

# テストプリント
print "project opened:\n";
print "\tkinds_all: ".mysql_words->num_kinds_all."\n";
print "\tkinds: ".mysql_words->num_kinds."\n";
print "\tall: ".mysql_words->num_all."\n\n";

#----------------#
#   テスト処理   #
#----------------#

use Benchmark;                                    # 時間計測用
my $t0 = new Benchmark;                           # 時間計測用

#--------------------#
#   テスト処理実行   #

my $tani = 'h2';

# コーディング実行
use kh_cod;
my $c = kh_cod->read_file('f:/home/koichi/study/perl/test_data/kokoro/theme.cod')->code($tani);
print ("tab: ", $c->codes->[0]->res_table, "\n");
my $m_table = $c->codes->[0]->res_table;
	# $c->codes->[0]->res_tableを使って連関規則を算出

# 以下の条件で連関規則を計算
# 単位         -> $tani
# 条件テーブル -> $m_table

my %sql_join = (
	'bun' =>
		'bun.id = hyosobun.bun_idt',
	'dan' =>
		'
			    dan.dan_id = hyosobun.dan_id
			AND dan.h5_id = hyosobun.h5_id
			AND dan.h4_id = hyosobun.h4_id
			AND dan.h3_id = hyosobun.h3_id
			AND dan.h2_id = hyosobun.h2_id
			AND dan.h1_id = hyosobun.h1_id
		',
	'h5' =>
		'
			    h5.h5_id = hyosobun.h5_id
			AND h5.h4_id = hyosobun.h4_id
			AND h5.h3_id = hyosobun.h3_id
			AND h5.h2_id = hyosobun.h2_id
			AND h5.h1_id = hyosobun.h1_id
		',
	'h4' =>
		'
			    h4.h4_id = hyosobun.h4_id
			AND h4.h3_id = hyosobun.h3_id
			AND h4.h2_id = hyosobun.h2_id
			AND h4.h1_id = hyosobun.h1_id
		',
	'h3' =>
		'
			    h3.h3_id = hyosobun.h3_id
			AND h3.h2_id = hyosobun.h2_id
			AND h3.h1_id = hyosobun.h1_id
		',
	'h2' =>
		'
			    h2.h2_id = hyosobun.h2_id
			AND h2.h1_id = hyosobun.h1_id
		',
	'h1' =>
		'h1.h1_id = hyosobun.h1_id',
);

# 条件付き確立の分母
my $denom1 = mysql_exec->select("SELECT count(*) from $m_table",1)
	->hundle->fetch->[0]; 
# 条件付き確立の計算
mysql_exec->drop_table("ct_ass_p");
mysql_exec->do("
	CREATE TABLE ct_ass_p(
		genkei_id INT primary key,
		p         FLOAT
	) TYPE=HEAP
",1);
my $sql = "INSERT INTO ct_ass_p (genkei_id, p)\n";
$sql .= "SELECT genkei.id, COUNT(DISTINCT $tani.id) / $denom1\n";
$sql .= "FROM hyosobun, $tani, $m_table, hyoso, genkei, hselection\n";
$sql .= "WHERE\n$sql_join{$tani}";
$sql .= "\tAND hyosobun.hyoso_id = hyoso.id\n";
$sql .= "\tAND hyoso.genkei_id = genkei.id\n";
$sql .= "\tAND genkei.nouse = 0\n";
$sql .= "\tAND hselection.khhinshi_id = genkei.khhinshi_id\n";
$sql .= "\tAND hselection.ifuse = 1\n";
$sql .= "\tAND $m_table.id = $tani.id\n";
$sql .= "GROUP BY genkei.id";
mysql_exec->do($sql,1);

# 全体確立の分母
my $denom2 = mysql_exec->select("SELECT count(*) from $tani",1)
	->hundle->fetch->[0]; 
# 全体確率の計算
mysql_exec->drop_table("ct_ass_a");
mysql_exec->do("
	CREATE TABLE ct_ass_a(
		genkei_id INT primary key,
		p         FLOAT
	) TYPE=HEAP
",1);
$sql = "INSERT INTO ct_ass_a (genkei_id, p)\n";
$sql .= "SELECT genkei.id, COUNT(DISTINCT $tani.id) / $denom2\n";
$sql .= "FROM hyosobun, $tani, ct_ass_p, hyoso, genkei\n";
$sql .= "WHERE\n$sql_join{$tani}";
$sql .= "\tAND hyosobun.hyoso_id = hyoso.id\n";
$sql .= "\tAND hyoso.genkei_id = genkei.id\n";
$sql .= "\tAND ct_ass_p.genkei_id = genkei.id\n";
$sql .= "GROUP BY genkei.id";
mysql_exec->do($sql,1);

# コーディングに使用した単語を捨てるロジック・・・



#--------------------#
#   テスト処理終了   #

my $t1 = new Benchmark;                           # 時間計測用
print timestr(timediff($t1,$t0)),"\n";            # 時間計測用

# 結果を出力


__END__


explain
SELECT
    genkei.id, count(DISTINCT h2.id)
FROM hyosobun, h2, hyoso, genkei, hselection
WHERE
             h2.h2_id = hyosobun.h2_id
    AND h2.h1_id = hyosobun.h1_id
    AND hyosobun.hyoso_id = hyoso.id
    AND hyoso.genkei_id = genkei.id
    AND genkei.nouse = 0
    AND hselection.khhinshi_id = genkei.khhinshi_id
    AND hselection.ifuse = 1
Group by genkei.id
