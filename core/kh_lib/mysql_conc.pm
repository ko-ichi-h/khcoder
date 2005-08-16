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
	#$args{length} = 5; # チェック用
	
	
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
		&& 0 # 必ず再検索・チェック用
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

	print "\n1: searching...\n";

	# Temp Table作成
	mysql_exec->drop_table("temp_conc");
	mysql_exec->do("
		#create temporary table temp_conc ( # チェック用
		create table temp_conc (
			id int primary key not null,
			l5 int,
			l4 int,
			l3 int,
			l2 int,
			l1 int,
			center int,
			r1 int,
			r2 int,
			r3 int,
			r4 int,
			r5 int
		)  TYPE = HEAP
	",1);

	# 検索して投入
	my $sql = '';
	$sql .= "INSERT INTO temp_conc\n";
	$sql .= "(id, l5,l4,l3,l2,l1,center,r1,r2,r3,r4,r5)\n";
	$sql .= "SELECT center.id, l5.hyoso_id,l4.hyoso_id,l3.hyoso_id,l2.hyoso_id,l1.hyoso_id,center.hyoso_id,r1.hyoso_id,r2.hyoso_id,r3.hyoso_id,r4.hyoso_id,r5.hyoso_id\n";
	$sql .= "FROM hyosobun as center\n";
	$sql .= "\tLEFT JOIN hyosobun as l1 ON ( center.id - 1 ) = l1.id\n";
	$sql .= "\tLEFT JOIN hyosobun as l2 ON ( center.id - 2 ) = l2.id\n";
	$sql .= "\tLEFT JOIN hyosobun as l3 ON ( center.id - 3 ) = l3.id\n";
	$sql .= "\tLEFT JOIN hyosobun as l4 ON ( center.id - 4 ) = l4.id\n";
	$sql .= "\tLEFT JOIN hyosobun as l5 ON ( center.id - 5 ) = l5.id\n";
	$sql .= "\tLEFT JOIN hyosobun as r1 ON ( center.id + 1 ) = r1.id\n";
	$sql .= "\tLEFT JOIN hyosobun as r2 ON ( center.id + 2 ) = r2.id\n";
	$sql .= "\tLEFT JOIN hyosobun as r3 ON ( center.id + 3 ) = r3.id\n";
	$sql .= "\tLEFT JOIN hyosobun as r4 ON ( center.id + 4 ) = r4.id\n";
	$sql .= "\tLEFT JOIN hyosobun as r5 ON ( center.id + 5 ) = r5.id\n";
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
}

sub hogehoge{
	my $self;
	# キャッシュ作成
	print "\n1: cashing...\n";
	mysql_exec->drop_table("temp_conc_cash");
	mysql_exec->do("
		create table temp_conc_cash (
			id int primary key not null,
			dan_id int,
			hyoso int
		) TYPE = HEAP
	",1);
	
	mysql_exec->drop_table("temp_conc_cash1");
	mysql_exec->do("
		create table temp_conc_cash1 (id int primary key not null) TYPE = HEAP
	",1);
	
	my $st = mysql_exec->select("SELECT id FROM temp_conc",1)->hundle;
	my @d = ();
	while (my $i = $st->fetch ){
		my $min = $i->[0] - $self->{length};
		my $max = $i->[0] + $self->{length};
		$min = 1 if $min < 1;
		foreach my $i (@d[$min...$max]){
			$i = 1;
		}
	}
	
	my $n = 0; my @temp;
	foreach my $i (@d){
		if ($i){
			push @temp, $n;
			if (@temp == 200){
				my $sql = "INSERT INTO temp_conc_cash1 (id) VALUES \n";
				foreach my $h (@temp){
					$sql .= "($h),";
				}
				chop $sql;
				mysql_exec->do($sql,1);
				
				@temp = ();
			}
		}
		++$n;
	}
	my $sql = "INSERT INTO temp_conc_cash1 (id) VALUES \n";
	foreach my $h (@temp){
		$sql .= "($h),";
	}
	chop $sql;
	mysql_exec->do($sql,1);
	
	mysql_exec->do("
		INSERT INTO temp_conc_cash (id,dan_id,hyoso)
		SELECT hyosobun.id, hyosobun.dan_id, hyosobun.hyoso_id
		FROM   hyosobun, temp_conc_cash1
		WHERE  hyosobun.id = temp_conc_cash1.id
	",1);
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
			#create temporary table temp_conc_$i (
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
		# create temporary table temp_conc_sort (
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
	
	# 出力リスト
	my $st1 = mysql_exec->select("
		SELECT temp_conc.id
		FROM   temp_conc,temp_conc_sort
		WHERE
			    temp_conc.id = temp_conc_sort.conc_id
			AND temp_conc_sort.id >= $start
			AND temp_conc_sort.id <  $start + $docs_per_once
	",1)->hundle;
	my $dlist = $st1->fetchall_arrayref;
	$st1->finish;
	
	print "L";
	
	my $sql = '';
	$sql .= "SELECT hyosobun.id, hyoso.name\n";
	$sql .= "FROM   hyosobun, hyoso\n";
	$sql .= "WHERE hyosobun.hyoso_id = hyoso.id \n AND (";
	my $n = 0;
	foreach my $i (@{$dlist}){
		$sql .= "OR " if $n;
		$sql .= "( ";
		$sql .= "hyosobun.hyoso_id >= $i->[0] - $self->{length}";
		$sql .= " AND ";
		$sql .= "hyosobun.hyoso_id <= $i->[0] + $self->{length}";
		$sql .= " )\n";
		$n = 1;
	}
	$sql .= " )";
	my $st2 = mysql_exec->select($sql,1)->hundle;
	
	
	return 0;
	
	
	my $return;
	my $n = 0;
	foreach my $i (@{$dlist}){
		$return->[$n][3] = $i->[0];
		
		my $st2 = mysql_exec->select("
			SELECT hyosobun.id, hyoso.name
			FROM   hyosobun, hyoso
			WHERE
				    hyosobun.hyoso_id = hyoso.id
				AND hyosobun.id >= $i->[0] - $self->{length}
				AND hyosobun.id <= $i->[0] + $self->{length}
			ORDER BY hyosobun.id
		",1)->hundle;
		my $hlist = $st2->fetchall_arrayref;
		#$st2->finish;
		
		my $cn = 0;
		foreach my $h (@{$hlist}){
			if ($h->[0] == $i->[0]){
				$return->[$n][1] .= $h->[1];
				$cn = 2;
				next;
			}
			$return->[$n][$cn] .= $h->[1];
		}
		print ".";
		++$n;
	}
	print "\n";
	
	return $return;
}

1;
