# 文書番号による指定 --- 「No. == 3」

package kh_cod::a_code::atom::number;
use base qw(kh_cod::a_code::atom);
use strict;


sub expr{
	my $self = shift;
	return "$self->{tani}.id";
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