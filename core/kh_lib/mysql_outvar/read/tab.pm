package mysql_outvar::read::tab;
use base qw(mysql_outvar::read);
use strict;

sub parser{
	my $self = shift;
	use Text::CSV_XS;
	return Text::CSV_XS->new({
		binary     => 1,
		auto_diag  => 2,
		sep_char   => "\t"
	});
}


1;