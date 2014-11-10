package kh_spreadsheet::xls;

use strict;
use warnings;
use base 'kh_spreadsheet';

use Encode;
use Spreadsheet::ParseExcel;

sub columns{
	my $self = shift;
	
	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->parse($self->{file});
	
	die("failed to open *.xls file!\n") unless $workbook;
	
	my $sheet = $workbook->worksheet(0);
	my ( $row_min, $row_max ) = $sheet->row_range();
	my ( $col_min, $col_max ) = $sheet->col_range();
	
	my @columns = ();
	for my $col ( $col_min .. $col_max ) {
		push @columns, $sheet->get_cell( $row_min, $col )->value;
	}
	
	return \@columns;
}

1;
