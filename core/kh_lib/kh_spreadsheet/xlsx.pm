package kh_spreadsheet::xlsx;

use strict;
use warnings;
use base 'kh_spreadsheet';

use Encode;
use Archive::Zip qw( :ERROR_CODES );
use Spreadsheet::ParseXLSX;
use Spreadsheet::ParseExcel::FmtJapan;

no warnings 'redefine';
*Spreadsheet::ParseExcel::FmtJapan::TextFmt    = \&TextFmt;
*Spreadsheet::ParseXLSX::_parse_shared_strings = \&_parse_shared_strings;
*Spreadsheet::ParseXLSX::_parse_sheet          = \&_parse_sheet;
*Spreadsheet::ParseXLSX::_extract_files        = \&_extract_files;
use warnings 'redefine';

use vars qw(@col);

sub columns{
	my $self = shift;
	@kh_spreadsheet::xlsx::col = ();

	my $p = Spreadsheet::ParseXLSX->new;
	$p->{NotSetCell} = 1;
	$p->{CellHandler} = \&cell_handler_c;
	$p->parse(
		$self->{file},
		Spreadsheet::ParseExcel::FmtJapan->new
	);

	sub cell_handler_c{
		my $self  = $_[0];
		my $row   = $_[1];
		my $col   = $_[2];
		my $cell  = $_[3];
		
		if ($row > 0){
			$self->{_ParseAbort} = 1 ;
			return $self;
		}
		
		push @kh_spreadsheet::xlsx::col, $cell->value;
		return $self;
	}

	return \@kh_spreadsheet::xlsx::col;
}

