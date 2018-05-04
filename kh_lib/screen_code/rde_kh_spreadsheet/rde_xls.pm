package rde_kh_spreadsheet::rde_xls;

use strict;
use warnings;
use base 'rde_kh_spreadsheet';

sub parser{
	my $self = shift;
	if (
		   $::config_obj->c_or_j eq 'chasen'
		|| $::config_obj->c_or_j eq 'mecab'
	){
		use Spreadsheet::ParseExcel::FmtJapan;
		return Spreadsheet::ParseExcel->new->parse(
			$self->{file},
			Spreadsheet::ParseExcel::FmtJapan->new(Code => 'utf8')
		);
	} else {
		return Spreadsheet::ParseExcel->new->parse($self->{file});
	}
}

sub get_value{
	use Encode qw(decode);
	if ( $_[1] ){
		my $t;
		$t = $_[1]->value ;
		$t = decode('utf8', $t) unless utf8::is_utf8($t);
		
		return $t;
	} else {
		return '';
	}
}

1;
