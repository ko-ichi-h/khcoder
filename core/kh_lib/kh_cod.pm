package kh_cod;
use strict;
use Jcode;

use gui_errormsg;
use mysql_exec;
use kh_cod::a_code;
use kh_cod::func;

use vars(%kh_cod::reading);

#----------------------#
#   コーディング実行   #

sub code{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;
	
	unless ($self->{codes}){
		return 0;
	}
	
	my $n = 0;
	foreach my $i (@{$self->{codes}}){
		my $res_table = "ct_$tani"."_code_$n";
		++$n;
		$i->ready($tani) or next;
		$i->code($res_table);
		if ($i->res_table){ push @{$self->{valid_codes}}, $i; }
		
	}
	
	return $self;
}

#----------------------------#
#   ルールファイル読み込み   #

sub read_file{
	my $self;
	my $class = shift;
	my $file = shift;

	# 文字コード判別
	open (FC,"$file") or 
		gui_errormsg->open(
			type => 'file',
			thefile => $file
		);
	my $check = '';
	while (<FC>){
		$check .= $_;
	}
	close (FC);
	my $icode = Jcode->new($check)->icode;
	$check = '';
	#print "$icode\n";
	
	open (F,"$file") or 
		gui_errormsg->open(
			type => 'file',
			thefile => $file
		);
	
	# 読みとり
	my (@codes, %codes, $head);
	while (<F>){
		$_ =~ s/\r\n\z/\n/o;
		chomp;
		if ((substr($_,0,1) eq '#') || (length($_) == 0)){
			next;
		}
		
		$_ = Jcode->new("$_",$icode)->euc;
		if ($_ =~ /^＊/o){
			$head = $_;
			push @codes, $head;
			#print Jcode->new("$head\n")->sjis;
		} else {
			$codes{$head} .= "$_\n";
		}
	}
	close (F);
	
	# 解釈
	foreach my $i (@codes){
		# print Jcode->new("code: $i\n")->sjis;
		my $c = kh_cod::a_code->new($i,$codes{$i});
		push @{$self->{codes}}, $c;
		$kh_cod::reading{$i} =  $c;
	}
	# リセット
	%kh_cod::reading = ();
	kh_cod::a_code::atom::code->reset;
	kh_cod::a_code::atom::string->reset;
	
	unless ($self){
		gui_errormsg->open(
			type => 'msg',
			msg  =>
				"選択されたファイルはコーディング・ルール・ファイルに見えません。"
		);
		return 0;
	}
	
	bless $self, $class;
	return $self;
}

#--------------------------------------------#
#   コーディング結果格納テーブルをまとめる   #
#--------------------------------------------#
sub cumulate{
	my $self = shift;
	my $salt = shift;
	
	my $cnt = 0;
	my $cycle = 0;
	my @temp;
	foreach my $i (@{$self->valid_codes}){
		push @temp, $i;
		++$cnt;
		if ($cnt == 30){
			$self->_cumulate(\@temp,$cycle,$salt);
			$cnt = 0;
			@temp = ();
			++$cycle;
		}
	}
	if (@temp){
		$self->_cumulate(\@temp,$cycle,$salt);
	}
	
	return 1;
}

sub _cumulate{
	my $self  = shift;
	my $codes = shift;
	my $n     = shift;
	my $salt  = shift;
	
	my $table = "ct_$self->{tani}_$salt"."code_cum_$n";
	#print "$table\n";
	
	# テーブル作成
	mysql_exec->drop_table($table);
	my $sql = "CREATE TABLE $table (\n";
	$sql .= "	id int not null primary key,\n";
	$n = 0;
	my $col_list;
	foreach my $i (@{$codes}){
		$sql .= "	c$n int,\n";
		$col_list .= "c$n,";
		++$n;
	}
	chop $sql; chop $sql; $sql .= "\n";
	chop $col_list;
	$sql .= ") type = heap";
	mysql_exec->do("$sql",1);
	
	# Insert
	$sql = "";
	$sql .= "INSERT INTO $table (id,$col_list)\n";
	$sql .= "SELECT $self->{tani}.id, ";
	foreach my $i (@{$codes}){
		$sql .= $i->res_table.'.'.$i->res_col.',';
	}
	chop $sql;
	$sql .= "\n";
	$sql .= "FROM $self->{tani}\n";
	foreach my $i (@{$codes}){
		$sql .= '	LEFT JOIN '.$i->res_table.' ON '.$i->res_table.".id = $self->{tani}.id\n";
	}
	$sql .= "WHERE\n";
	$n = 0;
	foreach my $i (@{$codes}){
		$sql .= "OR " if $n;
		$sql .= $i->res_table.'.'.$i->res_col."\n";
		++$n;
	}
	mysql_exec->do("$sql",1);
	
	# 新しいテーブル・カラム名をセット
	$n = 0;
	foreach my $i (@{$codes}){
		$i->res_table($table);
		$i->res_col("c$n");
		++$n;
	}
}

#--------------#
#   アクセサ   #

sub tables{                         # コーディング結果を納めたテーブルのリスト
	my $self = shift;
	my @r;
	
	return 0 unless $self->valid_codes;
	
	my %check;
	foreach my $i (@{$self->valid_codes}){
		next if $check{$i->res_table};
		push @r, $i->res_table;
		$check{$i->res_table} = 1;
	}
	return \@r;
}

sub valid_codes{
	my $self = shift;
	return $self->{valid_codes};
}

sub codes{
	my $self = shift;
	return $self->{codes};
}

sub tani{
	my $self = shift;
	return $self->{tani};
}

1;
