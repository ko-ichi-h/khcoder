# 既に定義してあるコードの利用 --- <＊コード名>

package kh_cod::a_code::atom::code;
use base qw(kh_cod::a_code::atom);
use strict;

my $num = 0;

sub reset{
	$num = 0;
}

#--------------------#
#   WHERE節用SQL文   #
#--------------------#

sub expr{
	my $self = shift;
	
	if ($self->{tables}){
		my $col = (split /\_/, $self->{tables}[0])[2].(split /\_/, $self->{tables}[0])[3];
		return "IFNULL(".$self->parent_table.".$col,0)";
	} else {
		return ' 0 ';
	}
}


#---------------------------------------#
#   コーディング準備（tmp table作成）   #
#---------------------------------------#

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{the_code}->ready($tani);
	$self->{the_code}->code("ct_$tani"."_atomcode_$num");
	if ($self->{the_code}->res_table){
		push @{$self->{tables}}, "ct_$tani"."_atomcode_$num";
		++$num;
	} else {
		$self->{tables} = 0;
	}
	return $self;
}

#----------------------------#
#   コード読み込み時の処理   #

sub when_read{
	my $self = shift;
	
	my $cod_name = $self->raw;
	chop $cod_name;
	substr($cod_name,0,1) = '';
	
	$self->{the_code} = kh_cod::a_code->new(
		$cod_name,
		$kh_cod::reading{$cod_name}
	);
	return $self;
}

#-------------------------------#
#   利用するtmp tableのリスト   #

sub tables{
	my $self = shift;
	return $self->{tables};
}

#----------------#
#   親テーブル   #
sub parent_table{
	my $self = shift;
	my $new  = shift;
	
	if (length($new)){
		$self->{parent_table} = $new;
	}
	return $self->{parent_table};
}

sub pattern{
	return '^<.+>$';
}
sub name{
	return 'code';
}

1;