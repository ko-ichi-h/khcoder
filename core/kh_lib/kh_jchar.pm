package kh_jchar;
use strict;
use vars qw($converter);

BEGIN{
	if (eval 'require NKF'){
		$converter = 'nkf';
	}
	elsif( $] > 5.008 ){
		require Encode;
		$converter = 'encode';
	} else {
		use Jcode;
		$converter = 'jcode';
	}
	#print "Jcode conv: $converter\n";
}

# ƒtƒ@ƒCƒ‹ŠÛ‚²‚Æ•ÏŠ·

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
			$temp = kh_jchar->s2e($temp);
			print TEMP "$temp";
			$n = 0; $temp = '';
		}
		++$n;
	}
	if ($temp){
		$temp = kh_jchar->s2e($temp);
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
			$temp = kh_jchar->e2s($temp);
			print TEMP "$temp";
			$n = 0; $temp = '';
		}
		++$n;
	}
	if ($temp){
		$temp = kh_jchar->e2s($temp);
		print TEMP "$temp";
	}

	close (EUC);
	close (TEMP);
	unlink ("$sjistoeuc");
	rename ("temp.txt","$sjistoeuc");
}

# •¶Žš—ñ•ÏŠ·

sub s2e{
	my $conv = '_s2e_'.$kh_jchar::converter;
	kh_jchar->$conv($_[1]);
}
sub _s2e_nkf{
	return NKF::nkf('-e -S',$_[1]);
}
sub _s2e_encode{
	Encode::from_to($_[1],'shiftjis','euc-jp');
	return $_[1];
}
sub _s2e_jcode{
	return Jcode->new($_[1],'sjis')->euc;
}


sub e2s{
	my $conv = '_e2s_'.$kh_jchar::converter;
	kh_jchar->$conv($_[1]);
}
sub _e2s_nkf{
	return NKF::nkf('-s -E',$_[1]);
}
sub _e2s_encode{
	Encode::from_to($_[1],'euc-jp','shiftjis');
	return $_[1];
}
sub _e2s_jcode{
	return Jcode->new($_[1],'euc')->sjis;
}


1;
