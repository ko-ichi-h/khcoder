package mysql_morpho_check;
use strict;
use mysql_exec;

sub search{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	unless ( length($self->{query}) ){
		return;
	}
	my $h = mysql_exec->select("
		SELECT hyoso.name, hyosobun.bun_idt
		FROM bun, hyosobun LEFT JOIN hyoso ON hyosobun.hyoso_id = hyoso.id
		WHERE
			bun.rowtxt LIKE \'%$self->{query}%\'
			AND hyosobun.bun_idt  = bun.id
		ORDER BY hyosobun.id
		LIMIT 2000
	",1)->hundle;
	
	my %d;
	while (my $i = $h->fetch){
		if ( length($d{$i->[1]}) ){
			$d{$i->[1]} .= " / $i->[0]";
		} else {
			$d{$i->[1]} .= $i->[0];
		}
	}
	my @d;
	for my $i (sort {$a <=> $b} keys %d ){
		push @d, [$d{$i}, $i];
	}
	return \@d;
}

sub detail{
	my $class = shift;
	my $query = shift;
	return mysql_exec->select("
		SELECT hyoso.name,genkei.name,hselection.name, hinshi.name, katuyo.name
		FROM hyoso, genkei, hselection, hinshi, katuyo, hyosobun
		WHERE
			hyosobun.bun_idt = $query
			AND hyosobun.hyoso_id = hyoso.id
			AND hyoso.genkei_id = genkei.id
			AND hyoso.katuyo_id = katuyo.id
			AND genkei.khhinshi_id = hselection.khhinshi_id
			AND genkei.hinshi_id = hinshi.id
		ORDER BY hyosobun.id
	",1)->hundle->fetchall_arrayref;
}

1;