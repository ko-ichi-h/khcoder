package mysql_contxt;
use strict;
use mysql_exec;

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

sub new{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	bless $self, $class;

	$self->{max}  = 0 unless length($self->{max} );
	$self->{max2} = 0 unless length($self->{max2});

	return $self;
}

sub culc{
	my $self = shift;
	$self->wlist;
	
	foreach my $i (@{$self->{tani}}){
		$self->culc_each($i->[0]);
	}
}

sub culc_each{
	my $self = shift;
	my $tani = shift;
	
	my $n = 0;
	foreach my $i (@{$self->{wList}}){
		# テーブルの準備
		print "\r$tani, $n";
		my $table = 'ct_'."$tani".'_contxt_'."$i";
		mysql_exec->drop_table($table);
		mysql_exec->do("
			CREATE TEMPORARY TABLE $table (
				word int primary key,
				num  int
			)
		",1);
		
		# 当該の語を含む文書数
		my $d_num = mysql_exec->select("
			SELECT COUNT(DISTINCT $tani.id)
			FROM   hyosobun, $tani, hyoso, genkei
			WHERE\n$sql_join{$tani}
				AND hyosobun.hyoso_id = hyoso.id
				AND hyoso.genkei_id   = genkei.id
				AND genkei.id = $i
		",1)->hundle->fetch->[0];
		next unless $d_num;
		mysql_exec->do("
			INSERT INTO $table (word, num) VALUES (-1,$d_num)
		",1);
		
		# 
		
		++$n;
	}
	
}

#------------------------#
#   抽出語リストの作製   #

sub wlist{
	my $self = shift;
	my $sql = "
		SELECT genkei.id, genkei.name
		FROM   genkei, hselection
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			AND genkei.num >= $self->{min}
			AND genkei.nouse = 0
			AND (
	";
	
	my $n = 0;
	foreach my $i ( @{$self->{hinshi}} ){
		if ($n){ $sql .= ' OR '; }
		$sql .= "hselection.khhinshi_id = $i\n";
		++$n;
	}
	$sql .= ")\n";
	if ($self->{max}){
		$sql .= "AND genkei.num <= $self->{max}\n";
	}
	$sql .= "ORDER BY genkei.khhinshi_id, 0 - genkei.num\n";
	
	my $sth = mysql_exec->select($sql, 1)->hundle;
	my (@list, %name, %hinshi);
	while (my $i = $sth->fetch) {
		push @list,        $i->[0];
		$name{$i->[0]}   = $i->[1];
	}
	$sth->finish;
	$self->{wList}   = \@list;
	$self->{wName}   = \%name;
	return $self;
}



1;
