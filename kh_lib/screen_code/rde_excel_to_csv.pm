package screen_code::rde_excel_to_csv;
use strict;

use FindBin;
use lib "$FindBin::Bin/kh_lib/screen_code";
use lib "$FindBin::Bin/kh_lib/screen_code/rde_kh_spreadsheet";
use rde_kh_spreadsheet;

sub save_excel_to_csv{

	my $self = shift;

	my %args = @_;

	

	# morpho_analyzer

	my $icode = 'utf8';

	#if ($args{lang} eq 'jp') {

		#$icode = 'cp932';

	#}

	# read excel

	my $workbook = $self->parser;

	die("failed to open *.xls file!\n") unless $workbook;

	

	my $sheet = $workbook->worksheet(0);

	my ( $row_min, $row_max ) = $sheet->row_range();

	my ( $col_min, $col_max ) = $sheet->col_range();

	

	open my $fh, ">::encoding(utf8)", $args{filev} or

		gui_errormsg->open(

			type => 'file',

			file => $args{filev}

		)

	;

	for my $row ($row_min .. $row_max){

		my $line = '';

		my $ncol = 0;

		for my $col ($col_min .. $col_max){
			
			my $t = '';

			my $cell = $sheet->get_cell( $row, $col );

			$t = $self->get_value($cell) if $cell;

			#$t =~ s/[[:cntrl:]]//g;
			
			$t =~ s/_x000D_\n/\n/go;
			if ($t =~ /[[:cntrl:]]/ || $t =~ /,/) {
				$t = "\"".$t."\""
			}

			#if (length($t) > 127){

			#	$t = substr($t, 0, 127);

			#}

			$line .= "$t,";

			++$ncol;

			if ($ncol == 1000){

				last;

			}

		}

		chop $line;

		print $fh "$line\n";

	}

	close $fh;


	return $args{selected};

}

1;