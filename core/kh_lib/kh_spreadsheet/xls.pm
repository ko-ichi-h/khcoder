package kh_spreadsheet::xls;

use strict;
use warnings;
use base 'kh_spreadsheet';

sub parser{
	my $self = shift;
	my %args = @_;
	
	# For column name only
	if ( defined($args{columns}) && $args{columns} == 1) {
		use Spreadsheet::ParseExcel;
		my $parser = Spreadsheet::ParseExcel->new(
			CellHandler => \&cell_handler_c,
			#NotSetCell  => 1
		);
		sub cell_handler_c {
			my $workbook    = $_[0];
			#my $sheet_index = $_[1];
			my $row         = $_[2];
			#my $col         = $_[3];
			#my $cell        = $_[4];
			$workbook->ParseAbort(1) if $row > 0;
		}
		return $parser->parse($self->{file});
	}
	
	# Full file
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
