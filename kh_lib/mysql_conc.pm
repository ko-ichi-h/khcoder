package mysql_conc;
use strict;
use mysql_exec;
use mysql_a_word;

my ( $l_query, $l_hinshi, $l_katuyo, $l_length);
my $docs_per_once = 200;

sub initialize{
	($l_query, $l_hinshi, $l_katuyo, $l_length) = ('','','','')
}

sub a_word{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	bless $self, $class;

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
	$self->{scanlist} = \@scanlist;
	$self->{left}     = \@left;
	$self->{right}    = \@right;

	unless (
		   ( $l_query eq $args{query} )
		&& ( $l_hinshi eq $args{hinshi} )
		&& ( $l_katuyo eq $args{katuyo} )
		&& ( $l_length == $args{length} )
	){
		my $hyoso = $self->_hyoso;
		unless ($hyoso){
			return 0;
		}
		my $points = $self->_find($hyoso);
	}
	$l_query = $args{query};
	$l_hinshi = $args{hinshi};
	$l_katuyo = $args{katuyo};
	$l_length = $args{length};

	$self->_sort;
	
	return $self;
	# return ($self->_format,$self->_count);
}

sub last_words{
	my $self;
	my $class = shift;
	my %args;
	$args{query} = $l_query;
	$args{hinshi} = $l_hinshi;
	$args{katuyo} = $l_katuyo;
	$self = \%args;
	bless $self, $class;
	return ($self->_hyoso);
}


sub _hyoso{
	my $self = shift;
	
	return mysql_a_word->new(
		genkei   => $self->{query},
		katuyo   => $self->{katuyo},
		khhinshi => $self->{hinshi}
	)->hyoso_id_s;
}

sub _find{
	my $self = shift;
	my %args = %{$self};
	my @hyoso = @{$_[0]};
	my $sql = '';

	print "\n1: searching...\n";

	# Temp Table作成（left + center）	
	mysql_exec->drop_table("temp_concl");
	$sql  = "create table temp_concl (\n";
	$sql .= "id int primary key not null,\n";
	foreach my $i (@{$self->{left}},'center'){
		$sql .= "$i int,";
	}
	chop $sql;
	$sql .= ") TYPE = HEAP";
	mysql_exec->do($sql,1);

	$sql = '';
	$sql .= "INSERT INTO temp_concl\n(id, ";
	foreach my $i (@{$self->{left}},'center'){
		$sql .= "$i,";
	}
	chop $sql;
	$sql .= ")\n";
	$sql .= "SELECT center.id, ";
	foreach my $i (@{$self->{left}},'center'){
		$sql .= "$i".".hyoso_id,";
	}
	chop $sql;
	$sql .= "\n";
	$sql .= "FROM hyosobun as center\n";
	foreach my $i (@{$self->{left}}){
		my $num = $i;
		substr($num,0,1) = '';
		$sql .= "	LEFT JOIN hyosobun as $i ON ( center.id - $num ) = $i".".id\n";
	}
	$sql .= "WHERE\n";
	my $n = 0;
	foreach my $i (@hyoso){
		if ($n){
			$sql .= 'OR ';
		}
		$sql .= "center.hyoso_id = $i\n";
		++$n;
	}
	mysql_exec->do($sql,1);
	
	# Temp Table作成（all）
	mysql_exec->drop_table("temp_conc");
	$sql  = "create table temp_conc (\n";
	$sql .= "id int primary key not null,\n";
	foreach my $i (@{$self->{scanlist}}){
		$sql .= "$i int,";
	}
	chop $sql;
	$sql .= ") TYPE = HEAP";
	mysql_exec->do($sql,1);
	
	$sql = '';
	$sql .= "INSERT INTO temp_conc\n(id, ";
	foreach my $i (@{$self->{scanlist}}){
		$sql .= "$i,";
	}
	chop $sql;
	$sql .= ")\n";
	$sql .= "SELECT center.id, ";
	foreach my $i (@{$self->{left}}, 'center'){
		$sql .= "temp_concl.$i,";
	}
	foreach my $i (@{$self->{right}}){
		$sql .= "$i".".hyoso_id,";
	}
	chop $sql;
	$sql .= "\n";
	$sql .= "FROM hyosobun as center, temp_concl\n";
	foreach my $i (@{$self->{right}}){
		my $num = $i;
		substr($num,0,1) = '';
		$sql .= "	LEFT JOIN hyosobun as $i ON ( center.id + $num ) = $i".".id\n";
	}
	$sql .= "WHERE center.id = temp_concl.id";

	mysql_exec->do($sql,1);
}

sub _count{
	my $self = shift;
	return mysql_exec->select("SELECT COUNT(*) FROM temp_conc_sort",1)
		->hundle->fetch->[0];
}

