package kh_cod::a_code::atom::word;
use base qw(kh_cod::a_code::atom);
use strict;

use mysql_a_word;
use mysql_exec;

my %sql_join = (
	'h5' =>
		'
			    h5.h5_id = hyosobun.h5_id
			AND h5.h4_id = hyosobun.h4_id
			AND h5.h3_id = hyosobun.h3_id
			AND h5.h2_id = hyosobun.h2_id
			AND h5.h1_id = hyosobun.h1_id
		',
);
my %sql_group = (
	'h5' =>
		'hyosobun.h5_id, hyosobun.h4_id, hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
);


sub expr{
	my $self = shift;
	my $t = $self->tables;
	unless ($t){ return '0';}
	
	my ($sql, $n) = ('',0);
	foreach my $i (@{$t}){
		if ($n){$sql .= ' or '}
		$sql .= "$i.num";
		++$n;
	}
	if ($n > 1){
		$sql = '( '."$sql".' )';
	}
	return $sql;
}

sub ready{
	my $self = shift;
	my $tani = shift;
	
	my $list = mysql_a_word->new(genkei => $self->raw)->genkei_ids;
	unless ($list){
		return '';
	}
	
	foreach my $i (@{$list}){
		my $table = 'ct_'."$tani".'_kihon_'. "$i";
		push @{$self->{tables}}, $table;
		
		mysql_exec->do("drop table $table");
		mysql_exec->do("
			CREATE TABLE $table (
				id INT primary key not null,
				num INT
			)
		",1);
		mysql_exec->do("
			INSERT
			INTO $table (id, num)
			SELECT $tani.id, count(*)
			FROM $tani, hyosobun, hyoso, genkei
			WHERE
				hyosobun.hyoso_id = hyoso.id
				AND genkei.id = hyoso.genkei_id
				AND genkei.id = $i
				AND $sql_join{$tani}
			GROUP BY $sql_group{$tani}
		",1);
		
	}
}

sub tables{
	my $self = shift;
	return $self->{tables};
}

sub pattern{
	return '.*';
}
sub name{
	return 'word';
}

1;