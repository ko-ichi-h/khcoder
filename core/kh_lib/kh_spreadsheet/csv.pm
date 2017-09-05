package kh_spreadsheet::csv;

use strict;
use warnings;
use base 'kh_spreadsheet';

use Text::CSV_XS;

sub save_files{
	my $self = shift;
	my %args = @_;
	my $icode = $args{icode};

	use Benchmark;
	my $t0 = new Benchmark;

	# check character code
	my $jp = 1;
	if (defined $gui_window::project_new::lang){
		unless ($gui_window::project_new::lang eq 'jp'){
			$jp = 0;
		}
	} else {
		unless (
			   $::config_obj->c_or_j eq 'chasen'
			|| $::config_obj->c_or_j eq 'mecab'
		) {
			$jp = 0;
		}
	}
	unless ($icode) {
		if ($jp) {
			$icode = kh_jchar->check_code3( $self->{file}, 0, 200 );
		} else {
			$icode = kh_jchar->check_code_en( $self->{file}, 0, 200 );
		}
	}

	# morpho_analyzer (output)
	#my $icode_o;
	#if ($args{lang} eq 'jp') {
	#	$icode_o = 'cp932';
	#} else {
	#	$icode_o = 'utf8';
	#}
	open my $fht, ">::encoding(utf8)", $args{filet} or
		gui_errormsg->open(
			type => 'file',
			file => $args{filet}
		)
	;
	open my $fhv, ">::encoding(utf8)", $args{filev} or
		gui_errormsg->open(
			type => 'file',
			file => $args{filev}
		)
	;

	# for writing variable file
	my $tsv = Text::CSV_XS->new({
		binary    => 1,
		auto_diag => 2,
		sep_char  => "\t",
		eol       => $/
	});

	# open csv file
	my $csv = Text::CSV_XS->new ( { binary => 1, auto_diag => 2, allow_loose_quotes => 1 } );
	open my $fh, "<:encoding($icode)", $self->{file}
		or gui_errormsg->open(
			type => 'file',
			file => $self->{file}
		)
	;
	my $row_n = 0;
	while ( my $row = $csv->getline($fh) ){
		# text
		if ($row_n){
			my $t = $row->[$args{selected}];
			$t =~ tr/<>/()/;
			print $fht
				'<h5>---cell---</h5>',
				"\n",
				$t,
				"\n",
			;
		}
		# variables
		my $col_n = 0;
		my $line = undef;
		foreach my $col (@{$row}){
			if ($col_n == $args{selected}){
				++$col_n;
				next;
			}
			my $t = $col;
			$t = '.' if length($t) == 0;
			$t =~ s/[[:cntrl:]]//g;
			#if (length($t) > 127){
			#	$t = substr($t, 0, 127);
			#}
			push @{$line}, $t;
			++$col_n;
			if ($col_n == 1001){
				last;
			}
		}
		$tsv->print($fhv, $line) if $line;
		
		++$row_n;
	}

	close ($fh);
	close ($fht);
	close ($fhv);

	unlink($args{filev}) if -s $args{filev} == 0;
	
	my $t1 = new Benchmark;
	print "Conv:\t",timestr(timediff($t1,$t0)),"\n";

	return 1;
}

sub columns{
	my $self = shift;
	my $icode = shift;
	
	#use Benchmark;
	#my $t0 = new Benchmark;
	
	# check character code
	my $jp = 1;
	if (defined $gui_window::project_new::lang){
		unless ($gui_window::project_new::lang eq 'jp'){
			$jp = 0;
		}
	} else {
		unless (
			   $::config_obj->c_or_j eq 'chasen'
			|| $::config_obj->c_or_j eq 'mecab'
		) {
			$jp = 0;
		}
	}
	unless ($icode) {
		if ($jp) {
			$icode = kh_jchar->check_code3( $self->{file}, 0, 200 );
		} else {
			$icode = kh_jchar->check_code_en( $self->{file}, 0, 200 );
		}
	}

	# open csv file
	my $csv = Text::CSV_XS->new ( { binary => 1, auto_diag => 1 } );
	open my $fh, "<:encoding($icode)", $self->{file}
		or gui_errormsg->open(
			type => 'file',
			file => $self->{file}
		)
	;
	my $row = $csv->getline($fh);
	close($fh);

	#my $t1 = new Benchmark;
	#print "Get Columns:\t",timestr(timediff($t1,$t0)),"\n";

	return $row;
}

1;
