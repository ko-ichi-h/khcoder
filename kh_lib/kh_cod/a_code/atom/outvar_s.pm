# 外部変数（値の降順による検索用）

package kh_cod::a_code::atom::outvar_s;
use base qw(kh_cod::a_code::atom);
use strict;
use utf8;
my $debug = 0;

sub expr{
	my $self = shift;
	
	if ($self->{valid}){
		my ($col,$tab);
		$col = (split /\_/, $self->{tables}[0])[2];
		$tab = $self->parent_table;
		print "expr: IFNULL($tab.$col,0) > 0\n" if $debug;
		return "IFNULL($tab.$col,0) > 0";
	} else {
		return '0';
	}
}

sub num_expr{
	my $self = shift;
	
	if ($self->{valid}){
		my ($col,$tab);
		$col = (split /\_/, $self->{tables}[0])[2];
		$tab = $self->parent_table;
		print "num_expr: IFNULL($tab.$col,0)\n" if $debug;
		return "IFNULL($tab.$col,0)";
	} else {
		return '0';
	}
}

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;

	if ($self->raw =~ /^"(.+)"$/){
		$self->{raw} = $1;
		$self->{raw} =~ s/""/"/g;
	}

	# ルール指定の解釈
	my $var;
	if ($self->raw =~ /^<>(.+)<>$/o){
		$var = $1;
		print "atom-outvar_s: $var\n" if $debug;
	} else {
		die("something wrong!");
	}
	
	# 変数の存在を確認
	my $var_obj = mysql_outvar::a_var->new($var);
	unless ($var_obj->{tani}){
		$self->{valid} = 0;
		return 1;
	}
	print "atom-outvar_s: the variable found\n" if $debug;
	
	# 集計単位が一致しているか確認
	$self->{valid} = 1;
	unless ($tani eq $var_obj->{tani}){
		$self->{valid} = 0;
		return 1;
	}
	print "atom-outvar_s: tani looks ok\n" if $debug;

	# テーブル名決定
	my $table = "ct_$tani"."_ovs"."$var_obj->{id}";
	print "atom-outvar_s: table: $table\n" if $debug;
	$self->{tables} = ["$table"];

	# テーブル作成
	if ( mysql_exec->table_exists($table) ){
		print "atom-outvar_s: the table already exists\n" if $debug;
		return 1;
	}
	mysql_exec->do("
		CREATE TABLE $table (
			id INT primary key not null,
			num DOUBLE
		)
	",1);
	
	my $sql = "
		INSERT
		INTO $table (id, num)
		SELECT id, $var_obj->{column}
		FROM $var_obj->{table}
		WHERE
			$var_obj->{column} IS NOT NULL
	";
	mysql_exec->do("$sql",1);
	$sql = Encode::encode('utf8', $sql) if utf8::is_utf8($sql);
	print "$sql" if $debug;
}

#--------------#
#   アクセサ   #

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
	return '^<>.+<>|^"<>.+<>"$';
}
sub name{
	return 'outvar_s';
}

1;