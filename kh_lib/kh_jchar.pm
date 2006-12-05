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
	# print "Jcode conv: $converter\n";
}

# ファイル丸ごと変換

sub to_euc{
	my $sjistoeuc = $_[1];
	
	my $temp_file = 'temp.txt';
	while (-e $temp_file){
		$temp_file .= '.tmp';
	}
	#print "kh_jachar temp-file: $temp_file\n";
	
	open (EUC,"$sjistoeuc")
		or &gui_errormsg->open(type => 'file',thefile => "$sjistoeuc");
	open (TEMP,">$temp_file")
		or &gui_errormsg->open(type => 'file',thefile => "$temp_file");
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
	rename ("$temp_file","$sjistoeuc");
}

sub to_sjis{
	my $sjistoeuc = $_[1];

	my $temp_file = 'temp.txt';
	while (-e $temp_file){
		$temp_file .= '.tmp';
	}
	#print "kh_jachar temp-file: $temp_file\n";

	open (EUC,"$sjistoeuc")
		or &gui_errormsg->open(type => 'file',thefile => "$sjistoeuc");
	open (TEMP,">$temp_file")
		or &gui_errormsg->open(type => 'file',thefile => "$temp_file");
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
	rename ("$temp_file","$sjistoeuc");
}

# ファイルの文字コードを判別

sub check_code{
	my $the_file = $_[1];
	
	if ( defined($::project_obj) ){
		my $chk = $::project_obj->assigned_icode;
		if (
			   ( $::project_obj->file_target eq $the_file )
			&& ( $chk )
		) {
			return $chk;
		}
	}
	#print "checking icode...\n";
	
	open (TEMP,$the_file)
		or &gui_errormsg->open(type => 'file',thefile => $the_file);
	my $n = 0;
	my $t;
	while (<TEMP>){
		$t .= $_;
		++$n;
		last if $n > 1000;
	}
	close (TEMP);
	use Jcode;
	my $icode = Jcode->new($t)->icode;
	print "char-set detection: $icode\n";
	return $icode;
}

# 文字列変換

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
