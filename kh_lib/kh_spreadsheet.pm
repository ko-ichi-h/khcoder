package kh_spreadsheet;
use strict;
use warnings;

use kh_spreadsheet::xls;
use kh_spreadsheet::xlsx;
use kh_spreadsheet::csv;
use kh_spreadsheet::tsv;

use Encode;

use vars qw($fht $fhv $line $row $ncol $selected $tsv);

sub new{
	my $self;
	$self->{file} = $_[1];
	
	my $ext;
	if ( $self->{file} =~ /\.(xls|xlsx|csv|tsv)$/i ){
		$ext = $1;
		$ext =~ tr/A-Z/a-z/;
	} else {
		die("Unexpected extension!\n");
	}
	
	$ext = "kh_spreadsheet::$ext";
	
	bless $self, $ext;
	return $self;
}


sub print_line{
	my $v;
	for (my $i = 0; $i <= $kh_spreadsheet::ncol;  ++$i){
		if ($i == $kh_spreadsheet::selected){
			next if $kh_spreadsheet::row == $kh_spreadsheet::the_first_line;
			my $t = $kh_spreadsheet::line->[$i];
			$t =~ tr/<>/()/;
			$t =~ s/\x0D\x0A|\x0D|\x0A/\n/go;
			$t =~ s/_x000D_\n/\n/go if (caller)[0] eq 'kh_spreadsheet::xlsx';
			print $kh_spreadsheet::fht
				'<h5>---cell---</h5>',
				"\n",
				$t,
				"\n",
			;
		} else {
			next if $i > 1000;
			next if $i < $kh_spreadsheet::the_first_colm;
			my $t = $kh_spreadsheet::line->[$i];
			$t = '.' unless defined($t);
			$t = '.' if length($t) == 0;
			$t =~ s/[[:cntrl:]]//g;
			push @{$v}, $t;
		}
	}
	$kh_spreadsheet::tsv->print($kh_spreadsheet::fhv, $v) if $v;
}

1;
