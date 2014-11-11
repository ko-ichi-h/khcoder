package kh_spreadsheet::xls;

use strict;
use warnings;
use base 'kh_spreadsheet';

use Spreadsheet::ParseExcel;

sub parser{
	return Spreadsheet::ParseExcel->new;
}

1;
