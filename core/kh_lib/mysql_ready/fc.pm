package mysql_ready::fc;
use strict;

my $st;
my $number_per_once = 100;

# SQL文（SELECT）で各語の初出場所を検索
sub calc_by_db{
	$st = 1;
	my $max = mysql_exec->select("select max(id) from genkei",1)
		->hundle->fetch->[0];
	
	mysql_exec->drop_table("fc_bun");
	mysql_exec->do("
		create table fc_bun(
			genkei_id int primary key not null,
			bun_idt   int
		)
	",1);
	
	while ($max >= $st){
		my $sql = &sql;
		mysql_exec->do($sql,1);
		$st += $number_per_once;
		#print ".";
	}
	#print "\n";
	
	return 1;
}

sub sql{
	my $sql = "
		insert into fc_bun (genkei_id, bun_idt)
		select genkei.id, min(hyosobun.bun_idt)
		from genkei, hyoso, hyosobun
		where
			genkei.id >= $st
			and genkei.id < $st + $number_per_once
			and genkei.id = hyoso.genkei_id
			and hyoso.id = hyosobun.hyoso_id
		group by genkei.id
	";
	return $sql;
}

1;

__END__

# Perlで全データをなめながらチェック
sub calc_by_perl{
	mysql_exec->drop_table("fc_bun");
	mysql_exec->do("
		create table fc_bun(
			genkei_id int primary key not null,
			bun_idt   int
		)
	",1);
	
	my $st = mysql_exec->select("
		select genkei.id, bun_idt
		from   hyosobun, hyoso, genkei
		where
			hyoso.id = hyosobun.hyoso_id
			and genkei.id = hyoso.genkei_id
	",1)->hundle;
	
	my %check; my %fc;
	while (my $i = $st->fetch){
		unless ($check{$i->[0]}){
			$fc{$i->[0]} = $i->[1];
			$check{$i->[0]} = 1;
		}
	}
}	# SQL文（SELECT）の方が速い （Perlの方がHDDには優しそうだが…）
