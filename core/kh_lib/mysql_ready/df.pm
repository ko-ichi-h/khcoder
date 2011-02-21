package mysql_ready::df;
use strict;

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
		
		# 処理確認用のprint
		#my $h = mysql_exec->select("explain\n$sql2")->hundle;
		#print "\n$sql2\n";
		#while (my $i = $h->fetch){
		#	foreach my $ii (@{$i}){
		#		print "$ii: ";
		#	}
		#	print "\n";
		#}
		
		mysql_exec->do($sql1.$sql2,1);
		
		#if ($switch){
		#	my_threads->exec1("mysql_exec->do(\"$sql1 $sql2\",1);");
		#	$switch = 0;
		#} else {
		#	my_threads->exec2("mysql_exec->do(\"$sql1 $sql2\",1);");
		#	$switch = 1;
		#}
	}
	
	#my_threads->wait1;
	#my_threads->wait2;
	return 1;
}



1;