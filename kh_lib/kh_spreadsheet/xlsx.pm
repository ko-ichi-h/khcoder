package kh_spreadsheet::xlsx;

use strict;
use warnings;
use base 'kh_spreadsheet';

use Spreadsheet::ParseXLSX;

use Spreadsheet::ParseExcel::FmtJapan;

no warnings 'redefine';
*Spreadsheet::ParseExcel::FmtJapan::TextFmt = \&TextFmt;
*Spreadsheet::ParseXLSX::_parse_shared_strings = \&_parse_shared_strings;
use warnings 'redefine';

sub parser{
	my $self = shift;
	
	if (
		   $::config_obj->c_or_j eq 'chasen'
		|| $::config_obj->c_or_j eq 'mecab'
	){
		return Spreadsheet::ParseXLSX->new->parse(
			$self->{file},
			Spreadsheet::ParseExcel::FmtJapan->new(Code => 'utf8')
		);
	} else {
		return Spreadsheet::ParseXLSX->new->parse($self->{file});
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

# MODs for existing modules

sub _parse_shared_strings {
    my $self = shift;
    my ($strings) = @_;

	$strings =~ s!<rPh[^>]*>.*?</rPh>!!gsm; # kh coder

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

1;
