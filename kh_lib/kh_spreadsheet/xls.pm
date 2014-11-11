package kh_spreadsheet::xls;

use strict;
use warnings;
use base 'kh_spreadsheet';

use Encode;
use Spreadsheet::ParseExcel;

sub save_files{
	my $self = shift;
	my %args = @_;
	
	# morpho_analyzer
	my $icode;
	if (
		   $::config_obj->c_or_j eq 'chasen'
		|| $::config_obj->c_or_j eq 'mecab'
	){
		$icode = 'cp932';
	} else {
		$icode = 'latin1';
	}
	
	# read excel
	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->parse($self->{file});
	
	die("failed to open *.xls file!\n") unless $workbook;
	
	my $sheet = $workbook->worksheet(0);
	my ( $row_min, $row_max ) = $sheet->row_range();
	my ( $col_min, $col_max ) = $sheet->col_range();
	
	# make a text file
	open my $fh, ">::encoding($icode)", $args{filet} or
		gui_errormsg->open(
			type => 'file',
			file => $args{file}
		)
	;
	for my $row ($row_min + 1 .. $row_max){
		my $t = '';
		my $cell = $sheet->get_cell( $row, $args{selected} );
		$t = $cell->value if $cell;
		$t =~ tr/<>/()/;
		print $fh
			'<h5>---cell---</h5>',
			"\n",
			$t,
			"\n",
		;
	}
	close $fh;

	# make a variable file, < 127 char, <= 1000 columns
	open $fh, ">::encoding($icode)", $args{filev} or
		gui_errormsg->open(
			type => 'file',
			file => $args{filev}
		)
	;
	for my $row ($row_min .. $row_max){
		my $line = '';
		my $ncol = 0;
		for my $col ($col_min .. $col_max){
			if ($col == $args{selected}){
				next;
			}
			my $t = '';
			my $cell = $sheet->get_cell( $row, $col );
			$t = $cell->value if $cell;
			$t = '.' if length($t) == 0;
			$t =~ s/[[:cntrl:]]//g;
			if (length($t) > 127){
				$t = substr($t, 0, 127);
			}
			$line .= "$t\t";
			++$ncol;
			if ($ncol == 1000){
				last;
			}
		}
		chop $line;
		print $fh "$line\n";
	}
	close $fh;

	return 1;
}

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
