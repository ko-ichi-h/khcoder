package mysql_conc;
use strict;
use mysql_exec;

sub a_word{
	my $class = shift;
	my %args  = @_;
	
	print "0-";
	
	# 表層語のリストアップ
	my @hyoso;
	if ($args{kihon}){
		my $d = mysql_exec->select("
			SELECT hyoso.id
			FROM   genkei, hyoso
			WHERE
				    genkei.id = hyoso.genkei_id
				AND genkei.name = '$args{query}'
		")->hundle->fetchall_arrayref;
		foreach my $i (@{$d}){
			push @hyoso, $i->[0];
		}
	} else {
#		push @hyoso, $query;
	}
	
	print "1-";
	
	# 出現位置のリストアップ
	
	my $sql;
	$sql .= "SELECT id\n";
	$sql .= "FROM hyosobun\n";
	$sql .= "WHERE\n";
	my $n = 0;
	foreach my $i (@hyoso){
		if ($n){
			$sql .= 'OR ';
		}
		$sql .= "hyoso_id = $i\n";
		++$n;
	}
	my $points = mysql_exec->select($sql,1)->hundle->fetchall_arrayref;
	
	print "2-";

	# 前後10づつのhyoso.idを取得

	my @hyoso_order;
	foreach my $i (@{$points}){
		my $p1 = $i->[0] - 10;
		my $p2 = $i->[0] - 1;
		my $n1 = $i->[0] + 1;
		my $n2 = $i->[0] + 10;
		
		my $prev = mysql_exec->select("
			SELECT hyoso_id
			FROM hyosobun
			WHERE id >= $p1 AND id <= $p2
		",1)->hundle->fetchall_arrayref;
		
		my $center =  mysql_exec->select("
			SELECT hyoso_id
			FROM hyosobun
			WHERE id = $i->[0]
		",1)->hundle->fetchall_arrayref;
		
		my $next =  mysql_exec->select("
			SELECT hyoso_id
			FROM hyosobun
			WHERE id >= $n1 AND id <= $n2
		",1)->hundle->fetchall_arrayref;
		
		my $current;
		push @{$current}, _listing($prev);
		push @{$current}, _listing($center);
		push @{$current}, _listing($next);
		
		push @hyoso_order, $current;
	}

	print "3-";

	# IDに対応する表層語を取得
	my %ids;
	foreach my $i (@hyoso_order){
		foreach my $h (@{$i}){
			foreach my $j (@{$h}){
				++$ids{$j};
			}
		}
	}
	
	$sql = "SELECT id, name \n FROM hyoso \n WHERE \n";
	my $temp = '';
	my $n = 0;
	my %id2word;
	foreach my $i (keys %ids){
		$temp .= "OR id = $i\n";
		++$n;
		if ($n = 500){
			substr($temp, 0, 2) = '';
			my $tempsql = "$sql"."$temp";
			my $id2word =
				mysql_exec->select($tempsql,1)->hundle->fetchall_arrayref;
			foreach my $i (@{$id2word}){
				$id2word{$i->[0]} = $i->[1];
			}
			$temp = '';
			$n = 0;
		}
	}
	
	if ($temp){
		substr($temp, 0, 2) = '';
		my $tempsql = "$sql"."$temp";
		my $id2word =
			mysql_exec->select($tempsql,1)->hundle->fetchall_arrayref;
		foreach my $i (@{$id2word}){
			$id2word{$i->[0]} = $i->[1];
		}
	}
	

	
	print "4->";
	
	# 結果の作成
	
	my $return;
	foreach my $i (@hyoso_order){
		my $current;
		foreach my $h (@{$i}){
			my $part;
			foreach my $g (@{$h}){
				$part .= $id2word{$g};
			}
			push @{$current}, $part;
		}
		push @{$return}, $current;
	}
	
	return $return;
}


sub _listing{
	my $result = shift;
	my $return;
	foreach my $i (@{$result}){
		push @{$return}, $i->[0];
	}
	return $return;
}


1;
