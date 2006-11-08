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
	return '0' unless $self->{the_code};
	if ($self->{tables}){
		my $col = (split /\_/, $self->{tables}[0])[2].(split /\_/, $self->{tables}[0])[3];
		return "(".$self->parent_table.".$col is not null)";
	} else {
		return ' 0 ';
	}
}

sub num_expr{
	my $self = shift;
	return '0' unless $self->{the_code};
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
	$self->{tani} = $tani;
	
	return $self unless $self->{the_code};
	
	# コーディングが実行されていなかった場合は、ここで実行
	unless (
		   $self->{the_code}->if_done == 1 
		&& $self->{the_code}->tani    eq $tani
	){
		$self->{the_code}->ready($tani);
		$self->{the_code}->code("ct_$tani"."_atomcode2_$num");
		print "\tWarn: Coding an atom-code. IDF values would be incorrect...";
	}
	
	$self->{hyosos} = $self->{the_code}->hyosos;
	
	if ($self->{the_code}->res_table){
		# 新しいテーブル名の作成・セット
		my $table  = "ct_$tani"."_atomcode_$num";
		push @{$self->{tables}}, $table;
		++$num;
		# テーブルをコピー
		my $oldtab = $self->{the_code}->res_table;
		print "\tatom-code: old-$oldtab, new-$table\n";
		mysql_exec->drop_table($table);
		mysql_exec->do("
			CREATE TABLE $table (
				id  INT primary key not null,
				num FLOAT
			) TYPE = HEAP
		",1);
		mysql_exec->do("
			INSERT INTO $table (id, num)
			SELECT id, num FROM $oldtab
		",1);
	} else {
		$self->{tables} = 0;
	}
	return $self;
}
sub clear{
	my $self = shift;
	return '0' unless $self->{the_code};
	$self->{the_code}->clear;
}


#----------------------------#
#   コード読み込み時の処理   #

sub when_read{
	my $self = shift;
	
	my $cod_name = $self->raw;
	chop $cod_name;
	substr($cod_name,0,1) = '';
	
	$self->{the_code} = $kh_cod::reading{$cod_name};

	gui_errormsg->open(
		msg  => "コーディングルールの記述に誤りがあります。\n".
		        '「'.$cod_name.'」というコードは定義されていません。',
		type => 'msg'
	) unless $self->{the_code};

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

#--------------#
#   アクセサ   #

sub raw_for_cache_chk{
	my $self = shift;
	return "$self->{raw}".'{'."$self->{the_code}->{ed_condition}".'}';
}

sub hyosos{
	my $self = shift;
	return $self->{hyosos};
}
sub pattern{
	return '^<.+>$';
}
sub name{
	return 'code';
}

1;