package mysql_outvar::read::csv;
use base qw(mysql_outvar::read);
use strict;

sub parse{
	my $self = shift;
	my $line = shift;

	my $tmp = Jcode->new($line)->euc;
	$tmp =~ s/(?:\x0D\x0A|[\x0D\x0A])?$/,/;
	my @line = map {/^"(.*)"$/ ? scalar($_ = $1, s/""/"/g, $_) : $_}
	                ($tmp =~ /("[^"]*(?:""[^"]*)*"|[^,]*),/g);
	return \@line;
}

1;