package kh_spreadsheet::xls;
use base 'kh_spreadsheet';

use strict;
use warnings;


use vars qw(@cell $fht $fhv $line $selected $row $ncol);

sub columns{
	my $self = shift;
	@kh_spreadsheet::xls::cell = ();

	use Spreadsheet::ParseExcel;
	my $parser = Spreadsheet::ParseExcel->new(
		CellHandler => \&cell_handler_cc,
		NotSetCell  => 1
	)->parse(
		$self->{file}
	);
	
	
	sub cell_handler_cc {
		my $workbook    = $_[0];
		my $sheet_index = $_[1];
		my $row         = $_[2];
		#my $col         = $_[3];
		my $cell        = $_[4];
		
		#print "$sheet_index, $row\n";
		
		$workbook->ParseAbort(1) if $row > 0;
		$workbook->ParseAbort(1) if $sheet_index > 0;
		
		if ($row == 0 && $sheet_index == 0){
			my $t = $cell->value;
			$t = Encode::decode('utf8', $t) unless utf8::is_utf8($t);
			push @kh_spreadsheet::xls::cell, $t;
		}
	}
	
	return \@kh_spreadsheet::xls::cell;
}

sub save_files{
	my $self = shift;
	my %args = @_;

	# text file
	$kh_spreadsheet::xls::fht = undef;
	open $kh_spreadsheet::xls::fht, '>:encoding(utf8)', $args{filet} or
		gui_errormsg->open(
			type => 'file',
			file => $args{file}
		)
	;
	# variable file
	$kh_spreadsheet::xls::fhv = undef;
	open $kh_spreadsheet::xls::fhv, '>::encoding(utf8)', $args{filev} or
		gui_errormsg->open(
			type => 'file',
			file => $args{filev}
		)
	;

	# init
	$kh_spreadsheet::xls::line = '';
	$kh_spreadsheet::xls::row = 0;
	$kh_spreadsheet::xls::ncol = 0;
	$kh_spreadsheet::xls::selected = $args{selected};

	use Spreadsheet::ParseExcel::FmtJapan;
	my $p = Spreadsheet::ParseExcel->new(
		CellHandler => \&cell_handler_s,
		NotSetCell  => 1
	)->parse(
		$self->{file},
		Spreadsheet::ParseExcel::FmtJapan->new(Code => 'utf8')
	);
	die("failed to open *.xls file!\n") unless $p;

	sub cell_handler_s {
		my $workbook    = $_[0];
		my $sheet_index = $_[1];
		my $row         = $_[2];
		my $col         = $_[3];
		my $cell        = $_[4];
		
		if ($sheet_index > 0){
			$workbook->ParseAbort(1);
			return 1;
		}
		
		unless ($row == $kh_spreadsheet::xls::row){
			chop $kh_spreadsheet::xls::line;
			print $kh_spreadsheet::xls::fhv $kh_spreadsheet::xls::line, "\n";
			
			$kh_spreadsheet::xls::line = '';
			$kh_spreadsheet::xls::ncol = 0;
			$kh_spreadsheet::xls::row = $row;
		}
		
		if ($col == $kh_spreadsheet::xls::selected){
			return 1 if $row == 0;
			my $t = $cell->value;
			$t = Encode::decode('utf8', $t) unless utf8::is_utf8($t);
			$t =~ tr/<>/()/;
			print $kh_spreadsheet::xls::fht
				'<h5>---cell---</h5>',
				"\n",
				$t,
				"\n",
			;
		} else {
			return 1 if $kh_spreadsheet::xls::ncol >= 1000;
			my $t = $cell->value;
			$t = Encode::decode('utf8', $t) unless utf8::is_utf8($t);
			$t = '.' if length($t) == 0;
			$t =~ s/[[:cntrl:]]//g;
			$kh_spreadsheet::xls::line .= "$t\t";
			++$kh_spreadsheet::xls::ncol;
		}
	}

	if ( length( $kh_spreadsheet::xls::line ) ){
		chop $kh_spreadsheet::xls::line;
		print $kh_spreadsheet::xls::fhv $kh_spreadsheet::xls::line;
	}

	close $kh_spreadsheet::xls::fht;
	close $kh_spreadsheet::xls::fhv;
}

1;

__END__

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
