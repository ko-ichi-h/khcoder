package kh_spreadsheet::csv;

use strict;
use warnings;
use base 'kh_spreadsheet';

use Text::CSV_XS;

sub save_files{
	my $self = shift;
	my %args = @_;

	# check character code
	my $icode = $args{icode};
	unless ($icode) {
		if (
			   $::config_obj->c_or_j eq 'chasen'
			|| $::config_obj->c_or_j eq 'mecab'
		) {
			$icode = kh_jchar->check_code2( $self->{file}, 0, 200 );
		} else {
			$icode = kh_jchar->check_code_en( $self->{file}, 0, 200 );
		}
	}

	# morpho_analyzer (output)
	my $icode_o;
	if ($args{lang} eq 'jp') {
		$icode_o = 'cp932';
	} else {
		$icode_o = 'utf8';
	}
	open my $fht, ">::encoding($icode_o)", $args{filet} or
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

	# open csv file
	my $csv = Text::CSV_XS->new ( { binary => 1, auto_diag => 1 } );
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
		my $line = '';
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
			$line .= "$t\t";
			++$col_n;
			if ($col_n == 1001){
				last;
			}
		}
		chop $line;
		print $fhv "$line\n";
		
		++$row_n;
	}

	close ($fh);
	close ($fht);
	close ($fhv);

	return 1;
}

sub columns{
	my $self = shift;
	my $icode = shift;
	
	use Benchmark;
	my $t0 = new Benchmark;
	
	# check character code
	unless ($icode) {
		if (
			   $::config_obj->c_or_j eq 'chasen'
			|| $::config_obj->c_or_j eq 'mecab'
		) {
			$icode = kh_jchar->check_code2( $self->{file}, 0, 200 );
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

	my $t1 = new Benchmark;
	print "Get Columns:\t",timestr(timediff($t1,$t0)),"\n";

	return $row;
}

1;
