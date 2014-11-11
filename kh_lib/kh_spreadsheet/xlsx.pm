package kh_spreadsheet::xlsx;

use strict;
use warnings;
use base 'kh_spreadsheet';

use Spreadsheet::ParseXLSX;

no warnings 'redefine';
*Spreadsheet::ParseXLSX::_parse_shared_strings = \&_parse_shared_strings;
use warnings 'redefine';

sub _parse_shared_strings {
	my $self = shift;
	my ($strings) = @_;

	return [
		map {
			my $node = $_;
			# XXX this discards information about formatting within cells
			# not sure how to represent that
			#{ Text => join('', map { $_->text } $node->find_nodes('.//t')) }
			{ Text => &remove_rph_text($node) }
		} $strings->find_nodes('//si')
	];
}

sub remove_rph_text {
	my $node = shift;

	# no Yomi-Gana
	my @rph = $node->find_nodes('.//rPh');
	unless (@rph){
		return join('', map { $_->text } $node->find_nodes('.//t'));
	}

	# exclude Yomi-Gana
	my $t = '';
	my @t = $node->find_nodes('.//t');

	my %check = ();                     # Yomi-Gana
	foreach my $h (@rph){
		$check{$h->text} = 1;
	}
	
	foreach my $i (@t){                 # Text
		my $c = $i->text;
		$t .= $c unless $check{$c};
	}
	return $t;
}

sub parser{
	return Spreadsheet::ParseXLSX->new;
}

1;