sub save_files{
	my $self = shift;
	my %args = @_;

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
	$kh_spreadsheet::ncol = 0;
	$kh_spreadsheet::selected = $args{selected};

	use Text::CSV_XS;
	$kh_spreadsheet::tsv = Text::CSV_XS->new({
		binary    => 1,
		auto_diag => 2,
		sep_char  => "\t",
		eol       => $/
		#quote_char => undef
	});

	my $p = Spreadsheet::ParseXLSX->new;
	$p->{NotSetCell} = 1;
	$p->{CellHandler} = \&cell_handler_s;
	$p->parse(
		$self->{file},
		Spreadsheet::ParseExcel::FmtJapan->new
	);
	die("failed to open *.xlsx file!\n") unless $p;

	sub cell_handler_s {
		my $self = $_[0];
		my $row  = $_[1];
		my $col  = $_[2];
		my $cell = $_[3];
		
		unless ($row == $kh_spreadsheet::row){
			&kh_spreadsheet::print_line;
			
			$kh_spreadsheet::line = undef;
			$kh_spreadsheet::row = $row;
		}
		
		++$kh_spreadsheet::ncol if $row == 0;
		$kh_spreadsheet::line->[$col] = $cell->value;
		
		return $self;
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


#-----------------------------------------------------------------------------#
#           Spreadsheet::ParseXLSX modifications for larger files             #
#-----------------------------------------------------------------------------#

sub _extract_files {
    my $self = shift;
    my ($zip) = @_;

    my $type_base =
        'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

    my $rels = $self->_parse_xml(
        $zip,
        $self->_rels_for('')
    );
    my $wb_name = ($rels->find_nodes(
        qq<//Relationship[\@Type="$type_base/officeDocument"]>
    ))[0]->att('Target');
    my $wb_xml = $self->_parse_xml($zip, $wb_name);

    my $path_base = $self->_base_path_for($wb_name);
    my $wb_rels = $self->_parse_xml(
        $zip,
        $self->_rels_for($wb_name)
    );

    my ($strings_xml) = map {
        $zip->memberNamed($path_base . $_->att('Target'))->contents
    } $wb_rels->find_nodes(qq<//Relationship[\@Type="$type_base/sharedStrings"]>);

    my $styles_xml = $self->_parse_xml(
        $zip,
        $path_base . ($wb_rels->find_nodes(
            qq<//Relationship[\@Type="$type_base/styles"]>
        ))[0]->att('Target')
    );

	# kh coder: Extract the file to Disk, not memory
	my %worksheet_xml = map {
		if (
			$zip->extractMemberWithoutPaths(
				$zip->memberNamed($path_base . $_->att('Target')),
				"config/".$_->att('Target')
			) == AZ_OK
		){
			( $_->att('Id') => "config/".$_->att('Target') );
		}
	} $wb_rels->find_nodes(qq<//Relationship[\@Type="$type_base/worksheet"]>);

    my %themes_xml = map {
        $_->att('Id') => $self->_parse_xml($zip, $path_base . $_->att('Target'))
    } $wb_rels->find_nodes(qq<//Relationship[\@Type="$type_base/theme"]>);

    return {
        workbook => $wb_xml,
        styles   => $styles_xml,
        sheets   => \%worksheet_xml,
        themes   => \%themes_xml,
        ($strings_xml
            ? (strings => $strings_xml)
            : ()),
    };
}


sub _parse_sheet {
    my $self = shift;
    my ($sheet, $sheet_file) = @_;

	if ($self->{_ParseAbort}) {   # kh coder: read the 1st sheet only!
		unlink( $sheet_file );    # kh coder
		return $sheet;            # kh coder
	}                             # kh coder

    $sheet->{MinRow} = 0;
    $sheet->{MinCol} = 0;
    $sheet->{MaxRow} = -1;
    $sheet->{MaxCol} = -1;
    $sheet->{Selection} = [ 0, 0 ];

    my @merged_cells;

    my @column_formats;
    my @column_widths;
    my @row_heights;

    my $default_row_height   = 15;
    my $default_column_width = 10;

    my $sheet_xml = XML::Twig->new(
        twig_roots => {
            #XXX need a fallback here, the dimension tag is optional
            'dimension' => sub {
                my ($twig, $dimension) = @_;

                my ($rmin, $cmin, $rmax, $cmax) = $self->_dimensions(
                    $dimension->att('ref')
                );

                $sheet->{MinRow} = $rmin;
                $sheet->{MinCol} = $cmin;
                $sheet->{MaxRow} = $rmax ? $rmax : -1;
                $sheet->{MaxCol} = $cmax ? $cmax : -1;

                $twig->purge;
            },

            'headerFooter' => sub {
                my ($twig, $hf) = @_;

                my ($helem, $felem) = map {
                    $hf->first_child($_)
                } qw(oddHeader oddFooter);
                $sheet->{Header} = $helem->text
                    if $helem;
                $sheet->{Footer} = $felem->text
                    if $felem;

                $twig->purge;
            },

            'pageMargins' => sub {
                my ($twig, $margin) = @_;
                map {
                    my $key = "\u${_}Margin";
                    $sheet->{$key} = $margin->att($_) // 0
                } qw(left right top bottom header footer);

                $twig->purge;
            },

            'pageSetup' => sub {
                my ($twig, $setup) = @_;
                $sheet->{Scale} = $setup->att('scale') // 100;
                $sheet->{Landscape} = ($setup->att('orientation') // '') ne 'landscape';
                $sheet->{PaperSize} = $setup->att('paperSize') // 1;
                $sheet->{PageStart} = $setup->att('firstPageNumber');
                $sheet->{UsePage} = $self->_xml_boolean($setup->att('useFirstPageNumber'));
                $sheet->{HorizontalDPI} = $setup->att('horizontalDpi');
                $sheet->{VerticalDPI} = $setup->att('verticalDpi');

                $twig->purge;
            },

            'mergeCells/mergeCell' => sub {
                my ( $twig, $merge_area ) = @_;

                if (my $ref = $merge_area->att('ref')) {
                    my ($topleft, $bottomright) = $ref =~ /([^:]+):([^:]+)/;

                    my ($toprow, $leftcol)     = $self->_cell_to_row_col($topleft);
                    my ($bottomrow, $rightcol) = $self->_cell_to_row_col($bottomright);

                    push @{ $sheet->{MergedArea} }, [
                        $toprow, $leftcol,
                        $bottomrow, $rightcol,
                    ];
                    for my $row ($toprow .. $bottomrow) {
                        for my $col ($leftcol .. $rightcol) {
                            push(@merged_cells, [$row, $col]);
                        }
                    }
                }

                $twig->purge;
            },

            'sheetFormatPr' => sub {
                my ( $twig, $format ) = @_;

                $default_row_height   //= $format->att('defaultRowHeight');
                $default_column_width //= $format->att('baseColWidth');

                $twig->purge;
            },

            'col' => sub {
                my ( $twig, $col ) = @_;

                for my $colnum ($col->att('min')..$col->att('max')) {
                    $column_widths[$colnum - 1] = $col->att('width');
                    $column_formats[$colnum - 1] = $col->att('style');
                }

                $twig->purge;
            },

            'row' => sub {
                my ( $twig, $row ) = @_;

                $row_heights[ $row->att('r') - 1 ] = $row->att('ht');

                $twig->purge;
            },

            'selection' => sub {
                my ( $twig, $selection ) = @_;

                if (my $cell = $selection->att('activeCell')) {
                    $sheet->{Selection} = [ $self->_cell_to_row_col($cell) ];
                }
                elsif (my $range = $selection->att('sqref')) {
                    my ($topleft, $bottomright) = $range =~ /([^:]+):([^:]+)/;
                    $sheet->{Selection} = [
                        $self->_cell_to_row_col($topleft),
                        $self->_cell_to_row_col($bottomright),
                    ];
                }

                $twig->purge;
            },

            'sheetPr/tabColor' => sub {
                my ( $twig, $tab_color ) = @_;

                $sheet->{TabColor} = $self->_color($sheet->{_Book}{Color}, $tab_color);

                $twig->purge;
            },

        }
    );

    #$sheet_xml->parse( $sheet_file ); # kh coder: we assume no merged cells!

    # 2nd pass: cell/row building is dependent on having parsed the merge definitions
    # beforehand.

    $sheet_xml = XML::Twig->new(
        twig_roots => {
            'sheetData/row' => sub {
                my ( $twig, $row_elt ) = @_;

				$twig->finish_now if $self->{_ParseAbort}; # kh coder

                for my $cell ( $row_elt->children('c') ){
                    my ($row, $col) = $self->_cell_to_row_col($cell->att('r'));
                    $sheet->{MaxRow} = $row
                        if $sheet->{MaxRow} < $row;
                    $sheet->{MaxCol} = $col
                        if $sheet->{MaxCol} < $col;
                    my $type = $cell->att('t') || 'n';
                    my $val_xml;
                    if ($type ne 'inlineStr') {
                        $val_xml = $cell->first_child('v');
                    }
                    elsif (defined $cell->first_child('is')) {
                        $val_xml = ($cell->find_nodes('.//t'))[0];
                    }
                    my $val = $val_xml ? $val_xml->text : undef;

                    my $long_type;
                    if (!defined($val)) {
                        $long_type = 'Text';
                        $val = '';
                    }
                    elsif ($type eq 's') {
                        $long_type = 'Text';
                        $val = $sheet->{_Book}{PkgStr}[$val];
                    }
                    elsif ($type eq 'n') {
                        $long_type = 'Numeric';
                        $val = defined($val) ? 0+$val : undef;
                    }
                    elsif ($type eq 'd') {
                        $long_type = 'Date';
                    }
                    elsif ($type eq 'b') {
                        $long_type = 'Text';
                        $val = $val ? "TRUE" : "FALSE";
                    }
                    elsif ($type eq 'e') {
                        $long_type = 'Text';
                    }
                    elsif ($type eq 'str' || $type eq 'inlineStr') {
                        $long_type = 'Text';
                    }
                    else {
                        die "unimplemented type $type"; # XXX
                    }

                    my $format_idx = $cell->att('s') || 0;
                    my $format = $sheet->{_Book}{Format}[$format_idx];
                    $format->{Merged} = !!grep {
                        $row == $_->[0] && $col == $_->[1]
                    } @merged_cells;

                    # see the list of built-in formats below in _parse_styles
                    # XXX probably should figure this out from the actual format string,
                    # but that's not entirely trivial
                    if (grep { $format->{FmtIdx} == $_ } 14..22, 45..47) {
                        $long_type = 'Date';
                    }

                    my $cell = Spreadsheet::ParseExcel::Cell->new(
                        Val      => $val,
                        Type     => $long_type,
                        Merged   => $format->{Merged},
                        Format   => $format,
                        FormatNo => $format_idx,
                        ($cell->first_child('f')
                            ? (Formula => $cell->first_child('f')->text)
                            : ()),
                    );
                    $cell->{_Value} = $sheet->{_Book}{FmtClass}->ValFmt(
                        $cell, $sheet->{_Book}
                    );
                    $sheet->{Cells}[$row][$col] = $cell
                        unless $self->{NotSetCell};  # kh coder
                    $self = $self->{CellHandler}->(  # kh coder
                    	$self, $row, $col, $cell     # kh coder
                    );                               # kh coder
                }

                $twig->purge;
            },

        }
    );

    $sheet_xml->parsefile( $sheet_file ); # kh coder: read from file not memory
    unlink( $sheet_file );                # kh coder
    $self->{_ParseAbort} = 1;             # kh coder: read the 1st sheet only!

    if ( ! $sheet->{Cells} ){
        $sheet->{MaxRow} = $sheet->{MaxCol} = -1;
    }

    $sheet->{DefRowHeight} = 0+$default_row_height;
    $sheet->{DefColWidth} = 0+$default_column_width;
    $sheet->{RowHeight} = [
        map { defined $_ ? 0+$_ : 0+$default_row_height } @row_heights
    ];
    $sheet->{ColWidth} = [
        map { defined $_ ? 0+$_ : 0+$default_column_width } @column_widths
    ];
    $sheet->{ColFmtNo} = \@column_formats;

}

#-----------------------------------------------------------------------------#
#                              Minor modifications                            #
#-----------------------------------------------------------------------------#

sub TextFmt {
    my ( $self, $text, $input_encoding ) = @_;
    if(!defined $input_encoding){
        $input_encoding = 'utf8';
    }
    elsif($input_encoding eq '_native_'){ 
        $input_encoding = 'cp932'; # Shift_JIS in Microsoft products
    }
    $text = decode($input_encoding, $text)
    	unless utf8::is_utf8($text); # kh coder
    return $self->{Code} ? $self->{encoding}->encode($text) : $text;
}

sub _parse_shared_strings {
    my $self = shift;
    my ($strings) = @_;

	$strings =~ s!<rPh[^>]*>.*?</rPh>!!gsmo; # kh coder

    my $PkgStr = [];

    if ($strings) {
        my $xml = XML::Twig->new(
            twig_handlers => {
                'si' => sub {
                    my ( $twig, $si ) = @_;

                    # XXX this discards information about formatting within cells
                    # not sure how to represent that
                    push @$PkgStr,
                      join( '', map { $_->text } $si->find_nodes('.//t') );
                    $twig->purge;
                },
            }
        );
        $xml->parse( $strings );
    }
    return $PkgStr;
}

1;
