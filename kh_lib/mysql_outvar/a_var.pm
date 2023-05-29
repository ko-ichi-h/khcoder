package mysql_outvar::a_var;
use strict;
use utf8;
use mysql_exec;

sub new{
	my $class = shift;
	my $self;
	$self->{name} = shift;
	$self->{id}   = shift;
	bless $self, $class;
	
	if (defined($self->{name}) && length($self->{name}) ){# 変数名から他の情報を取得
		my $name = mysql_exec->quote( $self->{name} );
		my $i = mysql_exec->select("
			SELECT tab, col, tani, id
			FROM outvar
			where name = $name
		",1)->hundle->fetch;
		
		if ($i){
			$self->{table}  = $i->[0];
			$self->{column} = $i->[1];
			$self->{tani}   = $i->[2];
			$self->{id}     = $i->[3];
		}
	} else {                                      # 変数IDから他の情報を取得
		my $i = mysql_exec->select("
			SELECT tab, col, tani, name
			FROM outvar
			where id = \'$self->{id}\'
		",1)->hundle->fetch;
		$self->{table}  = $i->[0];
		$self->{column} = $i->[1];
		$self->{tani}   = $i->[2];
		$self->{name}   = $i->[3];
	}
	unless ( defined($self->{id}) ){
		return $self;
	}
	
	my $i = mysql_exec->select("
		SELECT val, lab
		FROM outvar_lab
		WHERE var_id = $self->{id}
	",1)->hundle->fetchall_arrayref;
	foreach my $h (@{$i}){
		$self->{labels}{$h->[0]} = $h->[1];
	}
	
	return $self;
}

sub copy {
	my $self = shift;
	my $name = shift;
	
	my @data;
	
	push @data, [ $name ];
	
	my $sql = '';
	$sql .= "SELECT $self->{column} FROM $self->{table} ";
	$sql .= "ORDER BY id";

	my $type = 'INT';

	my $h = mysql_exec->select($sql,1)->hundle;
	while (my $i = $h->fetch){
		push @data, [ $i->[0] ];
		if ( $i->[0] =~ /[^0-9]/ ){
			$type = '';
		}
	}
	
	&mysql_outvar::read::save(
		data     => \@data,
		tani     => $self->{tani},
		var_type => $type,
	) or return 0;
	return 1;
}

# 値のリストを返す（生の値を返す）
sub values{
	my $self = shift;

	my @v = ();
	my $names = '';

	# 値リストの取得
	my $f = mysql_exec->select("
		SELECT $self->{column}
		FROM   $self->{table}
		GROUP BY $self->{column}
	",1)->hundle;
	while (my $i = $f->fetch){
		my $chk0 = utf8::is_utf8($i->[0]);
		$i->[0] = Encode::decode('utf8', $i->[0]) unless utf8::is_utf8($i->[0]);
		push @v, $i->[0];
		$names .= $i->[0];
	}

	# ソート
	my $chk1 = utf8::is_utf8($v[1]);
	if ($names =~ /\A[0-9]+\Z/){
		@v = sort {$a <=> $b} @v;
	} else {
		if ($::project_obj->morpho_analyzer_lang eq 'jp') {
			@v = sort {Encode::encode('eucjp', $a) cmp Encode::encode('eucjp', $b)} @v;
		} else {
			@v = sort @v;
		}
	}
	my $chk2 = utf8::is_utf8($v[1]);

	return \@v;
}

sub n{
	my $self = shift;

	my $f = mysql_exec->select("
		SELECT count(*)
		FROM   $self->{table}
	",1)->hundle;
	
	my $n = 0;
	$n = $f->fetch->[0] if $f;
	
	return $n;
}

# 値のリストを返す（値ラベルがある場合はラベルを返す）
sub print_values{
	my $self = shift;
	
	# リストの取得
	my %d;
	my $raw_values = $self->values;
	my @v = ();
	my $names = '';
	my $names_v = '';
	foreach my $i (@{$raw_values}){
		my $chk = $self->print_val($i);
		next if $d{$chk};
		$d{$chk} = 1;
		
		push @v, $chk;
		$names .= $chk;
		$names_v .= $i;
	}
	
	# ソート
	unless ( $names_v =~ /\A[0-9]*\.*[0-9]*\Z/ ) {# 値が数値のみなら値でソート
		if ($names =~ /\A[0-9]+\Z/){
			@v = sort {$a <=> $b} @v;
		} else {
			if ($::project_obj->morpho_analyzer_lang eq 'jp') {
			@v = sort {Encode::encode('eucjp', $a) cmp Encode::encode('eucjp', $b)} @v;
			} else {
				@v = sort @v;
			}
		}
	}

	return \@v;
}



# 値ラベルもしくは値を与えられた時に、値を返す
sub real_val{
	my $self = shift;
	my $val  = shift;
	
	# print "val: $val\n";
	# print "val-sjis: ", Jcode->new($val,'euc')->sjis, "\n";
	
	foreach my $i (keys %{$self->{labels}}){
		if ($val eq $self->{labels}{$i}){
			$val = $i;
			last;
		}
	}
	return $val;
}

# 値ラベルもしくは値を与えられた時に、値ID（何番目の値かを示す番号）を返す
sub real_val_id{
	my $self = shift;
	my $val  = shift;
	
	# print "val: $val\n";
	# print "val-sjis: ", Jcode->new($val,'euc')->sjis, "\n";
	
	foreach my $i (keys %{$self->{labels}}){
		if ($val eq $self->{labels}{$i}){
			$val = $i;
			last;
		}
	}

	my $values = $self->values;
	my $n = 0;
	foreach my $i (@{$values}){
		if ($i eq $val){
			last;
		}
		++$n;
	}
	
	return $n;
}

# 特定の文書に与えられた値を返す
sub doc_val{
	my $self = shift;
	my %args = @_;
	
	my $doc_id;
	if ($self->{tani} eq $args{tani}){
		$doc_id = $args{doc_id};
	} else {
		my $sql = "SELECT $self->{tani}.id\n";
		$sql .=   "FROM   $args{tani}, $self->{tani}\n";
		$sql .=   "WHERE\n";
		$sql .=   "\t$args{tani}.id = $args{doc_id}\n";
		
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			$sql .= "\tAND $self->{tani}.$i"."_id = $args{tani}.$i"."_id\n";
			last if $i eq $self->{tani};
		}
		$doc_id = mysql_exec->select("$sql",1);
		
		if ($doc_id->selected_rows){
			$doc_id = $doc_id->hundle->fetch->[0];
		} else {
			# 段落単位の変数の値を、文単位で見ようとする場合、
			# 見出し文では「該当なし（undef）」に
			return undef;
		}
		
		# print "$sql";
		# print "doc_id_var: $doc_id\n";
	}
	
	return mysql_exec->select("
		SELECT $self->{column}
		FROM   $self->{table}
		WHERE  id = $doc_id
	",1)->hundle->fetch->[0];
}

# 値を与えられた時に、値ラベルか値を返す
sub print_val{
	my $self = shift;
	if ($self->{labels}{$_[0]}){
		return $self->{labels}{$_[0]};
	} else {
		return $_[0];
	}
}

# 値ラベル＋単集の表を返す
sub detail_tab{
	my $self = shift;
	
	my $names = '';
	
	# 度数（単純集計）取得
	my $f = mysql_exec->select("
		SELECT $self->{column}, COUNT(*)
		FROM   $self->{table}
		GROUP BY $self->{column}
	",1)->hundle;
	while (my $i = $f->fetch){
		$self->{freqs}{$i->[0]} = $i->[1];
		$names .= $i->[0];
	}
	
	# リターンする表を作成
	my @data;
	
	if ($names =~ /\A[0-9]+\Z/){
		foreach my $i (sort {$a <=> $b} keys %{$self->{freqs}}){
			push @data, [$i, $self->{labels}{$i}, $self->{freqs}{$i} ];
		}
	} else {
		if ($::project_obj->morpho_analyzer_lang eq 'jp') {
			foreach my $i (
				sort
				{Encode::encode('eucjp', $a) cmp Encode::encode('eucjp', $b)}
				keys %{$self->{freqs}}
			){
				push @data, [$i, $self->{labels}{$i}, $self->{freqs}{$i} ];
			}
		} else {
			foreach my $i (sort keys %{$self->{freqs}}){
				push @data, [$i, $self->{labels}{$i}, $self->{freqs}{$i} ];
			}
		}
	}
	

	
	return \@data;
}

# 値ラベルを保存
sub label_save{
	my $self = shift;
	my $val  = shift;
	my $lab  = shift;
	
	if ($lab eq ''){                          # ラベルが空の場合はレコード削除
		mysql_exec->do("
			DELETE FROM outvar_lab
			WHERE
				var_id = $self->{id}
				AND val = \'$val\'
		",1);
	} else {
		my $exists = mysql_exec->select(     # レコードの有無を確認
			"SELECT *
			FROM outvar_lab
			WHERE 
				var_id = $self->{id}
				AND val = \'$val\'"
		)->hundle->rows;
		if ($exists){
			mysql_exec->do("
				UPDATE outvar_lab
				SET lab = \'$lab\'
				WHERE
					var_id = $self->{id}
					AND val = \'$val\'
			",1);
		} else {
			mysql_exec->do("
				INSERT INTO outvar_lab (var_id, val, lab)
				VALUES ($self->{id}, \'$val\', \'$lab\')
			",1);
		}
	}
}

sub tani{
	my $self = shift;
	return $self->{tani};
}

sub table{
	my $self = shift;
	return $self->{table};
}

1;
