package mysql_getdoc::dan;
use base qw(mysql_getdoc);
use DBI;
use Jcode;

my $tani = 'dan';

sub get_doc_id{
	my $self = shift;
	return mysql_exec->select("
		SELECT $tani.id
		FROM hyosobun, $tani
		WHERE
			hyosobun.id = $self->{hyosobun_id}
			AND hyosobun.dan_id = $tani.dan_id
			AND hyosobun.h5_id = $tani.h5_id
			AND hyosobun.h4_id = $tani.h4_id
			AND hyosobun.h3_id = $tani.h3_id
			AND hyosobun.h2_id = $tani.h2_id
			AND hyosobun.h1_id = $tani.h1_id
	",1)->hundle->fetch->[0];
}

sub get_body{
	my $self = shift;
	
	my $d = mysql_exec->select("
		SELECT hyoso.name, hyoso.id, hyosobun.dan_id
		FROM hyoso, hyosobun, $tani
		WHERE
			$tani.id = $self->{doc_id}
			AND hyosobun.hyoso_id = hyoso.id
			AND hyosobun.dan_id = $tani.dan_id
			AND hyosobun.h5_id = $tani.h5_id
			AND hyosobun.h4_id = $tani.h4_id
			AND hyosobun.h3_id = $tani.h3_id
			AND hyosobun.h2_id = $tani.h2_id
			AND hyosobun.h1_id = $tani.h1_id
	",1)->hundle->fetchall_arrayref;
	return $d;
}




1;
