package kh_jchar;
use strict;
use NKF;

sub to_euc{
	my $sjistoeuc = $_[1];
	open (EUC,"$sjistoeuc")
		or &gui_errormsg->open(type => 'file',thefile => "$sjistoeuc");
	open (TEMP,">temp.txt")
		or &gui_errormsg->open(type => 'file',thefile => 'temp.txt');
	my $n = 0; my $temp = '';
	while (<EUC>){
		$temp .= $_;
		if ($n == 1000){
			$temp = nkf('-e -S',$temp);
			print TEMP "$temp";
			$n = 0; $temp = '';
		}
		++$n;
	}
	if ($temp){
		$temp = nkf('-e -S',$temp);
		print TEMP "$temp";
	}

	close (EUC);
	close (TEMP);
	unlink ("$sjistoeuc");
	rename ("temp.txt","$sjistoeuc");
}

sub to_sjis{
	my $sjistoeuc = $_[1];
	open (EUC,"$sjistoeuc")
		or &gui_errormsg->open(type => 'file',thefile => "$sjistoeuc");
	open (TEMP,">temp.txt")
		or &gui_errormsg->open(type => 'file',thefile => 'temp.txt');
	my $n = 0; my $temp = '';
	while (<EUC>){
		$temp .= $_;
		if ($n == 1000){
			$temp = nkf('-s -E',$temp);
			print TEMP "$temp";
			$n = 0; $temp = '';
		}
		++$n;
	}
	if ($temp){
		$temp = nkf('-s -E',$temp);
		print TEMP "$temp";
	}

	close (EUC);
	close (TEMP);
	unlink ("$sjistoeuc");
	rename ("temp.txt","$sjistoeuc");
}

1;
