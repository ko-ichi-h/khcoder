package mysql_contxt::tab;
use base qw(mysql_contxt);
use strict;

sub save{
	my $self = shift;
	$self->{file_save} = shift;

	#--------------------------#
	#   データファイルの出力   #
	
	my $file_data = $self->data_file;
	open (DOUT,'>encoding(utf8)', $file_data) or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "$file_data",
		);
	my $n = 1;
	foreach my $i (@{$self->{wList}}){
	print "\rout, $n.";
		# 各単位の集計を合算
		my %line;
		foreach my $t (@{$self->{tani}}){
			my $table = 'ct_'."$t->[0]".'_contxt_'."$i";
			# 文書数（分母の取得）
			my $r_num_hdl = mysql_exec->select("
				SELECT num
				FROM   $table
				WHERE  word = -1
			",1)->hundle->fetch;
			my $r_num;
			if ($r_num_hdl){
				$r_num = $r_num_hdl->[0];
			} else {
				next;
			}
			# 期待値計算（割り算＆重み付け）
			my $sth = mysql_exec->select("
				SELECT word, num
				FROM   $table
				WHERE  word > 0
			",1)->hundle;
			while (my $r = $sth->fetch){
				$line{$r->[0]} += ($r->[1] / $r_num) * $t->[1];
			}
			$sth->finish;
		}
		# 書き出し
		my $line =
			$self->{wName}{$i}
			.'('
			."$self->{wNum}{$i}"
			.')'
			."\t"
		;
		foreach my $w2 (@{$self->{wList2}}){
			if ($line{$w2}){
				#$line .= sprintf("%.8f",$line{$w2}).',';
				$line .= "$line{$w2}\t";
			} else {
				$line .= "0\t";
			}
		}
		chop $line;
		print DOUT "$line\n";
		++$n;
	}
	print "\n";
	close DOUT;

	$self->_save_finish;
}


#---------------------#
#   1行目を付け足す   #

sub _save_finish{
	my $self = shift;
	
	use kh_csv;
	my $first_line = kh_msg->gget('words')."\t";
	foreach my $w2 (@{$self->{wList2}}){
		$first_line .= 'cw: '.kh_csv->value_conv_t($self->{wName2}{$w2})."\t";
	}
	chop $first_line;
	
	my $file = $self->data_file;
	my $file_tmp = "$file".".bak";
	
	open (OLD,'<:encoding(utf8)', $file) or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "$file",
		);
	open (NEW,'>:encoding(utf8)', $file_tmp) or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$file_tmp",
		);
	print NEW "$first_line\n";
	while (<OLD>){
		print NEW $_;
	}
	close (NEW);
	close (OLD);
	unlink($file);
	rename($file_tmp,$file);

}

#--------------#
#   アクセサ   #
#--------------#

sub data_file{
	my $self = shift;
	return $self->{file_save};
}


1;