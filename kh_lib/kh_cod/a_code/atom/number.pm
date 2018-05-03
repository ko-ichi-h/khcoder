# 文書番号による指定 --- 「No. == 3」

package kh_cod::a_code::atom::number;
use base qw(kh_cod::a_code::atom);
use strict;

sub expr{
	my $self = shift;
	
	if ($self->{tani} eq 'bun'){
		return "bun.seq";
	} else {
		return "$self->{tani}.id";
	}
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
sub tables{
	return 0;
}

sub ready{
	my $self = shift;
	$self->{tani} = shift;
}

sub pattern{
	return '^No\.$';
}
sub name{
	return 'number';
}

1;