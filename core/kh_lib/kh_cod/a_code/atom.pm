package kh_cod::a_code::atom;
use strict;

use kh_cod::a_code::atom::delimit;
use kh_cod::a_code::atom::word;
use kh_cod::a_code::atom::code;
use kh_cod::a_code::atom::hinshi;
use kh_cod::a_code::atom::string;
use kh_cod::a_code::atom::number;
use kh_cod::a_code::atom::length;
use kh_cod::a_code::atom::outvar_o;
use kh_cod::a_code::atom::heading;
use kh_cod::a_code::atom::phrase;


BEGIN {
	use vars qw(@pattern);
	push @pattern, [
		kh_cod::a_code::atom::heading->pattern,
		kh_cod::a_code::atom::heading->name
	];
	push @pattern, [
		kh_cod::a_code::atom::outvar_o->pattern,
		kh_cod::a_code::atom::outvar_o->name
	];
	push @pattern, [
		kh_cod::a_code::atom::length->pattern,
		kh_cod::a_code::atom::length->name
	];
	push @pattern, [
		kh_cod::a_code::atom::number->pattern,
		kh_cod::a_code::atom::number->name
	];
	push @pattern, [
		kh_cod::a_code::atom::string->pattern,
		kh_cod::a_code::atom::string->name
	];
	push @pattern, [
		kh_cod::a_code::atom::hinshi->pattern,
		kh_cod::a_code::atom::hinshi->name
	];
	push @pattern, [
		kh_cod::a_code::atom::code->pattern,
		kh_cod::a_code::atom::code->name
	];
	push @pattern, [
		kh_cod::a_code::atom::phrase->pattern,
		kh_cod::a_code::atom::phrase->name
	];
	push @pattern, [
		kh_cod::a_code::atom::delimit->pattern,
		kh_cod::a_code::atom::delimit->name
	];
	push @pattern, [
		kh_cod::a_code::atom::word->pattern,
		kh_cod::a_code::atom::word->name
	];
}

sub new{
	my $self;
	my $class = shift;
	$self->{raw} = shift;
	
	foreach my $i (@pattern){
		if ($self->{raw} =~ /$i->[0]/){
			# print Jcode->new("$self->{raw}, $i->[1]\n")->sjis;
			$class .= '::'."$i->[1]";
			last;
		}
	}
	
	bless $self, $class;
	$self->when_read;
	return $self;
}

sub num_expr{
	my $self = shift;
	return $self->expr;
}

sub clear{
	return 1;
}

sub raw{
	my $self = shift;
	return $self->{raw};
}

sub when_read{
	return 1;
}
sub hyosos{
	return undef;
}


1;