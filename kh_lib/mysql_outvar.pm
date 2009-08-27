package mysql_outvar;
use strict;
use mysql_exec;
use gui_errormsg;

use mysql_outvar::a_var;

#----------------------#
#   変数リストを返す   #

sub get_list{
	my $h = mysql_exec->select("
		SELECT tani, name, id
		FROM outvar
		ORDER BY id
	",1)->hundle->fetchall_arrayref;
	
	return $h;
}

#----------------#
#   変数を削除   #

sub delete{
	my $class = shift;
	my %args  = @_;
	
	mysql_exec->do("
		DELETE FROM outvar
		WHERE
			name = \'$args{name}\'
	",1);
}

#--------------------------#
#   変数をファイルに保存   #

sub save{
	my $class = shift;
	my %args = @_;

	my @vars = ();
	my %tables = ();
	foreach my $i (@{$args{vars}}){
		my $var_obj = mysql_outvar::a_var->new($i);
		push @vars, $var_obj;
		++$tables{$var_obj->{table}};
	}

	my $header = 'No.,';
	foreach my $i (@vars){
		$header .= kh_csv->value_conv($i->{name}).',';
	}
	chop $header;

	my $sql;
	$sql .= "SELECT $vars[0]->{tani}.id,";
	foreach my $i (@vars){
		$sql .= "$i->{table}.$i->{column},";
	}
	chop $sql;
	$sql .= "\nFROM $vars[0]->{tani},";
	foreach my $i (keys %tables){
		$sql .= "$i,";
	}
	chop $sql;
	
	$sql .= "\nWHERE\n";
	my $n = 0;
	foreach my $i (@vars){
		$sql .= "AND " if $n;
		$sql .= "$i->{tani}.id = $i->{table}.id\n";
		++$n;
	}
	$sql .= "ORDER BY $vars[0]->{tani}.id";

	my $sth = mysql_exec->select($sql, 1)->hundle;

	open (VOUT,">$args{path}") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $args{path},
		)
	;
	print VOUT "$header\n";

	while (my $i = $sth->fetch) {
		my $current = '';
		foreach my $h (@{$i}){
			$current .= kh_csv->value_conv($h).',';
		}
		chop $current;
		print VOUT "$current\n";
	}
	close(VOUT);

	kh_jchar->to_sjis($args{path});


}


1;
