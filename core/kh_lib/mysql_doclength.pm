package mysql_doclength;
use strict;

my $records_per_once = 200;

use mysql_exec;

sub make{
	my $class = shift;
	my $self;
	$self->{tani} = shift;

	$self->{html} = "99999";

	bless $self, $class;
	

	
	mysql_exec->drop_table("tmp_len_$self->{tani}");
	mysql_exec->do("
		CREATE TABLE tmp_len_$self->{tani} (
			id int primary key not null,
			length_c int,
			length_w int
		)
	",1);

	my $id = 1;
	while (1){
		mysql_exec->do(
			$self->sql($id, $id + $records_per_once),
			1
		);
		$id += $records_per_once;
		print "$id,";
		if ($id > 1492){last;}
	}

}

sub sql{
	my $self = shift;
	my $d1 = shift;
	my $d2 = shift;
	
	my $sql = "INSERT INTO tmp_len_$self->{tani} (id, length_c, length_w)\n";
	$sql .= "SELECT $self->{tani}.id, sum(hyoso.len), count(*)\n";
	$sql .= "FROM hyosobun, hyoso, $self->{tani}, genkei\n";
	$sql .= "WHERE\n";
	$sql .= "	    hyosobun.hyoso_id = hyoso.id\n";
	$sql .= "	AND hyoso.genkei_id = genkei.id\n";

	my $flag = 0;
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($i eq $self->{tani}){ $flag = 1; }
		if ($flag){
			$sql .= "	AND hyosobun.$i"."_id = $self->{tani}.$i"."_id\n";
		}
	}

	$sql .= "	AND genkei.nouse = 0\n";
	$sql .= "	AND genkei.khhinshi_id != $self->{html}\n";
	$sql .= "	AND $self->{tani}.id >= $d1\n";
	$sql .= "	AND $self->{tani}.id < $d2\n";
	$sql .= "GROUP BY h5.id";
	
	return $sql;
}




1;