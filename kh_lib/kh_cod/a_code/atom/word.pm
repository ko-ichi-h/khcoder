# 通常の抽出語（基本形）を使った指定

package kh_cod::a_code::atom::word;
use base qw(kh_cod::a_code::atom);
use strict;

use mysql_a_word;
use mysql_exec;

#-----------------#
#   SQL文の準備   #
#-----------------#

my %sql_join = (
	'bun' =>
		'bun.id = hyosobun.bun_idt',
	'dan' =>
		'
			    dan.dan_id = hyosobun.dan_id
			AND dan.h5_id = hyosobun.h5_id
			AND dan.h4_id = hyosobun.h4_id
			AND dan.h3_id = hyosobun.h3_id
			AND dan.h2_id = hyosobun.h2_id
			AND dan.h1_id = hyosobun.h1_id
		',
	'h5' =>
		'
			    h5.h5_id = hyosobun.h5_id
			AND h5.h4_id = hyosobun.h4_id
			AND h5.h3_id = hyosobun.h3_id
			AND h5.h2_id = hyosobun.h2_id
			AND h5.h1_id = hyosobun.h1_id
		',
	'h4' =>
		'
			    h4.h4_id = hyosobun.h4_id
			AND h4.h3_id = hyosobun.h3_id
			AND h4.h2_id = hyosobun.h2_id
			AND h4.h1_id = hyosobun.h1_id
		',
	'h3' =>
		'
			    h3.h3_id = hyosobun.h3_id
			AND h3.h2_id = hyosobun.h2_id
			AND h3.h1_id = hyosobun.h1_id
		',
	'h2' =>
		'
			    h2.h2_id = hyosobun.h2_id
			AND h2.h1_id = hyosobun.h1_id
		',
	'h1' =>
		'h1.h1_id = hyosobun.h1_id',
	'buntmp' =>
		'buntmp.id = hyosobun.bun_idt',
	'dantmp' =>
		'
			    dantmp.dan_id = hyosobun.dan_id
			AND dantmp.h5_id = hyosobun.h5_id
			AND dantmp.h4_id = hyosobun.h4_id
			AND dantmp.h3_id = hyosobun.h3_id
			AND dantmp.h2_id = hyosobun.h2_id
			AND dantmp.h1_id = hyosobun.h1_id
		',
	'h5tmp' =>
		'
			    h5tmp.h5_id = hyosobun.h5_id
			AND h5tmp.h4_id = hyosobun.h4_id
			AND h5tmp.h3_id = hyosobun.h3_id
			AND h5tmp.h2_id = hyosobun.h2_id
			AND h5tmp.h1_id = hyosobun.h1_id
		',
	'h4tmp' =>
		'
			    h4tmp.h4_id = hyosobun.h4_id
			AND h4tmp.h3_id = hyosobun.h3_id
			AND h4tmp.h2_id = hyosobun.h2_id
			AND h4tmp.h1_id = hyosobun.h1_id
		',
	'h3tmp' =>
		'
			    h3tmp.h3_id = hyosobun.h3_id
			AND h3tmp.h2_id = hyosobun.h2_id
			AND h3tmp.h1_id = hyosobun.h1_id
		',
	'h2tmp' =>
		'
			    h2tmp.h2_id = hyosobun.h2_id
			AND h2tmp.h1_id = hyosobun.h1_id
		',
	'h1tmp' =>
		'h1tmp.h1_id = hyosobun.h1_id'
);
my %sql_group = (
	'bun' =>
		'hyosobun.bun_idt',
	'dan' =>
		'hyosobun.dan_id, hyosobun.h5_id, hyosobun.h4_id, hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h5' =>
		'hyosobun.h5_id, hyosobun.h4_id, hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h4' =>
		'hyosobun.h4_id, hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h3' =>
		'hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h2' =>
		'hyosobun.h2_id, hyosobun.h1_id',
	'h1' =>
		'hyosobun.h1_id',
	'buntmp' =>
		'hyosobun.bun_idt',
	'dantmp' =>
		'dantmp.id',
	'h5tmp' =>
		'hyosobun.h5_id, hyosobun.h4_id, hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h4tmp' =>
		'hyosobun.h4_id, hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h3tmp' =>
		'hyosobun.h3_id, hyosobun.h2_id, hyosobun.h1_id',
	'h2tmp' =>
		'hyosobun.h2_id, hyosobun.h1_id',
	'h1tmp' =>
		'hyosobun.h1_id',
);

my %a_doc_cache;

#--------------------#
#   WHERE節用SQL文   #
#--------------------#

sub expr{
	my $self = shift;
	
	if (index($self->{tani},'tmp') > 0){
		return $self->{bool};
	}
	
	my $t = $self->tables;
	unless ($t){ return '0';}
	
	my ($sql, $n) = ('',0);
	foreach my $i (@{$t}){
		if ($n){$sql .= ' or '}
		my $col = (split /\_/, $i)[2].(split /\_/, $i)[3];
		$sql .= "IFNULL(".$self->parent_table.".$col,0)";
		++$n;
	}
	if ($n > 1){
		$sql = '( '."$sql".' )';
	}
	return $sql;
}

#---------------------------------------#
#   コーディング準備（tmp table作成）   #
#---------------------------------------#

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;
	
	#-------------------#
	#   文書1つの場合   #
	
	if (index($tani,'tmp') > 0){
		
		$self->{bool} = 0;
	
		my $list = mysql_a_word->new(
			genkei => $self->raw
		)->genkei_ids;
		unless ( $list ){
			return '';
		}
		
		# キャッシュ作製
		unless ( %a_doc_cache ){
			print " making cache\n";
			my $sql = "
				SELECT genkei.id
				FROM   hyosobun, hyoso, genkei, $tani
				WHERE
					$sql_join{$tani}
					AND hyosobun.hyoso_id = hyoso.id
					AND hyoso.genkei_id   = genkei.id
			";
			my $sth = mysql_exec->select($sql,1)->hundle;
			while (my $i = $sth->fetch){
				++$a_doc_cache{$i->[0]};
			}
		}
		
		foreach my $i (@{$list}){
			$self->{bool} += $a_doc_cache{$i};
		}
		return 1;
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

sub clear{
	%a_doc_cache = ();
}

sub hyosos{
	my $self = shift;
	return mysql_a_word->new(
		genkei => $self->raw
	)->hyoso_id_s;;
}

sub pattern{
	return '.*';
}
sub name{
	return 'word';
}




1;