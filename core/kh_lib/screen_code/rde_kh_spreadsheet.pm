package rde_kh_spreadsheet;
use strict;


use rde_kh_spreadsheet::rde_xls;
use rde_kh_spreadsheet::rde_xlsx;
use rde_kh_spreadsheet::rde_csv;

use Encode;

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
	$ext = "rde_kh_spreadsheet::rde_".$ext;
	bless $self, $ext;
	return $self;
}

# for xls and xlsx
sub save_files{
	my $self = shift;
	my %args = @_;
	
	# morpho_analyzer
	my $icode = 'utf8';
	if ($args{lang} eq 'jp') {
		$icode = 'cp932';
	}
	# read excel
	my $workbook = $self->parser;
	
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
		$t = $self->get_value($cell) if $cell;
		$t =~ tr/<>/()/;
		print $fh
			'<h5>---cell---</h5>',
			"\n",
			$t,
			"\n",
		;
	}
	close $fh;

	# make a variable file, <= 1000 columns
	return 1 if $col_min == $col_max;
	
	open $fh, ">::encoding(utf8)", $args{filev} or
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
			$t = $self->get_value($cell) if $cell;
			$t = '.' if length($t) == 0;
			$t =~ s/_x000D_\n/\n/go;
			$t =~ s/[[:cntrl:]]//g;
			#if (length($t) > 127){
			#	$t = substr($t, 0, 127);
			#}
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
# for xls and xlsx
sub columns{
	my $self = shift;
	
	use Benchmark;
	my $t0 = new Benchmark;
	
	#my $parser   = $self->parser;
	my $workbook = $self->parser; #$parser->parse($self->{file});
	
	die("Failed to open the Excel file!\n") unless $workbook;
	
	my $sheet = $workbook->worksheet(0);
	my ( $row_min, $row_max ) = $sheet->row_range();
	my ( $col_min, $col_max ) = $sheet->col_range();
	
	my @columns = ();
	for my $col ( $col_min .. $col_max ) {
		my $t = '';
		my $cell = $sheet->get_cell( $row_min, $col );
		$t = $self->get_value($cell) if $cell;
		push @columns, $t;
	}
	
	my $t1 = new Benchmark;
	print "Gets Columns:\t",timestr(timediff($t1,$t0)),"\n";
	
	return \@columns;
}

1;
