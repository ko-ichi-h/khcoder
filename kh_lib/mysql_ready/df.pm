package mysql_ready::df;
use strict;
use Benchmark;

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


sub calc{
	
	my $switch = 0;
	
	foreach my $tani ('bun','dan','h1','h2','h3','h4','h5'){
		# 見出しが存在するかどうかをチェック
		my $check_col = '';
		if ($tani eq 'bun'){
			$check_col = 'bun_idt';
		} else {
			$check_col = "$tani".'_id';
		}
		unless (
			mysql_exec->select("select max($check_col) from hyosobun",1)
			->hundle->fetch->[0]
		){
			next;
		}
		
		my $heap = '';
		$heap = 'TYPE=HEAP' if $::config_obj->use_heap;
		
		#print "DF: $tani\n";
		# 文以外の単位では中間テーブルを作成（hyosobun.idと各単位.idを直結）
		my $tain_hb = '';
		unless ($tani eq 'bun'){
			my $t0 = new Benchmark;
			$tain_hb = $tani.'_hb';
			mysql_exec->drop_table("$tain_hb");
			mysql_exec->do("
				CREATE TABLE $tain_hb(
					hyosobun_id INT primary key,
					tid         INT
				) $heap
			",1);
			mysql_exec->do("
				INSERT INTO $tain_hb (hyosobun_id, tid)
				SELECT hyosobun.id, $tani.id
				FROM hyosobun, $tani
				WHERE
					$sql_join{$tani}
			",1);
			my $t1 = new Benchmark;
			#print "TMP\t",timestr(timediff($t1,$t0)),"\n";
		}
		
		# テーブル作製
		my $t0 = new Benchmark;
		mysql_exec->drop_table("df_$tani");
		mysql_exec->do("
			CREATE TABLE df_$tani(
				genkei_id INT primary key,
				f         INT
			)
		",1);

		# 集計の実行
		if ($tani eq 'bun'){  # 文単位
			mysql_exec->do("
				INSERT INTO df_$tani (genkei_id, f)
				SELECT genkei.id, COUNT(DISTINCT $tani.id)
				FROM hyosobun, $tani, hyoso, genkei
				WHERE
					$sql_join{$tani}
					AND hyosobun.hyoso_id = hyoso.id
					AND hyoso.genkei_id = genkei.id
				GROUP BY genkei.id
			",1);
		} else {              # それ以外の単位
			mysql_exec->do("
				INSERT INTO df_$tani (genkei_id, f)
				SELECT genkei.id, COUNT(DISTINCT tid)
				FROM hyosobun, $tain_hb, hyoso, genkei
				WHERE
					    hyosobun.id = $tain_hb.hyosobun_id
					AND hyosobun.hyoso_id = hyoso.id
					AND hyoso.genkei_id = genkei.id
				GROUP BY genkei.id
			",1);
		}

		# 中間テーブルをHEAPからMyISAMへ
		if ($tani ne 'bun' && length($heap) != 0){
			my $heap_table = $tain_hb.'_heap';
			mysql_exec->drop_table($heap_table);
			mysql_exec->do("ALTER TABLE $tain_hb RENAME $heap_table",1);
			mysql_exec->do("
				CREATE TABLE $tain_hb(
					hyosobun_id INT primary key,
					tid         INT
				)
			",1);
			mysql_exec->do("
				INSERT INTO $tain_hb (hyosobun_id, tid)
				SELECT hyosobun_id, tid
				FROM $heap_table
			",1);
			mysql_exec->drop_table($heap_table);
		}

		my $t1 = new Benchmark;
		#print "Main\t",timestr(timediff($t1,$t0)),"\n";
	}
	
	return 1;
}

sub old{
		my $tani;
		
		# テーブル作製
		mysql_exec->drop_table("df_$tani");
		mysql_exec->do("
			CREATE TABLE df_$tani(
				genkei_id INT primary key,
				f         INT
			)
		",1);
		# 集計の実行
		my $sql1 = "INSERT INTO df_$tani (genkei_id, f)\n";
		my $sql2 = "SELECT genkei.id, COUNT(DISTINCT $tani.id)\n";
		$sql2 .= "FROM hyosobun, $tani, hyoso, genkei\n";
		$sql2 .= "WHERE\n$sql_join{$tani}";
		$sql2 .= "\tAND hyosobun.hyoso_id = hyoso.id\n";
		$sql2 .= "\tAND hyoso.genkei_id = genkei.id\n";
		$sql2 .= "GROUP BY genkei.id";
}

1;