# 外部変数による指定（KH Coderバージョン1x 互換）

package kh_cod::a_code::atom::outvar_o;
use base qw(kh_cod::a_code::atom);
use strict;

sub expr{
	my $self = shift;
	
	if ($self->{valid}){
		my ($col,$tab);
		$col = (split /\_/, $self->{tables}[0])[2].(split /\_/, $self->{tables}[0])[3];
		$tab = $self->parent_table;
		return "IFNULL($tab.$col,0)";
	} else {
		return '0';
	}
}

sub ready{
	my $self = shift;
	my $tani = shift;
	
	# ルール指定の解釈
	my ($var, $val);
	if ($self->raw =~ /<>(.+)\-\->(.+)$/o){
		$var = $1;
		$val = $2;
	} else {
		die("something wrong!");
	}
	
	# 集計単位が一致するかどうか確認
	my $var_obj = mysql_outvar::a_var->new($var);
	if ($var_obj->{tani} eq $tani){
		$self->{valid} = 1;
	} else {
		$self->{valid} = 0;
		return 1;
	}
	
	# テーブル名決定
	$val = $var_obj->real_val($val);
	my @temp = unpack "C*", $val;
	my $temp;
	foreach my $i (@temp){
		$temp .= $i;
	}
	my $table = "ct_$tani"."_ovo"."$var_obj->{id}"."_"."$temp";
	$self->{tables} = ["$table"];
	
	# テーブル作成
	if ( mysql_exec->table_exists($table) ){
		return 1;
	}
	mysql_exec->do("
		CREATE TABLE $table (
			id INT primary key not null,
			num INT
		)
	",1);
	mysql_exec->do("
		INSERT
		INTO $table (id, num)
		SELECT id, 1
		FROM $var_obj->{table}
		WHERE
			$var_obj->{column} = \'$val\'
	",1);
}

sub tables{
	my $self = shift;
	return $self->{tables};
}

sub parent_table{
	my $self = shift;
	my $new  = shift;
	
	if (length($new)){
		$self->{parent_table} = $new;
	}
	return $self->{parent_table};
}

sub pattern{
	return '^<>.+\-\->.+';
}
sub name{
	return 'outvar_o';
}

1;