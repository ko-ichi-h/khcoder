#! /usr/bin/perl

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

kh_project->temp(             # 分析対象ファイルのパスとDB名を直接指定
	target  =>
#		'F:/home/Koichi/Study/perl/test_data/kokoro/kokoro.txt',
		Jcode->new('E:/home/higuchi/perl/core/data/ohsumi/H1D607DX_931s_生活意識for_WM_Q1_6.txt')->sjis,
	dbname  =>
		'khc14',
)->open;

# テストプリント
use mysql_words;
print "project opened:\n";
print "\tkinds_all: ".mysql_words->num_kinds_all."\n";
print "\tkinds: ".mysql_words->num_kinds."\n";
print "\tall: ".mysql_words->num_all."\n\n";

#--------------------#
#   以下テスト処理   #
#--------------------#

# 時間計測(1)
use Benchmark;
my $t0 = new Benchmark;

use kh_csv;
my $dun_num = mysql_exec->select("select count(*) from dan")
	->hundle->fetch->[0];

#----------------------#
#   品詞度数（茶筌）   #

# 品詞リスト作成
my %hinshi;
my $h = mysql_exec->select("
	SELECT   id, name
	FROM     hinshi
	ORDER BY name
")->hundle or die;
while (my $i = $h->fetch){
	$hinshi{$i->[0]} = $i->[1];
}

# データ作成
my $sql = "select\n";
foreach my $i (sort {$a <=> $b} keys %hinshi){
	$sql .= "\tcount(if(hinshi.id = $i,1,NULL)),\n";
}
chop $sql; chop $sql;
$sql .= "
	from hyosobun,hyoso,genkei,hinshi,khhinshi
	where
		hyosobun.hyoso_id = hyoso.id
		and hyoso.genkei_id = genkei.id
		and genkei.hinshi_id = hinshi.id
		and genkei.khhinshi_id = khhinshi.id
		and khhinshi.name != 'HTMLタグ'
		and dan_id > 0
	group by h1_id,h2_id,h3_id,h4_id,h5_id,dan_id
	order by hyosobun.id";
$h = mysql_exec->select($sql)->hundle;

# 書き出し
open (OUT,">hinshi1_1.csv") or die;
my $fstline;                                      # 一行目
foreach my $i (sort {$a <=> $b} keys %hinshi){
	$fstline .= Jcode->new("$hinshi{$i},")->sjis;
}
chop $fstline;
print OUT "$fstline\n";
while (my $i = $h->fetch){
	my $line;
	foreach my $ii (@{$i}){
		$line .= "$ii,";
	}
	chop $line;
	print OUT "$line\n";
}
close OUT;

#--------------------------#
#   品詞別リスト（茶筌）   #

# データ作成
$sql = "
	select dan.id, hyoso.name, hinshi.id
	from hyosobun,hyoso,genkei,hinshi,khhinshi,dan
	where
		hyosobun.hyoso_id = hyoso.id
		and hyoso.genkei_id = genkei.id
		and genkei.hinshi_id = hinshi.id
		and genkei.khhinshi_id = khhinshi.id
		and khhinshi.name != 'HTMLタグ'
		and hyosobun.h1_id = dan.h1_id
		and hyosobun.h2_id = dan.h2_id
		and hyosobun.h3_id = dan.h3_id
		and hyosobun.h4_id = dan.h4_id
		and hyosobun.h5_id = dan.h5_id
		and hyosobun.dan_id = dan.dan_id
	order by hyosobun.id";
$h = mysql_exec->select($sql)->hundle;
my $data;
while (my $i = $h->fetch){
	$data->{$i->[0]}{$i->[2]} .= "$i->[1],"
}

# 書き出し

open (OUT,">hinshi1_2.csv") or die;
print OUT "$fstline\n";
for (my $n = 1; $n <= $dun_num; ++$n){
	my $line;
	foreach my $i (sort {$a <=> $b} keys %hinshi){
		my $cell = $data->{$n}{$i};
		chop $cell;
		$cell = kh_csv->value_conv($cell);
		$cell = Jcode->new($cell)->sjis;
		$line .= "$cell,";
	}
	chop $line;
	print OUT "$line\n";
}
close (OUT);





# 時間計測(2)
my $t1 = new Benchmark;
print timestr(timediff($t1,$t0)),"\n";


__END__



	#--------------------#
	#   品詞度数（KH）   #

	# 品詞リスト作成
	my %hinshi;
	my $h = mysql_exec->select("
		SELECT   id, name
		FROM     khhinshi
	")->hundle or die;
	while (my $i = $h->fetch){
		$hinshi{$i->[0]} = $i->[1];
	}

	# SQL作成
	my $sql = "select\n";
	foreach my $i (sort {$a <=> $b} keys %hinshi){
		$sql .= "\tcount(if(khhinshi.id = $i,1,NULL)),\n";
	}
	chop $sql; chop $sql;
	$sql .= "
		from hyosobun,hyoso,genkei,hinshi,khhinshi
		where
			hyosobun.hyoso_id = hyoso.id
			and hyoso.genkei_id = genkei.id
			and genkei.hinshi_id = hinshi.id
			and genkei.khhinshi_id = khhinshi.id
			and khhinshi.name != 'HTMLタグ'
			and dan_id > 0
		group by h1_id,h2_id,h3_id,h4_id,h5_id,dan_id
		order by hyosobun.id";
	$h = mysql_exec->select($sql)->hundle;

	# 書き出し
	open (OUT,">hinshi2_1.csv") or die;
	my $fstline;                                      # 一行目
	foreach my $i (sort {$a <=> $b} keys %hinshi){
		$fstline .= Jcode->new("$hinshi{$i},")->sjis;
	}
	chop $fstline;
	print OUT "$fstline\n";
	while (my $i = $h->fetch){
		my $line;
		foreach my $ii (@{$i}){
			$line .= "$ii,";
		}
		chop $line;
		print OUT "$line\n";
	}
	close OUT;

	#------------------------#
	#   品詞別リスト（KH）   #

	# データ作成
	$sql = "
		select dan.id, hyoso.name, khhinshi.id
		from hyosobun,hyoso,genkei,hinshi,khhinshi,dan
		where
			hyosobun.hyoso_id = hyoso.id
			and hyoso.genkei_id = genkei.id
			and genkei.hinshi_id = hinshi.id
			and genkei.khhinshi_id = khhinshi.id
			and khhinshi.name != 'HTMLタグ'
			and hyosobun.h1_id = dan.h1_id
			and hyosobun.h2_id = dan.h2_id
			and hyosobun.h3_id = dan.h3_id
			and hyosobun.h4_id = dan.h4_id
			and hyosobun.h5_id = dan.h5_id
			and hyosobun.dan_id = dan.dan_id
		order by hyosobun.id";
	$h = mysql_exec->select($sql)->hundle;
	$data = undef;
	while (my $i = $h->fetch){
		$data->{$i->[0]}{$i->[2]} .= "$i->[1],"
	}

	# 書き出し

	open (OUT,">hinshi2_2.csv") or die;
	print OUT "$fstline\n";
	for (my $n = 1; $n <= $dun_num; ++$n){
		my $line;
		foreach my $i (sort {$a <=> $b} keys %hinshi){
			my $cell = $data->{$n}{$i};
			chop $cell;
			$cell = kh_csv->value_conv($cell);
			$cell = Jcode->new($cell)->sjis;
			$line .= "$cell,";
		}
		chop $line;
		print OUT "$line\n";
	}
	close (OUT);
