package mysql_conc;

use strict;
use utf8;

use mysql_exec;
use mysql_a_word;

my ( $l_query, $l_hinshi, $l_katuyo, $l_length, $l_tuika);
my $docs_per_once = 200;
my $temporary = 'temporary';

if ($::config_obj->web_if){
	$docs_per_once = 50;
	$temporary = 'temporary';
}

#----------------------------#
#   初期化・コンストラクト   #
#----------------------------#

sub initialize{
	($l_query, $l_hinshi, $l_katuyo, $l_length, $l_tuika) = ('','','','');
}

sub a_word{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	bless $self, $class;

	unless ($args{length}){
		$args{length} = 20;
	}

	$args{tuika}->{1}{pos}    = '' unless defined( $args{tuika}->{1}{pos}    );
	$args{tuika}->{1}{query}  = '' unless defined( $args{tuika}->{1}{query}  );
	$args{tuika}->{1}{hinshi} = '' unless defined( $args{tuika}->{1}{hinshi} );
	$args{tuika}->{1}{katuyo} = '' unless defined( $args{tuika}->{1}{katuyo} );
	$args{tuika}->{2}{pos}    = '' unless defined( $args{tuika}->{2}{pos}    );
	$args{tuika}->{2}{query}  = '' unless defined( $args{tuika}->{2}{query}  );
	$args{tuika}->{2}{hinshi} = '' unless defined( $args{tuika}->{2}{hinshi} );
	$args{tuika}->{2}{katuyo} = '' unless defined( $args{tuika}->{2}{katuyo} );
	$args{tuika}->{3}{pos}    = '' unless defined( $args{tuika}->{3}{pos}    );
	$args{tuika}->{3}{query}  = '' unless defined( $args{tuika}->{3}{query}  );
	$args{tuika}->{3}{hinshi} = '' unless defined( $args{tuika}->{3}{hinshi} );
	$args{tuika}->{3}{katuyo} = '' unless defined( $args{tuika}->{3}{katuyo} );

	my $tuika_chk = 
		 "$args{tuika}->{1}{pos},"
		."$args{tuika}->{1}{query},"
		."$args{tuika}->{1}{hinshi},"
		."$args{tuika}->{1}{katuyo},"
		."$args{tuika}->{2}{pos},"
		."$args{tuika}->{2}{query},"
		."$args{tuika}->{2}{hinshi},"
		."$args{tuika}->{2}{katuyo},"
		."$args{tuika}->{3}{pos},"
		."$args{tuika}->{3}{query},"
		."$args{tuika}->{3}{hinshi},"
		."$args{tuika}->{3}{katuyo}"
	;
	
	my $abort = 0;

	unless (
		   ( $l_query eq $args{query} )
		&& ( $l_hinshi eq $args{hinshi} )
		&& ( $l_katuyo eq $args{katuyo} )
		&& ( length($args{query}.$args{hinshi}.$args{katuyo}) )
		&& ( $l_tuika eq $tuika_chk )
		&& ( $::config_obj->web_if == 0 )
	){
		if (
			not (
				   ( $l_query eq $args{query} )
				&& ( $l_hinshi eq $args{hinshi} )
				&& ( $l_katuyo eq $args{katuyo} )
				&& ( length($args{query}.$args{hinshi}.$args{katuyo}) )
				&& ( $::config_obj->web_if == 0 )
			)
			or (length($l_tuika) > 11)
		){
			#print "1st search\n";
			$self->_hyoso_ext or $abort = 1;
			$self->_find;
			$l_query = $args{query};
			$l_hinshi = $args{hinshi};
			$l_katuyo = $args{katuyo};
		}
		if (length($tuika_chk) > 11 && $abort == 0){
			#print "2nd search\n";
			$self->_tuika or $abort = 1;
		}
		$l_tuika = $tuika_chk;
	}
	if ($abort == 0){
		#print "3. sort\n\n";
		$self->_sort;
		return $self;
	} else {
		($l_query, $l_hinshi, $l_katuyo, $l_length, $l_tuika) = ('','','','');
		return 0;
	}
}

