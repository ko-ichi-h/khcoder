package mysql_getheader;
use strict;
use mysql_exec;

sub get{
	my $class = shift;
	my $tani  = shift;
	my $id    = shift;
	
	if ($tani eq 'dan' or $tani eq 'bun' or $tani eq ''){
		return '';
	}
	
	my @list = ('h1','h2','h3','h4','h5');
	
	my %id_info;
	my $sql;
	$sql .= "SELECT ";
	foreach my $i (@list){
		$sql .= "$i".'_id,';
		if ($i eq $tani){last;}
	}
	chop $sql;
	$sql .= "\nFROM $tani\n";
	$sql .= "WHERE id = $id";
	
	my $f = mysql_exec->select($sql,1)->hundle->fetch or return '';
	my $n = 0;
	foreach my $i (@{$f}){
		$id_info{$list[$n]} = $i;
		++$n;
	}
	
	$sql  = "SELECT hyoso.name\n";
	$sql .= "FROM hyosobun, hyoso\n";
	$sql .= "WHERE\n";
	$sql .= "    hyosobun.hyoso_id = hyoso.id\n";
	$sql .= "    AND bun_id = 0\n";
	$sql .= "    AND dan_id = 0\n";
	my $frag = 0; my $n = 5;
	foreach my $i (@list){
		if ($id_info{$i}){
			$sql .= "    AND $i"."_id = $id_info{$i}\n";
		} else {
			$sql .= "    AND $i"."_id = 0\n";
		}
	}
	$sql   .= "ORDER BY hyosobun.id";
	my @h = @{mysql_exec->select("$sql",1)->hundle->fetchall_arrayref};
	shift @h;
	pop   @h;
	my $h;
	foreach my $i (@h){
		$h .= $i->[0];
	}
	return Jcode->new($h)->sjis;
}
1;