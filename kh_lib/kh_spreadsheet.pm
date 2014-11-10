package kh_spreadsheet;
use strict;
use warnings;

use kh_spreadsheet::xls;
use kh_spreadsheet::xlsx;
use kh_spreadsheet::csv;

sub new{
	my $self;
	$self->{file} = $_[1];
	
	my $ext;
	if ( $self->{file} =~ /\.(xls|xlsx|csv)$/i ){
		$ext = $1;
		$ext =~ tr/A-Z/a-z/;
	} else {
		die("Unexpected extension!\n");
	}
	
	$ext = "kh_spreadsheet::$ext";
	
	bless $self, $ext;
	return $self;
}

1;
