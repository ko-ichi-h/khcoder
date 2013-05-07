# 上位見出しによる指定

package kh_cod::a_code::atom::heading;
use base qw(kh_cod::a_code::atom);
use strict;

my $num = 0;
sub reset{
	$num = 0;
}

sub expr{
	my $self = shift;
	my $t = $self->tables;
	unless ($t){ return '0';}
	
	$t = $t->[0];
	my $col = (split /\_/, $t)[2].(split /\_/, $t)[3];
	my $sql = "IFNULL(".$self->parent_table.".$col,0)";
	return $sql;
}

sub num_expr{
	my $self = shift;
	my $sort = shift;
	my $r = "1";
	if ($sort eq 'tf*idf'){
		$r .= " * ".$self->idf;
	}
	elsif ($sort eq 'tf/idf'){
		$r .= " / ".$self->idf;
	}
	return $r;
}

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;

	if ($self->raw =~ /^"(.+)"$/){
		$self->{raw} = $1;
	}

	# ルール指定の解釈
	my ($var, $val);
	if ($self->raw =~ /<>(見出し|heading)([1-5])\-\->(.+)$/io){
		$var = $2;
		$val = $3;
		$val = '\'<h'."$var".'>'."$val".'</h'."$var".'>\'';
		$self->{heading_tani} = "h"."$var";
	} else {
		die("something wrong!");
	}
	
	
	# 集計単位が矛盾しないかどうか確認
	$self->{valid} = 1;
	if ($tani =~ /h([1-5])/i){
		if ($1 < $var){
			$self->{valid} = 0;
			return;
		}
	}
	
	# 条件に合致する見出し文のリストを作製
	my ($temp_s, $temp_c);
	foreach my $i (1,2,3,4,5){
		$temp_s .= "h"."$i"."_id,";
		$temp_c .= "h"."$i"."_id int,\n";
		last if $var == $i;
	}
	chop $temp_s; chop $temp_c; chop $temp_c;
	mysql_exec->drop_table('ct_tmp_midashi');
	mysql_exec->do("
		CREATE TEMPORARY TABLE ct_tmp_midashi (
			$temp_c
		) TYPE=HEAP
	",1);
	mysql_exec->do("
		INSERT INTO ct_tmp_midashi ($temp_s)
		SELECT $temp_s
		FROM   bun, bun_r
		WHERE
			    bun.id = bun_r.id
			AND bun_id = 0
			AND dan_id = 0
			AND rowtxt = $val
	",1);
	
	# 当該の見出し文を持つケースをリストアップ

	my $table = "ct_$tani"."_heading_$num";
	$self->{tables} = ["$table"];
	++$num;
	mysql_exec->drop_table($table);
	mysql_exec->do("
		CREATE TABLE $table (
			id INT primary key not null,
			num INT
		)
	",1);
	my $sql;
	$sql .= "INSERT INTO $table (id, num)\n";
	$sql .= "SELECT $tani.id, 1\n";
	$sql .= "FROM $tani, ct_tmp_midashi\n";
	$sql .= "WHERE\n";
	my $n = 0;
	foreach my $i (1,2,3,4,5){
		$sql .= "AND " if $n;
		$sql .= "$tani.h"."$i"."_id = ct_tmp_midashi.h"."$i"."_id\n";
		last if $var == $i;
		++$n;
	}
	mysql_exec->do($sql,1);
	
	return $self;
}

#-------------------------------#
#   利用するtmp tableのリスト   #

sub tables{
	my $self = shift;
	return $self->{tables};
}

#----------------#
#   親テーブル   #
sub parent_table{
	my $self = shift;
	my $new  = shift;
	
	if (length($new)){
		$self->{parent_table} = $new;
	}
	return $self->{parent_table};
}


sub pattern{
	return '^<>見出し[1-5]\-\->.+|^"<>見出し[1-5]\-\->.+"$|^<>heading[1-5]\-\->.+|^"<>heading[1-5]\-\->.+"$';
}
sub name{
	return 'heading';
}


1;