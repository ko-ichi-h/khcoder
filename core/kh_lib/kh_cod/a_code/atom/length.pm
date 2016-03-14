# 文書長による指定

package kh_cod::a_code::atom::length;
use base qw(kh_cod::a_code::atom);
use strict;


sub expr{
	my $self = shift;
		if ($self->raw eq 'lc'){
			return "( $self->{tani}_length.c )";
		} else {
			return "$self->{tani}_length.w";
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
	return '^lw$|^lc$';
}
sub name{
	return 'length';
}

1;



1;
