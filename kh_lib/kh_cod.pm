package kh_cod;
use strict;
use Jcode;

use gui_errormsg;
use kh_cod::a_code;

sub count{
	my $self = shift;
	my $tani = shift;
	
	unless ($self->{codes}){
		return 0;
	}
	
	foreach my $i (@{$self->{codes}}){
		$i->ready($tani);
		print Jcode->new($i->name.": ".$i->count($tani)."\n")->sjis;
	}
}


sub read_file{
	my $self;
	my $class = shift;
	my $file = shift;
	
	open (F,"$file") or 
		gui_errormsg->open(
			type => 'file',
			thefile => $file
		);
	
	# 読みとり
	my (@codes, %codes, $head);
	while (<F>){
		if ((substr($_,0,1) eq '#') || (length($_) == 0)){
			next;
		}
		
		$_ = Jcode->new("$_")->euc;
		if ($_ =~ /^＊/o){
			chomp;
			$head = $_;
			push @codes, $head;
			#print Jcode->new("$head\n")->sjis;
		} else {
			$codes{$head} .= $_;
		}
	}
	close (F);
	
	# 解釈
	foreach my $i (@codes){
		print Jcode->new("code: $i\n")->sjis;
		#print "in: $codes{$i}\n";
		push @{$self->{codes}}, kh_cod::a_code->new($i,$codes{$i});
	}
	
	bless $self, $class;
	return $self;
}


1;
