package mysql_contxt::spss;
use base qw(mysql_contxt);
use strict;

#--------------------------------#
#   シンタックスファイルの出力   #

sub _save_finish{
	my $self = shift;
	my $file_data   = $self->data_file;
	my $file_syntax = $self->synt_file;
	
	# 変数定義
	my $spss;
	$spss .= "file handle trgt1 /name=\'$file_data\'\n";
	$spss .= "                 /lrecl=32767 .\n";
	$spss .= "data list list(',') file=trgt1 /\n";
	$spss .= "  word(A255)\n";
	my $n = 0;
	foreach my $w2 (@{$self->{wList2}}){
		$spss .= "  cw$n(F10.8)\n";
		++$n;
	}
	$spss .= ".\nexecute.\n";

	# 変数ラベル
	$n = 0;
	$spss .= "variable labels\n";
	$spss .= "  word \'抽出語\'\n";
	foreach my $w2 (@{$self->{wList2}}){
		$spss .= "  cw$n \'cw: $self->{wName2}{$w2}\'\n";
		++$n;
	}
	$spss .= ".\nexecute.";

	open (SOUT,">$file_syntax") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "$file_syntax",
		);
	print SOUT $spss;
	close (SOUT);
	kh_jchar->to_sjis($file_syntax);
}


#--------------#
#   アクセサ   #
#--------------#

sub data_file{
	my $self = shift;
	return substr($self->{file_save},0,length($self->{file_save})-4).".dat";
}
sub synt_file{
	my $self = shift;
	return $self->{file_save};
}
1;