package mysql_conc;
use strict;
use mysql_exec;

sub a_word{
	my $class = shift;
	my %args  = @_;
	
	print "0: getting hyoso list\n";
	
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
	
	print "1: getting places\n";
	
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
	
	print "2: getting context(id)\n";

	# 前後のhyoso.idを取得

	my $order = [()];
	$sql  = "SELECT id, hyoso_id\n FROM hyosobun\n WHERE\n";
	my $n2 = 0;
	my $temp = '';
	foreach my $i (@{$points}){
		my $p = $i->[0] - $args{context};
		my $n = $i->[0] + $args{context};
		$temp .= "OR ( id >= $p AND id <= $n )\n";
		++$n2;
		if ($n2 >= 100){
			substr($temp,0,2) = '';
			my $hoge = &run_sql($sql,$temp);
			@{$order} = (@{$order},@{$hoge});
			$temp = ''; $n2 = 0;
		}
	}
	if ($temp){
		substr($temp,0,2) = '';
		my $hoge = &run_sql($sql,$temp);
		@{$order} = (@{$order},@{$hoge});
	}

	sub run_sql{ 
		my $sql = shift;
		my $temp = shift;
		$sql .= $temp;
		my $result = mysql_exec->select($sql,1)->hundle->fetchall_arrayref;
		return $result;
	}

	return 0;
}
1;

__END__
	print "3: getting ready for id2word conv\n";

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
	
	print "4: id2word conversion\n";
	
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
