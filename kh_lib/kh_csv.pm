package kh_csv;
use strict;

# CSVファイル作製のために、「,"」と改行をエスケープ
# usage: kh_csv->value_conv("value");
sub value_conv{
	my $v = $_[1];
	if (
		   ($v =~ s/"/""/g )
		or ($v =~ /\r|\n|,/o )
	){
		$v = "\"$v\"";
	}
	return $v;
}

1;
