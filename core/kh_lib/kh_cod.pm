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
		$i->ready($tani) or next;
		$i->code($res_table);
		if ($i->res_table){ push @{$self->{valid_codes}}, $i; }
		++$n;
	}
	
	return $self;
}

#----------------------------#
#   ルールファイル読み込み   #

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
		$kh_cod::reading{$i} = $codes{$i};
		push @{$self->{codes}}, kh_cod::a_code->new($i,$codes{$i});
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

#--------------#
#   アクセサ   #

sub tables{                         # コーディング結果を納めたテーブルのリスト
	my $self = shift;
	my @r;
	unless ($self->valid_codes){return 0;}
	foreach my $i (@{$self->valid_codes}){
		push @r, $i->res_table;
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
