package kh_cod::a_code::atom::delimit;
use base qw(kh_cod::a_code::atom);
use strict;

sub ready{
	return 1;
}

sub tables{
	return 0;
}
sub expr{
	my $self = shift;
	return $self->raw;
}
sub pattern{
	return '^and$|^or$|^not$|^\($|^\)$';
}

sub name{
	return 'delimit';
}
1;


__END__


sub if_delimit{
	my $ifdelimit = 0;
	if (
		($_[0] eq '|')
		|| ($_[0] eq '&')
		|| ($_[0] eq '(')
		|| ($_[0] eq ')')
		|| ($_[0] eq '!')
		|| ($_[0] eq '&!')
		|| ($_[0] eq '|!')
		|| ($_[0] eq 'and')
		|| ($_[0] eq 'or')
		|| ($_[0] eq 'not')
		|| ($_[0] eq '+')
		|| ($_[0] eq '-')
		|| ($_[0] eq '>')
		|| ($_[0] eq '>=')
		|| ($_[0] eq '<=')
		|| ($_[0] eq '<')
		|| ($_[0] eq '==')
		|| ($_[0] =~ /^\d+$/)
	){
		$ifdelimit = 1;
	}
	return($ifdelimit);
}