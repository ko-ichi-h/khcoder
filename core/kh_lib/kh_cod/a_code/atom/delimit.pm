# 「and」や「or」などなどの演算子を識別

package kh_cod::a_code::atom::delimit;
use base qw(kh_cod::a_code::atom);
use strict;

my %conv = (
	'|'  => 'or',
	'&'  => 'and',
	'|!' => 'or not',
	'&!' => 'and not',
	'==' => '=',
);

sub ready{
	return 1;
}

sub tables{
	return 0;
}
sub expr{
	my $self = shift;
	my $t = $self->raw;
	
	if (defined($conv{$t})){
		$t = $conv{$t};
	}
	return $t;
}
sub pattern{
	my $t = '';
	$t .= '^and$';            $t .= '|';
	$t .= '^or$';             $t .= '|';
	$t .= '^not$';            $t .= '|';
	$t .= '^\($';             $t .= '|';
	$t .= '^\)$';             $t .= '|';
	$t .= '^\&$';             $t .= '|';
	$t .= '^\|$';             $t .= '|';
	$t .= '^\!$';             $t .= '|';
	$t .= '^\&\!$';           $t .= '|';
	$t .= '^\|\!$';           $t .= '|';
	$t .= '^\>$';             $t .= '|';
	$t .= '^\>=$';            $t .= '|';
	$t .= '^\<$';             $t .= '|';
	$t .= '^\<=$';            $t .= '|';
	$t .= '^==$';             $t .= '|';
	$t .= '^\+$';             $t .= '|';
	$t .= '^\-$';             $t .= '|';
	$t .= '^\*$';             $t .= '|';
	$t .= '^\/$';             $t .= '|';
	$t .= '^\d+$';
	return $t;
}

sub name{
	return 'delimit';
}
1;


__END__