sub last_words{
	my @r;
	my $h = mysql_exec->select("
		SELECT id
		FROM   temp_conc_hyoso
	")->hundle;
	while (my $i = $h->fetch){
		push @r, $i->[0];
	}
	return \@r;
}

#sub last_words{
#	my $self;
#	my $class = shift;
#	my %args;
#	
#	$args{query} = $l_query;
#	$args{hinshi} = $l_hinshi;
#	$args{katuyo} = $l_katuyo;
#	$self = \%args;
#	bless $self, $class;
#	return ($self->_hyoso);
#}

#sub _hyoso{
#	my $self = shift;
#	
#	return mysql_a_word->new(
#		genkei   => $self->{query},
#		katuyo   => $self->{katuyo},
#		khhinshi => $self->{hinshi}
#	)->hyoso_id_s;
#}

sub _hyoso_ext{
	my $self = shift;
	my $r;
	
	mysql_exec->drop_table("temp_conc_hyoso");
	mysql_exec->do("
		create $temporary table temp_conc_hyoso(
			id int primary key not null
		)  TYPE = HEAP
	",1);
	
	# 語が指定されている場合
	if (length($self->{query})){
		$r = mysql_a_word->new(
			genkei   => $self->{query},
			katuyo   => $self->{katuyo},
			khhinshi => $self->{hinshi}
		)->hyoso_id_s;
		if ($r){
			my $sql = "INSERT INTO temp_conc_hyoso (id)\n";
			$sql .= "VALUES\n";
			my $n = 0;
				foreach my $i (@{$r}){
					$sql .= "," if $n;
					$sql .= "($i)";
					++$n;
				}
			mysql_exec->do($sql,1);
		} else {
			return 0;
		}
	}
	# 品詞・活用形での指定
	elsif ( ( length($self->{katuyo}) ) || ( length($self->{hinshi}) ) ){
		my $sql = '';
		$sql .= "INSERT INTO temp_conc_hyoso (id)\n";
		$sql .= "SELECT hyoso.id\n";
		$sql .= "FROM   hyoso, genkei, khhinshi, katuyo\n";
		$sql .= "WHERE\n";
		$sql .= "	hyoso.genkei_id = genkei.id\n";
		$sql .= "	AND genkei.khhinshi_id = khhinshi.id\n";
		$sql .= "	AND hyoso.katuyo_id = katuyo.id\n";
		if ( length($self->{katuyo}) ){
			$sql .= "	AND katuyo.name = \'$self->{katuyo}\'\n";
		}
		if ( length($self->{hinshi}) ){
			$sql .= "	AND khhinshi.name = \'$self->{hinshi}\'\n";
		}
		mysql_exec->do($sql,1);
	} else {
		return 0;
	}
	
	return mysql_exec->select("
		SELECT id
		FROM   temp_conc_hyoso
	",1)->hundle->rows;
}

#----------#
#   検索   #
#----------#

sub _find{
	my $self = shift;
	my %args = %{$self};
	#my @hyoso = @{$_[0]};

	# print "\n1: Searching(1)...\n";

	# Temp Table作成
	mysql_exec->drop_table("temp_conc");
	mysql_exec->do("
		create $temporary table temp_conc (
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
	$sql .= "FROM temp_conc_hyoso, hyosobun as center\n";
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
	$sql .= "center.hyoso_id = temp_conc_hyoso.id";
	
	#my $n = 0;
	#foreach my $i (@hyoso){
	#	if ($n){
	#		$sql .= 'OR ';
	#	}
	#	$sql .= "center.hyoso_id = $i\n";
	#	++$n;
	#}
	mysql_exec->do($sql,1);
}

#----------------------------#
#   追加条件による絞り込み   #
#----------------------------#

sub _tuika{
	my $self = shift;
	# print "\n1: Searching(2)...\n";
	
	# 絞り込みの準備
	foreach my $i (1,2,3){
		next unless $self->{tuika}{$i}{pos};
		# テーブルの準備
		mysql_exec->drop_table("temp_conc_hyoso_opt$i");
		mysql_exec->do("
			create $temporary table temp_conc_hyoso_opt$i(
				id int primary key not null
			)  TYPE = HEAP
		",1);
		# 語が指定されている場合
		if ( length($self->{tuika}{$i}{query}) ){
			my $r = mysql_a_word->new(
				genkei   => $self->{tuika}{$i}{query},
				katuyo   => $self->{tuika}{$i}{katuyo},
				khhinshi => $self->{tuika}{$i}{hinshi}
			)->hyoso_id_s;
			if ($r){
				my $sql = "INSERT INTO temp_conc_hyoso_opt$i (id)\n";
				$sql .= "VALUES\n";
				my $n = 0;
				foreach my $i (@{$r}){
					$sql .= "," if $n;
					$sql .= "($i)";
					++$n;
				}
				mysql_exec->do($sql,1);
			}
		}
		# 品詞・活用形による指定
		elsif (
			   (length($self->{tuika}{$i}{katuyo}))
			|| (length($self->{tuika}{$i}{hinshi}))
		){
			my $sql = '';
			$sql .= "INSERT INTO temp_conc_hyoso_opt$i (id)\n";
			$sql .= "SELECT hyoso.id\n";
			$sql .= "FROM   hyoso, genkei, khhinshi, katuyo\n";
			$sql .= "WHERE\n";
			$sql .= "	hyoso.genkei_id = genkei.id\n";
			$sql .= "	AND genkei.khhinshi_id = khhinshi.id\n";
			$sql .= "	AND hyoso.katuyo_id = katuyo.id\n";
			if ( length($self->{tuika}{$i}{katuyo}) ){
				$sql .= "\tAND katuyo.name = \'$self->{tuika}{$i}{katuyo}\'\n";
			}
			if ( length($self->{tuika}{$i}{hinshi}) ){
				$sql .= "\tAND khhinshi.name = \'$self->{tuika}{$i}{hinshi}\'\n";
			}
			mysql_exec->do($sql,1);
		} else {
			return 0;
		}
	}
	
	# Temp Table作成
	mysql_exec->drop_table("temp_conc_old");
	mysql_exec->do("ALTER TABLE temp_conc RENAME temp_conc_old",1);
	mysql_exec->do("
		create $temporary table temp_conc (
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
		) TYPE = HEAP
	",1);
	
	my $cols = {
		'rl' => ['l5','l4','l3','l2','l1','r1','r2','r3','r4','r5'],
		'l'  => ['l5','l4','l3','l2','l1'],
		'r'  => ['r1','r2','r3','r4','r5'],
		'l5' => ['l5'],
		'l4' => ['l4'],
		'l3' => ['l3'],
		'l2' => ['l2'],
		'l1' => ['l1'],
		'r1' => ['r1'],
		'r2' => ['r2'],
		'r3' => ['r3'],
		'r4' => ['r4'],
		'r5' => ['r5'],
	};
	
	my $sql = '';
	$sql .= "INSERT INTO temp_conc (id,l5,l4,l3,l2,l1,center,r1,r2,r3,r4,r5)\n";
	$sql .= "SELECT DISTINCT temp_conc_old.id,l5,l4,l3,l2,l1,center,r1,r2,r3,r4,r5\n";
	$sql .= "FROM temp_conc_old";
	foreach my $i (1,2,3){
		if ($self->{tuika}{$i}{pos}){
			$sql .= ",temp_conc_hyoso_opt$i";
		}
	}
	$sql .= "\n";
	$sql .= "WHERE\n";
	foreach my $i (1,2,3){
		next unless $self->{tuika}{$i}{pos};
		$sql .= "\tAND "if $i > 1;
		$sql .= "\t(\n";
		my $n = 0;
		foreach my $p (@{$cols->{$self->{tuika}{$i}{pos}}}){
			if ($n){
				$sql .= "\t\tOR $p = temp_conc_hyoso_opt$i.id\n";
			} else {
				$sql .= "\t\t   $p = temp_conc_hyoso_opt$i.id\n";
			}
			++$n;
		}
		$sql .= "\t)\n";
	}
	#print "$sql\n";
	mysql_exec->do($sql,1);
	mysql_exec->drop_table("temp_conc_old");
	
	return 0 unless mysql_exec->select("SELECT COUNT(*) FROM temp_conc",1)
		->hundle->fetch->[0];
	return 1;
}

#------------#
#   ソート   #
#------------#

sub _sort{
	my $self = shift;
	my %args = %{$self};
	my $sql = '';
	my $new = 1;
	
	use Benchmark;
	my $t0 = new Benchmark;
	
	my @cols = ();
	my %chk_dup = ();
	foreach my $i ('sort1','sort2','sort3'){
		last if $args{$i} eq "id";
		next if $chk_dup{$args{$i}};
		push @cols, $args{$i};
		$chk_dup{$args{$i}} = 1;
	}
	
	if (@cols){                                   # ソートを行う場合
		# 基本形のテーブルを作成
		mysql_exec->drop_table("temp_conc_fs");
		my $sql = '';
		my $sql_temp0 = '';
		$sql .= "create $temporary table temp_conc_fs (\n";
		$sql .= "	id int primary key not null,\n";
		foreach my $i (@cols){
			$sql .= "	$i int,\n";
			$sql_temp0 .= "$i,";
		}
		chop $sql;
		chop $sql;
		chop $sql_temp0;
		$sql .= "\n) TYPE = HEAP";
		mysql_exec->do($sql,1);
		
		# 基本形を投入
		my $join_count = 0;
		$sql = '';
		$sql .= "INSERT INTO temp_conc_fs (id, $sql_temp0 )\n";
		$sql .= "SELECT temp_conc.id";
		my $sql_temp1 = '';
		foreach my $i (@cols){
			last if $i eq 'id';
			$sql .= ", ";
			if ($i eq 'center'){
				$sql .= 'center';
			} else {
				$sql .= "h$join_count.genkei_id";
				$sql_temp1 .= "\n\tLEFT JOIN hyoso as h$join_count ON temp_conc.$i = h$join_count.id";
				++$join_count;
			}
		}
		$sql .= "\n";
		$sql .= "FROM temp_conc $sql_temp1";
		mysql_exec->do($sql,1);
		
		#$sql = '';
		#$sql .= "ALTER TABLE temp_conc_fs ADD INDEX index1 (";
		#foreach my $i (@cols){
		#	$sql .= "$i,";
		#}
		#chop $sql;
		#$sql .= ")";
		#mysql_exec->do($sql,1);
		
		# 予備的なソート
		my ($group, $n);
		foreach my $i ('sort1','sort2','sort3'){
			mysql_exec->drop_table("temp_conc_$i");
			last if $args{$i} eq "id";
			
			my $sql = '';                                       # テーブル作成
			$sql .= "create $temporary table temp_conc_$i (\n";
			#$sql .= "create table temp_conc_$i (\n";
			$sql .= "	id int auto_increment primary key not null,\n";
			$sql .= "	hyoso_id int not null,\n";
			$sql .= "	count int not null";
			if ($n){
				my $l = $n - 1;
				while ($l >= 0){
					$sql .= ",\n";
					$sql .= "	temp$l int";
					--$l;
				}
			}
			$sql .= "\n)";
			mysql_exec->do($sql,1);
			
			$sql = '';                                          # 挿入
			$sql .= "INSERT INTO temp_conc_$i ( ";
			for (my $count = 0; $count < $n; ++$count){
				$sql .= "temp$count, ";
			}
			$sql .= "hyoso_id, count )\n";
			$sql .= "SELECT $group $args{$i}, count(*) as count\n";
			$sql .= "FROM temp_conc_fs\n";
			$sql .= "GROUP BY $group $args{$i}\n";
			$sql .= "ORDER BY count DESC, $args{$i}";
			mysql_exec->do($sql,1);
			
			$sql = '';                                          # インデックス
			$sql .= "ALTER TABLE temp_conc_$i ADD INDEX index1 (hyoso_id,";
			if ($n){
				my $l = $n - 1;
				while ($l >= 0){
					$sql .= "temp$l,";
					--$l;
				}
			}
			$sql .= "count)";
			#print "$sql\n";
			mysql_exec->do($sql,0);
			
			$group .= "$args{$i},";
			++$n;
		}
		
		# 最終ソート
		mysql_exec->drop_table("temp_conc_sort");
		mysql_exec->do("
			create $temporary table temp_conc_sort (
			#create table temp_conc_sort (
				id int auto_increment primary key not null,
				conc_id int not null
			)
		",1);

		$sql = '';
		$sql .= "INSERT INTO temp_conc_sort ( conc_id )\n";
		$sql .= "SELECT temp_conc_fs.id\n";
		$sql .= "FROM   temp_conc_fs\n";
		my @temp;
		foreach my $i ('sort1','sort2','sort3'){
			last if $args{$i} eq "id";
			
			$sql .= "	LEFT JOIN temp_conc_$i ON\n";
			$sql .= "		temp_conc_fs.$args{$i} = temp_conc_$i.hyoso_id\n";
			
			my $n = 0;
			foreach my $h (@temp){
				$sql .= "		AND temp_conc_fs.$h = temp_conc_$i.temp$n\n";
				++$n;
			}
			push @temp, $args{$i};
			
			$sql .= "		AND temp_conc_$i.count > 1\n";
		}
		$sql .= "ORDER BY\n";
		foreach my $i ('sort1','sort2','sort3'){
			last if $args{$i} eq "id";
			$sql .= "	IFNULL(temp_conc_$i.id, 4294967295),\n";
		}
		$sql .= "	temp_conc_fs.id";
		#print "$sql\n";
		mysql_exec->do($sql,1);

	} else {
		# 最終ソート・テーブル
		mysql_exec->drop_table("temp_conc_sort");
		mysql_exec->do("
			create $temporary table temp_conc_sort (
			#create table temp_conc_sort (
				id int auto_increment primary key not null,
				conc_id int not null
			)
		",1);

		$sql = '';
		$sql .= "INSERT INTO temp_conc_sort ( conc_id )\n";
		$sql .= "SELECT temp_conc.id\n";
		$sql .= "FROM   temp_conc\n";
		my @temp;
		foreach my $i ('sort1','sort2','sort3'){
			last if $args{$i} eq "id";
			
			$sql .= "	LEFT JOIN temp_conc_$i ON\n";
			$sql .= "		temp_conc.$args{$i} = temp_conc_$i.hyoso_id\n";
			
			my $n = 0;
			foreach my $h (@temp){
				$sql .= "		AND temp_conc.$h = temp_conc_$i.temp$n\n";
				++$n;
			}
			push @temp, $args{$i};
			
			$sql .= "		AND temp_conc_$i.count > 1\n";
		}
		$sql .= "ORDER BY\n";
		foreach my $i ('sort1','sort2','sort3'){
			last if $args{$i} eq "id";
			$sql .= "	IFNULL(temp_conc_$i.id, 4294967295),\n";
		}
		$sql .= "	temp_conc.id";
		#print "$sql\n";
		mysql_exec->do($sql,1);
	}

	my $t1 = new Benchmark;
	#print "Sort: ",timestr(timediff($t1,$t0)),"\n";
}

#--------------------------------#
#   コンコーダンス・ライン作成   #
#--------------------------------#

sub _format{                                      # 結果の出力
	my $self = shift;
	my $start = shift;
	
	my $cell_symbol = $::config_obj->cell_symbol;
	
	#print "3: Formating...\n";
	my $spacer = $::project_obj->spacer;
	
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
	
	#print "mysql_conc::_format, dlist: @{$dlist}\n";
	
	# データをMySQLから取り出す
	my $sql = '';
	$sql .= "SELECT hyosobun.id, hyoso.name, hyosobun.dan_id\n";
	$sql .= "FROM   hyosobun, hyoso\n";
	$sql .= "WHERE hyosobun.hyoso_id = hyoso.id \n AND (";
	my $n = 0;
	foreach my $i (sort {$a->[0] <=> $b->[0]} @{$dlist}){
		#print "mysql_conc::_format, \$i->[0]: $i->[0]\n";
		$sql .= "OR " if $n;
		$sql .= "( ";
		$sql .= "hyosobun.id >= $i->[0] - $self->{length}";
		$sql .= " AND ";
		$sql .= "hyosobun.id <= $i->[0] + $self->{length}";
		$sql .= " )\n";
		$n = 1;
	}
	$sql .= " )\n";
	my $st2 = mysql_exec->select($sql,1)->hundle;
	my $res;
	while (my $i = $st2->fetch){
		$res->{$i->[0]}[0] = $i->[1];
		$res->{$i->[0]}[1] = $i->[2];
	}
	
	# フォーマット
	my $fix_cell = $::project_obj->status_from_table;
	my $return;
	$n = 0;
	foreach my $i (@{$dlist}){
		# 中央
		$return->[$n][3] = $i->[0];
		$return->[$n][1] = $res->{$i->[0]}[0];
		
		# 左側
		my $l_dan = 0;
		for (my $m = $i->[0] - $self->{length}; $m < $i->[0]; ++$m){
			next unless defined($res->{$m}[0]);
			if ( 
				   ( $l_dan != $res->{$m}[1] )
				&& ( $l_dan > 0 )
				&& ( $res->{$m}[1] > 1 )
			){
				$return->[$n][0] .= $::config_obj->newline_symbol;
			}
			$l_dan = $res->{$m}[1];
			$return->[$n][0] .= $spacer if length($return->[$n][0]);
			$return->[$n][0] .= $res->{$m}[0];
		}
		if (
			   ( $l_dan != $res->{$i->[0]}[1] )
			&& ( $l_dan > 0 )
			&& ( $res->{$i->[0]}[1] > 1 )
		) {
			$return->[$n][0] .= $::config_obj->newline_symbol;
		}
		if ($fix_cell) {
			$return->[$n][0] =~ s/<h5>$spacer---cell---$spacer<\/h5>/$cell_symbol/g;
		}
		
		$l_dan = $res->{$i->[0]}[1];
		
		# 右側
		for (my $m = $i->[0] + 1; $m <= $i->[0] + $self->{length}; ++$m){
			next unless defined($res->{$m}[0]);
			if ( 
				   ( $l_dan != $res->{$m}[1] )
				&& ( $l_dan > 0 )
				&& ( $res->{$m}[1] > 1 )
			){
				$return->[$n][2] .= $::config_obj->newline_symbol;
			}
			$l_dan = $res->{$m}[1];
			$return->[$n][2] .= $spacer if length($return->[$n][2]);
			$return->[$n][2] .= $res->{$m}[0];
		}
		if ($fix_cell) {
			$return->[$n][2] =~ s/<h5>$spacer---cell---$spacer<\/h5>/$cell_symbol/g;
		}
		++$n;
	}
	
	# Korean patchim check
	if ($::project_obj->morpho_analyzer_lang eq 'kr' ) {
		foreach my $i (@{$return}){
			$i->[0] = gui_window->kchar_patchim($i->[0]);
			$i->[2] = gui_window->kchar_patchim($i->[2]);
		}
	}

	return $return;
}

sub save_all{
	my $self = shift;
	my %args = @_;
	
	# 文字列データ整理
	my @result;
	my $start = 1;
	my $max   = $self->_count;
	while ($start <= $max){
		my $res = $self->_format($start);
		@result = (@result, @{$res});
		$start += 200;
	}
	
	# ID情報の整理
	my $st1 = mysql_exec->select("
		SELECT hyosobun.h1_id, hyosobun.h2_id, hyosobun.h3_id, hyosobun.h4_id, hyosobun.h5_id, hyosobun.dan_id, hyosobun.bun_id, bun.seq, temp_conc.id
		FROM   temp_conc, temp_conc_sort, hyosobun, bun
		WHERE
			    temp_conc.id = hyosobun.id
			AND temp_conc.id = temp_conc_sort.conc_id
			AND hyosobun.bun_idt = bun.id
		ORDER BY temp_conc_sort.id
	",1)->hundle;
	my $id = $st1->fetchall_arrayref;

	# 出力
	use File::BOM;
	open (KWICO, '>:encoding(utf8):via(File::BOM)', $args{path}) or 
		gui_errormsg->open(
			type => 'file',
			thefile => $args{path}
		);

	print KWICO "h1,h2,h3,h4,h5,dan,bun,bun-No.,mp-No.,L,C,R\n";
	for (my $n = 0; $n < $max; ++$n){
		my $line = "$id->[$n][0],$id->[$n][1],$id->[$n][2],$id->[$n][3],$id->[$n][4],$id->[$n][5],$id->[$n][6],$id->[$n][7],$id->[$n][8],";
		$line .= kh_csv->value_conv($result[$n]->[0]).",";
		$line .= kh_csv->value_conv($result[$n]->[1]).",";
		$line .= kh_csv->value_conv($result[$n]->[2])."\n";
		print KWICO $line;
	}
	close (KWICO);
	#kh_jchar->to_sjis($args{path}) if $::config_obj->os eq 'win32';
	
	return 1;
}


#------------------------#
#   コロケーション集計   #
#------------------------#

sub coloc{
	my $self = shift;
	my @cols = ('l5','l4','l3','l2','l1','r1','r2','r3','r4','r5');
	
	# 列ごとにカウント
	my %words;
	my $res_atom;
	foreach my $i (@cols){
		my $st = mysql_exec->select("
			SELECT genkei.id, count(*)
			FROM temp_conc, hyoso, genkei, hselection
			WHERE
				temp_conc.$i = hyoso.id
				AND hyoso.genkei_id = genkei.id
				AND genkei.khhinshi_id = hselection.khhinshi_id
				AND hselection.ifuse = 1
				AND genkei.nouse = 0
			GROUP by genkei.id
		",1)->hundle;
		while ( my $h = $st->fetch ){
			$words{$h->[0]} = 1;
			$res_atom->{$i}{$h->[0]} = $h->[1];
		}
	}
	
	# 仮テーブル作成
	mysql_exec->drop_table("temp_conc_coloc");
	my $sql = '';
	$sql .= "create $temporary table temp_conc_coloc(\n";
	$sql .= "\tgenkei_id int primary key not null,\n";
	foreach my $i (@cols){
		$sql .= "\t$i int not null,\n";
	}
	chop $sql; chop $sql;
	$sql .= ") TYPE = HEAP";
	mysql_exec->do($sql);
	
	# 整形して仮テーブルに投入
	my $value; my $n;
	foreach my $i (keys %words){
		$value .= "($i,";
		foreach my $h (@cols){
			$res_atom->{$h}{$i} = 0 unless $res_atom->{$h}{$i};
			$value .= "$res_atom->{$h}{$i},";
		}
		chop $value;
		$value .= "),";
		++$n;
		if ($n == 300){
			&coloc_insert($value);
			$value = '';
			$n = 0;
		}
	}
	&coloc_insert($value);
	
	# テーブル投入用ルーチン
	sub coloc_insert{
		my @cols = ('l5','l4','l3','l2','l1','r1','r2','r3','r4','r5');
		my $value = shift;
		chop $value;
		
		my $sql = "INSERT INTO temp_conc_coloc (genkei_id,";
		foreach my $i (@cols){
			$sql .= "$i,";
		}
		chop $sql;
		$sql .= ")\nVALUES $value";
		mysql_exec->do($sql);
		return 1;
	}
}

sub format_coloc{
	my $self = shift;
	my %args = @_;
	
	# 総語数
	my $total = mysql_words->num_all;

	# Node wordの出現数
	my $w1_freq = $self->_count;
	
	# 共起数の表現
	my $joint;
	my $j_f;
	my $span = 0;
	foreach my $i ('l5','l4','l3','l2','l1','r1','r2','r3','r4','r5'){
		if ($i eq $args{span1}){
			$j_f = 1;
		}
		if ($j_f){
			$joint .= '+' if length($joint);
			$joint .= "$i";
			++$span;
		}
		if ($i eq $args{span2}){
			last;
		}
	}
	#print "joint exp: $joint\n";
	
	my $sql = '';
	$sql .= "SELECT genkei.name, hselection.name,";
	$sql .= "l5+l4+l3+l2+l1+r1+r2+r3+r4+r5 as sum,";
	$sql .= "l5+l4+l3+l2+l1 as suml,";
	$sql .= "r1+r2+r3+r4+r5 as sumr,";
	$sql .= "l5,l4,l3,l2,l1,r1,r2,r3,r4,r5,\n";
	
	if ( $args{sort} eq 'MI' ){
		$sql .= "truncate( log( ($joint) * $total / ($w1_freq * genkei.num) ) / log(2) + .0005, 3) as MI\n";
	}
	elsif ( $args{sort} eq 'MI3' ){
		$sql .= "truncate( log( power($joint,3) * $total / ($w1_freq * genkei.num) ) / log(2) + .0005, 3) as MI3\n",
	}
	elsif ( $args{sort} eq 'T' ){
		$sql .= "truncate( ( $joint - $w1_freq * genkei.num / $total ) / sqrt( $joint ) + .0005, 3 ) as T\n";
	}
	elsif ( $args{sort} eq 'Z' ){
		$sql .= "truncate( ($joint - (genkei.num / ($total - $w1_freq) * $w1_freq * $span)) / sqrt( genkei.num / ($total - $w1_freq) * $w1_freq * $span * (1-(genkei.num / ($total - $w1_freq))) ) + .0005, 3 ) as Z\n";
	}
	elsif ( $args{sort} eq 'Dice' ){
		$sql .= "truncate( ($joint) * 2 / ($w1_freq + genkei.num) + .0005, 3 ) as Dice\n";
	}
	elsif ( $args{sort} eq 'Jaccard' ){
		$sql .= "truncate( ($joint) / ($w1_freq + genkei.num - ($joint) ) + .0005, 3 ) as Jaccard\n";
	}
	elsif ( $args{sort} eq 'LL' ){
		$sql .= "truncate( 2 * (
			  ($joint) * Log($joint)

			+ (genkei.num - ($joint)) * IFNULL(Log(genkei.num - ($joint)), 0)

			+ ($w1_freq - ($joint) )  * IFNULL(Log($w1_freq - ($joint)), 0)

			+ ($total - genkei.num - $w1_freq + $joint)
			                          * IFNULL(Log($total - genkei.num - $w1_freq + $joint), 0)

			- (genkei.num)
			    * Log(genkei.num)

			- ($w1_freq)
			    * Log($w1_freq)

			- ($total - $w1_freq)
			    * IFNULL( Log($total - $w1_freq), 0 )

			- ($total - genkei.num)
			    * IFNULL( Log($total - genkei.num), 0 )

			+ ($total)
			    * Log($total)
		) + .0005, 3 ) as LL\n";
	}
	else {
		$sql .= "truncate( (l5+r5) / 5 + (l4+r4) / 4 + (l3+r3) / 3 + (l2+r2) / 2 + l1 + r1 + .0005, 3 ) as score\n";
	}
	

	$sql .= "FROM temp_conc_coloc,genkei,hselection\n";
	$sql .= "WHERE\n";
	$sql .= "\ttemp_conc_coloc.genkei_id = genkei.id\n";
	$sql .= "\tAND genkei.khhinshi_id = hselection.khhinshi_id\n";
	$sql .= "\tAND l5+l4+l3+l2+l1+r1+r2+r3+r4+r5 >= $args{filter}->{filter}\n";
	$sql .= "\tAND (\n";
	my $n = 0;
	foreach my $i (keys %{$args{filter}->{hinshi}}){
		$sql .= "\t\t";
		$sql .= "OR " if $n;
		if ($args{filter}->{hinshi}{$i}){
			$sql .= "hselection.khhinshi_id = $i\n";
		} else {
			$sql .= "0\n";
		}
		$n = 1;
	}
	
	
	$sql .= "\t)\n";
	$sql .= "ORDER BY $args{sort} DESC, ".$::project_obj->mysql_sort('genkei.name')."\n";
	$sql .= "LIMIT $args{filter}->{limit}";
	
	return mysql_exec->select($sql,1)->hundle->fetchall_arrayref;
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
