package mysql_getdoc::h1;
use base qw(mysql_getdoc);
use strict;

sub get_doc_id{
	my $self = shift;
	return mysql_exec->select("
		SELECT h1_id
		FROM hyosobun
		WHERE
			hyosobun.id = $self->{hyosobun_id}
	",1)->hundle->fetch->[0];
}

sub get_body{
	my $self = shift;
	return mysql_exec->select("
		SELECT hyoso.name, hyoso.id, hyosobun.dan_id
		FROM hyoso, hyosobun
		WHERE
			hyosobun.h1_id = $self->{doc_id}
			AND hyosobun.hyoso_id = hyoso.id
		ORDER BY hyosobun.id
	",1)->hundle->fetchall_arrayref;
}

sub get_header{
	return '';
}



1;
