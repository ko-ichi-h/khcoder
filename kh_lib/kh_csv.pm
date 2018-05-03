package kh_csv;
use strict;

# CSVファイル作製のために、「,"」と改行をエスケープ
# usage: kh_csv->value_conv("value");
sub value_conv{
	my $v = $_[1];
	return '' unless defined($v);
	if (
		   ($v =~ s/"/""/g )
		or ($v =~ /\r|\n|,/o )
	){
		$v = "\"$v\"";
	}
	return $v;
}

sub value_conv_t{
	my $v = $_[1];
	$v =~ s/\t/ /g;
	return $v;
}


1;
