package kh_spreadsheet::xls;
use base 'kh_spreadsheet';

use strict;
use warnings;


use vars qw(@cell);

sub columns{
	my $self = shift;
	@kh_spreadsheet::xls::cell = ();
	$kh_spreadsheet::xls::the_row = -1;

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
		my $col         = $_[3];
		my $cell        = $_[4];

		#print "$sheet_index, $row, $col\n";
		$kh_spreadsheet::xls::the_row = $row
			if $kh_spreadsheet::xls::the_row == -1;

		if ($row > $kh_spreadsheet::xls::the_row){
			$workbook->ParseAbort(1);
			return;
		}
		if ($sheet_index > 0){
			$workbook->ParseAbort(1);
			return;
		}

		my $t = $cell->value;
		$t = "[no_name]" unless length($t);
		$kh_spreadsheet::xls::cell[$col] = $t;
	}
	
	return \@kh_spreadsheet::xls::cell;
}

sub save_files{
	my $self = shift;
	my %args = @_;
	$kh_spreadsheet::the_first_line = -1;
	$kh_spreadsheet::the_first_colm = -1;

	use Benchmark;
	my $t0 = new Benchmark;

	# text file
	$kh_spreadsheet::fht = undef;
	open $kh_spreadsheet::fht, '>:encoding(utf8)', $args{filet} or
		gui_errormsg->open(
			type => 'file',
			file => $args{file}
		)
	;
	# variable file
	$kh_spreadsheet::fhv = undef;
	open $kh_spreadsheet::fhv, '>::encoding(utf8)', $args{filev} or
		gui_errormsg->open(
			type => 'file',
			file => $args{filev}
		)
	;

	# init
	$kh_spreadsheet::line = undef;
	$kh_spreadsheet::row = 0;
	$kh_spreadsheet::ncol = -1;
	$kh_spreadsheet::selected = $args{selected};

	use Text::CSV_XS;
	$kh_spreadsheet::tsv = Text::CSV_XS->new({
		binary    => 1,
		auto_diag => 2,
		sep_char  => "\t",
		eol       => $/
		#quote_char => undef
	});

	my $fmt;
	if ($args{lang} eq 'jp') {
		use Spreadsheet::ParseExcel::FmtJapan;
		$fmt = Spreadsheet::ParseExcel::FmtJapan->new;
	}
	
	my $p = Spreadsheet::ParseExcel->new(
		CellHandler => \&cell_handler_s,
		NotSetCell  => 1
	)->parse(
		$self->{file},
		$fmt
	);
	die("failed to open *.xls file!\n") unless $p;

	sub cell_handler_s {
		my $workbook    = $_[0];
		my $sheet_index = $_[1];
		my $row         = $_[2];
		my $col         = $_[3];
		my $cell        = $_[4];
		
		$kh_spreadsheet::the_first_line = $row
			if $kh_spreadsheet::the_first_line == -1;
		
		$kh_spreadsheet::the_first_colm = $col
			if $kh_spreadsheet::the_first_colm == -1;
		
		if ($sheet_index > 0){
			$workbook->ParseAbort(1);
			return 1;
		}
		
		unless ($row == $kh_spreadsheet::row){
			&kh_spreadsheet::print_line;
			
			$kh_spreadsheet::line = undef;
			$kh_spreadsheet::row = $row;
		}
		
		$kh_spreadsheet::ncol = $col if
			$row == $kh_spreadsheet::the_first_line && $kh_spreadsheet::ncol < $col;
		$kh_spreadsheet::line->[$col] = $cell->value;
	}

	if ( $kh_spreadsheet::line ){
		&kh_spreadsheet::print_line;
	}

	close $kh_spreadsheet::fhv;
	close $kh_spreadsheet::fht;

	my $t1 = new Benchmark;
	print "Conv:\t",timestr(timediff($t1,$t0)),"\n";
	
	unlink $args{filev} if $kh_spreadsheet::ncol == 1;
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
