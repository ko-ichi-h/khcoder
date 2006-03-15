package kh_CheckDataFile;
use strict;
use Jcode;

sub exec{
	my $self;
	my $class        = shift;
	$self->{file_in} = shift;
	bless $self, $class;
	
	my $error_flag = 0;
	my $result = '';
	
	# ファイルの存在
	$result .= "target file\t".$self->{file_in}."\t";
	if (-e $self->{file_in}){
		$result .= "OK\n";
	} else {
		$result .= "NG\n";
		$error_flag = 1;
	}
	
	# 文字コード
	my $icode = kh_jchar->check_code($self->{file_in});
	$result .= "icode\t$icode\t";
	if ( ($icode) and not ($icode =~ /utf/i) ){
		$result .= "OK\n";
	} else {
		$result .= "NG\n";
	}

	my $length_a;
	my $length_h;
	open (SOURCE,"$self->{file_in}") or
		gui_errormsg->open(
			type => 'file',
			thefile => $self->{file_in}
		);
	binmode (SOURCE);
	while (<SOURCE>){
		chomp;
		my $text = Jcode->new($_,$icode)->h2z->euc;
		$text =~ s/ /　/go;
		# 行の長さ
		if (length($text) > $length_a){
			$length_a = length($text);
		}
		
		# 見出し行の長さ
		if (
			   ($text =~ /<h[1-5]>.+<\/h[1-5]>/io)
			&& (length($text) > $length_h) 
		){
			$length_h = length($text);
		}
	}
	close (SOURCE);
	
	
	print "$result";
	print "$length_a, $length_h\n";
	
	return 1;
}

1;