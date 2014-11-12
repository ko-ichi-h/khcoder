package kh_spreadsheet::xls;

use strict;
use warnings;
use base 'kh_spreadsheet';

use Spreadsheet::ParseExcel;

sub parser{
	my $self = shift;
	return Spreadsheet::ParseExcel->new->parse($self->{file});
}

sub get_value{
	use Encode qw(decode);
	if ( $_[1] ){
		my $t = $_[1]->value ;
		$t = decode('utf8', $t) unless utf8::is_utf8($t);
		return $t;
	} else {
		return '';
	}
}

1;
