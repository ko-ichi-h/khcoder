package mysql_conc;
use strict;
use mysql_exec;

sub a_word{
	my $class = shift;
	my %args  = @_;

	unless ($args{length}){
		$args{length} = 20;
	}
	my (@left, @right);
	for (my $n = 1; $n <= $args{length}; ++$n){
		my $l = $args{length} - $n + 1;
		$l = 'l'."$l";
		push @left, $l;
		push @right, "r$n";
	}
	my @scanlist = (@left,"center",@right);


	print "0: getting hyoso list\n";
	
	# 表層語のリストアップ
	my @hyoso;
#	if ($args{kihon}){
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
#	} else {
#		push @hyoso, $query;
#	}

	unless (@hyoso){
		return 0;
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
	
	print "2: Creating temp table\n";

	# Temp Table作成

	mysql_exec->do("drop table temp_conc");
	$sql  = "create table temp_conc (\n";
	$sql .= "id int auto_increment primary key not null,\n";
	foreach my $i (@scanlist){
		$sql .= "$i int,";
	}
	chop $sql;
	$sql .= ")";
	mysql_exec->do($sql,1);
	
	foreach my $i (@{$points}){
		my $p = $i->[0] - $args{length};
		my $n = $i->[0] + $args{length};
		my $sql  = "SELECT hyoso_id\n FROM hyosobun\n WHERE\n";
		$sql .= "id >= $p AND id <= $n \n";
		$sql .= "ORDER BY id";
		my $r = mysql_exec->select("$sql",1)->hundle->fetchall_arrayref;
		$sql  = "INSERT INTO temp_conc\n (";
		foreach my $h (@scanlist){
			$sql .= "$h,";
		}
		chop $sql;		
		$sql .= ") VALUES (";
		foreach my $h (@{$r}){
			$sql .= "$h->[0],";
		}
		chop $sql;
		$sql .= ")";
		mysql_exec->do("$sql",1);
	}
	
	# 結果の出力
	print "3: Sorting...\n";
	
	my $result;
	foreach my $i (@scanlist){
		my $sql  = "SELECT hyoso.name FROM ( hyoso, temp_conc ) WHERE";
		   $sql .= "	temp_conc.$i = hyoso.id\n";
		   $sql .= "ORDER BY temp_conc.id";
		$result->{$i} = mysql_exec->select($sql,1)->hundle->fetchall_arrayref;
	}

	print "4: Formating output...\n";
	#open (TOUT,">test2.txt") or die;
	#use Data::Dumper;
	#print TOUT Dumper($result);

	my $return;
	my $last = @{$points};
	--$last;

	
	for (my $n = 0; $n <= $last; ++$n){
		foreach my $i (@left){
			$return->[$n][0] .= $result->{$i}[$n][0];
		}
		foreach my $i (@right){
			$return->[$n][2] .= $result->{$i}[$n][0];
		}
		$return->[$n][1] = $result->{center}[$n][0];
	}



	return $return;
}

1;