sub _sort{                                        # ソート用テーブルの作成
	my $self = shift;
	my %args = %{$self};
	my $sql = '';

	print "2: Sorting...\n";
	my ($group, $n);
	foreach my $i ('sort1','sort2','sort3'){
		mysql_exec->drop_table("temp_conc_$i");
		if ($args{$i} eq "id"){ last; }
		mysql_exec->do("
			create table temp_conc_$i (
				id int auto_increment primary key not null,
				hyoso_id int not null,
				count int not null,
				temp0 int,
				temp1 int
			)
		",1);

		my $sql = '';
		$sql .= "INSERT INTO temp_conc_$i ( ";
		for (my $count = 0; $count < $n; ++$count){
			$sql .= "temp$count, ";
		}
		$sql .= "hyoso_id, count )\n";
		$sql .= "SELECT $group $args{$i}, count(*) as count\n";
		$sql .= "FROM temp_conc\n";
		$sql .= "GROUP BY $group $args{$i}\n";
		$sql .= "ORDER BY count DESC";
		mysql_exec->do($sql,1);
		$group .= "$args{$i},";
		++$n;
	}

	# 最終ソート・テーブル
	mysql_exec->drop_table("temp_conc_sort");
	mysql_exec->do("
		create table temp_conc_sort (
			id int auto_increment primary key not null,
			conc_id int not null
		)
	",1);

	$sql = '';
	$sql .= "INSERT INTO temp_conc_sort ( conc_id )\n";
	$sql .= "SELECT temp_conc.id\n";
	$sql .= "FROM   temp_conc,";
	my @temp;
	foreach my $i ('sort1','sort2','sort3'){
		if ($args{$i} eq "id"){ last; }
		$sql .= "temp_conc_$i,";
	}
	chop $sql; $sql .= "\n";
	my @temp; my $n = 0;
	foreach my $i ('sort1','sort2','sort3'){
		if ($args{$i} eq "id"){ last; }
		if ($n == 0){
			$sql .= "WHERE\n";
			$sql .= "temp_conc.$args{$i} = temp_conc_$i.hyoso_id\n";
		} else {
			$sql .= "AND temp_conc.$args{$i} = temp_conc_$i.hyoso_id\n";
		}
		my $l = 0;
		foreach my $h (@temp){
			$sql .= "AND temp_conc.$h = temp_conc_$i.temp"."$l\n";
			++$l;
		}
		push @temp, $args{$i};
		++$n;
	}
	$sql .= "ORDER BY ";
	foreach my $i ('sort1','sort2','sort3'){
		if ($args{$i} eq "id"){ last; }
		$sql .= "temp_conc_"."$i".".id,";
	}
	$sql .= "temp_conc.id";
	mysql_exec->do($sql,1);
	#mysql_exec->("alter table temp_conc_sort add index index1 (conc_id)",1);
}

sub docs_per_once{
	return $docs_per_once;
}

sub _format{                                      # 結果の出力
	my $self = shift;
	my $start = shift;
	
	print "3: Formating output...\n";
	
	my $result;
	foreach my $i (@{$self->{left}},@{$self->{right}}){
		my $sql = "SELECT hyoso.name FROM temp_conc\n";
		$sql .= "	LEFT JOIN hyoso ON temp_conc.$i = hyoso.id,\n";
		$sql .= "	temp_conc_sort\n";
		$sql .= "WHERE temp_conc.id = temp_conc_sort.conc_id\n";
		$sql .= "	AND temp_conc_sort.id >= $start\n";
		$sql .= "	AND temp_conc_sort.id <  $start + $docs_per_once\n";
		$sql .= "ORDER BY temp_conc_sort.id\n";
		# $sql .= "LIMIT $self->{limit}";
		$result->{$i} = mysql_exec->select($sql,1)->hundle->fetchall_arrayref;
	}
	my $sql = "SELECT hyoso.name, temp_conc.id FROM ( hyoso,temp_conc,temp_conc_sort )\n";
	$sql .= "WHERE\n\t";
	$sql .= "temp_conc.center = hyoso.id\n";
	$sql .= "	AND temp_conc.id = temp_conc_sort.conc_id\n";
	$sql .= "	AND temp_conc_sort.id >= $start\n";
	$sql .= "	AND temp_conc_sort.id <  $start + $docs_per_once\n";
	$sql .= "ORDER BY temp_conc_sort.id\n";
	# $sql .= "LIMIT $self->{limit}";
	$result->{center} = mysql_exec->select($sql,1)->hundle->fetchall_arrayref;
	
	print "...\n";

	my $return;
	my $last = mysql_exec->select("
		SELECT COUNT(*)
		FROM temp_conc_sort
		WHERE
			    temp_conc_sort.id >= $start
			AND temp_conc_sort.id <  $start + $docs_per_once
	",1)->hundle->fetch->[0];
	--$last;
	
	for (my $n = 0; $n <= $last; ++$n){
		foreach my $i (@{$self->{left}}){
			$return->[$n][0] .= $result->{$i}[$n][0];
		}
		$return->[$n][1] = $result->{center}[$n][0];
		foreach my $i (@{$self->{right}}){
			$return->[$n][2] .= $result->{$i}[$n][0];
		}
		$return->[$n][3] = $result->{center}[$n][1];
	}

	return $return;
}

1;
