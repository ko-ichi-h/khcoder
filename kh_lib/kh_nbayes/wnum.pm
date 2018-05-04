package kh_nbayes::wnum;
use base qw(kh_nbayes);

use strict;

sub _get_wnum{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;

	# 単語リストの作製
	mysql_exec->drop_table("genkei_in_use");
	mysql_exec->do("create temporary table genkei_in_use
		(
			genkei_id int primary key not null
		) TYPE = HEAP
	",1);

	my $sql = "
		INSERT INTO genkei_in_use (genkei_id)
		SELECT genkei.id
		FROM   genkei, hselection, df_$self->{tani}
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			AND genkei.num >= $self->{min}
			AND genkei.nouse = 0
			AND genkei.id = df_$self->{tani}.genkei_id
			AND df_$self->{tani}.f >= $self->{min_df}
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
	if ($self->{max_df}){
		$sql .= "AND df_$self->{tani}.f <= $self->{max_df}\n";
	}
	mysql_exec->do($sql,1);

	# 外部変数のチェック
	my @missing = ('missing', '.', '欠損値');
	my $var_obj = mysql_outvar::a_var->new(undef,$self->{outvar});
	foreach my $i ( keys %{$var_obj->{labels}} ){
		if (
			   $var_obj->{labels}{$i} eq '.'
			|| $var_obj->{labels}{$i} eq '欠損値'
			|| $var_obj->{labels}{$i} =~ /missing/io
		){
			push @missing, $i;
		}
	}

	mysql_exec->drop_table("doc_in_use");
	mysql_exec->do("create temporary table doc_in_use
		(
			id int primary key not null
		) TYPE = HEAP
	",1);

	$sql = '';
	$sql .= "INSERT INTO doc_in_use (id)\n";
	
	if ($self->{tani} eq $var_obj->{tani}){
		$sql .= "SELECT id FROM $var_obj->{table}\n";
		$sql .= "WHERE\n";
		my $n = 0;
		foreach my $i (@missing){
			$sql .= "AND " if $n;
			$sql .= "$var_obj->{table}.$var_obj->{column} != \"$i\"\n";
			++$n;
		}
		$sql .= "ORDER BY id";
	} else {
		my $tani = $self->{tani};
		$sql .= "SELECT $tani.id\n";
		$sql .= "FROM $tani, $var_obj->{tani}, $var_obj->{table}\n";
		$sql .= "WHERE\n";
		$sql .= "	$var_obj->{tani}.id = $var_obj->{table}.id\n";
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			$sql .= "	and $var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
			last if ($var_obj->{tani} eq $i);
		}
		foreach my $i (@missing){
			$sql .= "AND ";
			$sql .= "$var_obj->{table}.$var_obj->{column} != \"$i\"\n";
			++$n;
		}
		$sql .= "ORDER BY $tani.id";
	}
	mysql_exec->do($sql,1);

	# 単語の数をチェック

	$sql = '';
	$sql = "
	SELECT count(distinct genkei.name, genkei.khhinshi_id)
	FROM  hyosobun, hyoso, genkei, genkei_in_use, $self->{tani}, doc_in_use
	WHERE
		hyosobun.hyoso_id = hyoso.id
		AND hyoso.genkei_id = genkei.id
		AND genkei.id = genkei_in_use.genkei_id
	";
	
	my $flag = 0;
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($i eq $self->{tani}){ $flag = 1; }
		if ($flag){
			$sql .= "	AND hyosobun.$i"."_id = $self->{tani}.$i"."_id\n";
		}
	}

	$sql .= "AND $self->{tani}.id = doc_in_use.id";
	
	my $h = mysql_exec->select($sql,1)->hundle->fetch->[0];

	return $h;

}


1;