package kh_cod;
use strict;
use Jcode;

use gui_errormsg;
use kh_cod::a_code;

sub count{
	my $self = shift;
	my $tani = shift;
	
	$self->code($tani) or return 0;
	
	# 総数を取得
	my $total = mysql_exec->select("select count(*) from $tani",1)
		->hundle->fetch->[0];
	
	# 各コードの出現数を取得
	my $result;
	foreach my $i (@{$self->{codes}}){
		my $rows = mysql_exec->select("SELECT count(*) FROM $i->{res_table}")
			->hundle;
		if ($rows = $rows->fetch){                # 出現数0に対処
			$rows = $rows->[0]; 
		} else {
			$rows = 0;
		}
		push @{$result}, [
			$i->name,
			$rows,
			sprintf("%.2f",($rows / $total) * 100 )."%"
		];
	}
	
	# 1つでもコードが与えられた文書の数を取得
	my $sql = "SELECT count(*)\nFROM $tani\n";
	foreach my $i (@{$self->{codes}}){
		unless ( $i->{res_table} ){next;} # 出現数0に対処
		$sql .= "LEFT JOIN $i->{res_table} ON $tani.id = $i->{res_table}.id\n";
	}
	$sql .= "WHERE\n";
	my $n = 0;
	foreach my $i (@{$self->{codes}}){
		unless ( $i->{res_table} ){next;} # 出現数0に対処
		if ($n){ $sql .= "or "; }
		$sql .= "$i->{res_table}.num\n";
		++$n;
	}
	my $least1 = mysql_exec->select($sql,1)->hundle->fetch->[0];
	
	push @{$result}, [
		'＃コード無し',
		$total - $least1,
		sprintf("%.2f",( ($total - $least1) / $total ) * 100)."%"
	];
	push @{$result}, [
		'（文書数）',
		$total,
		''
	];
	
	return $result;
}


sub code{
	my $self = shift;
	my $tani = shift;
	
	unless ($self->{codes}){
		return 0;
	}
	
	my $n = 0;
	foreach my $i (@{$self->{codes}}){
		my $res_table = "ct_$tani"."_code_$n";
		$i->ready($tani) or next;
		$i->code($res_table);
		++$n;
	}
	
	return $self;
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
		
		$_ = Jcode->new("$_",'sjis')->euc;
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
		# print Jcode->new("code: $i\n")->sjis;
		push @{$self->{codes}}, kh_cod::a_code->new($i,$codes{$i});
	}
	
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


1;
