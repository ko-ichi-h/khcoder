package mysql_conc;
use strict;
use mysql_exec;
use mysql_a_word;

my ( $l_query, $l_hinshi, $l_katuyo, $l_length);
my $docs_per_once = 200;

#----------------------------#
#   初期化・コンストラクト   #
#----------------------------#

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

#----------#
#   検索   #
#----------#

sub _find{
	my $self = shift;
	my %args = %{$self};
	my @hyoso = @{$_[0]};

	print "\n1: Searching...\n";

	# Temp Table作成
	mysql_exec->drop_table("temp_conc");
	mysql_exec->do("
		create temporary table temp_conc (
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

#------------#
#   ソート   #
#------------#

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
			create temporary table temp_conc_$i (
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
		create temporary table temp_conc_sort (
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
}

#--------------------------------#
#   コンコーダンス・ライン作成   #
#--------------------------------#

sub _format{                                      # 結果の出力
	my $self = shift;
	my $start = shift;
	
	print "3: Formating...\n";
	
	# 出力リスト作成（中央のID）;
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
	
	# データをMySQLから取り出す
	my $sql = '';
	$sql .= "SELECT hyosobun.id, hyoso.name, hyosobun.dan_id\n";
	$sql .= "FROM   hyosobun, hyoso\n";
	$sql .= "WHERE hyosobun.hyoso_id = hyoso.id \n AND (";
	my $n = 0;
	foreach my $i (@{$dlist}){
		$sql .= "OR " if $n;
		$sql .= "( ";
		$sql .= "hyosobun.id >= $i->[0] - $self->{length}";
		$sql .= " AND ";
		$sql .= "hyosobun.id <= $i->[0] + $self->{length}";
		$sql .= " )\n";
		$n = 1;
	}
	$sql .= " )\n ORDER BY hyosobun.id";
	my $st2 = mysql_exec->select($sql,1)->hundle;
	my $res;
	while (my $i = $st2->fetch){
		$res->{$i->[0]}[0] = $i->[1];
		$res->{$i->[0]}[1] = $i->[2];
	}
	
	# フォーマット
	my $return;
	my $n = 0;
	foreach my $i (@{$dlist}){
		# 中央
		$return->[$n][3] = $i->[0];
		$return->[$n][1] = $res->{$i->[0]}[0];
		
		# 左側
		my $l_dan = 0;
		for (my $m = $i->[0] - $self->{length}; $m < $i->[0]; ++$m){
			if ( 
				   ( $l_dan != $res->{$m}[1] )
				&& ( $l_dan > 0 )
				&& ( $res->{$m}[1] > 1 )
			){
				$return->[$n][0] .= $::config_obj->kaigyo_kigou;
			}
			$l_dan = $res->{$m}[1];
			$return->[$n][0] .= $res->{$m}[0];
		}
		if (
			   ( $l_dan != $res->{$i->[0]}[1] )
			&& ( $l_dan > 0 )
			&& ( $res->{$i->[0]}[1] > 1 )
		) {
			$return->[$n][0] .= $::config_obj->kaigyo_kigou;
		}
		$l_dan = $res->{$i->[0]}[1];
		
		# 右側
		for (my $m = $i->[0] + 1; $m <= $i->[0] + $self->{length}; ++$m){
			if ( 
				   ( $l_dan != $res->{$m}[1] )
				&& ( $l_dan > 0 )
				&& ( $res->{$m}[1] > 1 )
			){
				$return->[$n][2] .= $::config_obj->kaigyo_kigou;
			}
			$l_dan = $res->{$m}[1];
			$return->[$n][2] .= $res->{$m}[0];
		}
		++$n;
	}
	
	return $return;
}

#------------------------#
#   コロケーション集計   #
#------------------------#

sub coloc{
	my $self = shift;
	my @cols = ('l5','l4','l3','l2','l1','r1','r2','r3','r4','r5',);
	
	# 列ごとにカウント
	my %words_count;
	my %num2words;
	my $res_atom;
	foreach my $i (@cols){
		my $st = mysql_exec->select("
			SELECT genkei.id, count($i), genkei.name
			FROM temp_conc, hyoso, genkei, hselection
			WHERE
				temp_conc.$i = hyoso.id
				AND hyoso.genkei_id = genkei.id
				AND genkei.khhinshi_id = hselection.khhinshi_id
				AND hselection.ifuse = 1
				AND genkei.nouse = 0
			GROUP by $i
		",1)->hundle;
		while ( my $h = $st->fetch ){
			$res_atom->{$i}{$h->[0]} = $h->[1];
			$words_count{$h->[0]} += $h->[1];
			$num2words{$h->[0]} = $h->[2];
		}
	}
	
	# 整形
	foreach my $i (
		sort {$words_count{$b} <=> $words_count{$a}}
		keys %words_count
	){
		print Jcode->new("$num2words{$i}\t$words_count{$i}\t")->sjis;
		foreach my $h (@cols){
			print "$res_atom->{$h}{$i}\t";
		}
		print "\n";
	}
	
	
	
}


#------------#
#   その他   #
#------------#

sub _count{
	my $self = shift;
	return mysql_exec->select("SELECT COUNT(*) FROM temp_conc_sort",1)
		->hundle->fetch->[0];
}

sub docs_per_once{
	return $docs_per_once;
}

1;
