package kh_cod::a_code::atom::hinshi;
use base qw(kh_cod::a_code::atom);
use strict;

use mysql_a_word;
use mysql_exec;




#---------------------------------------#
#   コーディング準備（tmp table作成）   #
#---------------------------------------#

sub ready{
	my $self = shift;
	my $tani = shift;
	
	my $list;
	if ($self->raw =~ /^(.+)\-\->(.+)->(.+)$/){   # 品詞＆活用 指定
		$list = mysql_a_word->new(
			genkei => $1,
			hinshi => $2,
			katuyo => $3
		)->hyoso_id_s;
	}
	elsif ($self->raw =~ /^(.+)\-\->(.+)$/){      # 品詞指定
		$list = mysql_a_word->new(
			genkei => $1,
			hinshi => $2,
		)->hyoso_id_s;
	}
	elsif ($self->raw ~= /^(.+)\->(.+)$$/){       # 活用指定
		$list = mysql_a_word->new(
			genkei => $1,
			katuyo => $2,
		)->hyoso_id_s;
	}
	
	my $list = mysql_a_word->new(
		genkei => $self->raw
	)->genkei_ids;
	unless (defined($list) ){
		print Jcode->new(
			"no such word in the text: \"".$self->raw."\"\n"
		)->sjis;
		return '';
	}
	
	foreach my $i (@{$list}){
		my $table = 'ct_'."$tani".'_kihon_'. "$i";
		push @{$self->{tables}}, $table;
		
		if ( mysql_exec->table_exists($table) ){
			next;
		}
		
		mysql_exec->do("
			CREATE TABLE $table (
				id INT primary key not null,
				num INT
			)
		",1);
		mysql_exec->do("
			INSERT
			INTO $table (id, num)
			SELECT $tani.id, count(*)
			FROM $tani, hyosobun, hyoso, genkei
			WHERE
				hyosobun.hyoso_id = hyoso.id
				AND genkei.id = hyoso.genkei_id
				AND genkei.id = $i
				AND $sql_join{$tani}
			GROUP BY $sql_group{$tani}
		",1);
		
	}
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
	return '.+\->.+';
}
sub name{
	return 'word';
}


1;
