package kh_cod::a_code;
use kh_cod::a_code::atom;
use strict;

sub count{
	my $self = shift;
	my $tani = shift;
	unless ($self->{condition}){
		return 0;
	}
	
	my $sql = "SELECT count(*)\n";
	$sql .= "FROM $tani\n";
	foreach my $i ($self->tables){
		$sql .= "\tLEFT JOIN $i ON $tani.id = $i.id\n";
	}
	$sql .= "WHERE\n";
	foreach my $i (@{$self->{condition}}){
		$sql .= "\t".$i->expr."\n";
	}
	
	return mysql_exec->select($sql,1)->hundle->fetch->[0];
}

sub tables{
	my $self = shift;
	unless ($self->{condition}){
		return 0;
	}
	my @t;
	foreach my $i (@{$self->{condition}}){
		my $at = $i->tables;
		unless ($at){next;}
		foreach my $h (@{$at}){
			push @t, $h;
		}
	}
	return @t;
}

sub ready{
	my $self = shift;
	my $tani = shift;
	unless ($self->{condition}){
		return 0;
	}
	
	foreach my $i (@{$self->{condition}}){
		$i->ready($tani);
	}
}

sub new{
	my $self;
	my $class = shift;
	$self->{name} = shift;
	$self->{row_condition} = shift;
	
	my $condition = Jcode->new($self->{row_condition},'euc')->tr('¡¡',' ');
	$condition =~ tr/\t\n/  /;
	my @temp = split / /, $condition;
	
	foreach my $i (@temp){
		unless ( length($i) ){next;}
		push @{$self->{condition}}, kh_cod::a_code::atom->new($i);
	}
	
	bless $self, $class;
	return $self;
}

sub name{
	my $self = shift;
	return $self->{name};
}




1;