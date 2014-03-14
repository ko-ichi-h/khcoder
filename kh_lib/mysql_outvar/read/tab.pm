package mysql_outvar::read::tab;
use base qw(mysql_outvar::read);
use strict;

sub parse{
	my $self = shift;
	my $line = shift;
	
	my @line = split /\t/, $line;
	
	return \@line;
}

1;