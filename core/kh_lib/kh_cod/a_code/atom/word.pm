# 通常の抽出語（基本形）を使った指定

package kh_cod::a_code::atom::word;
use base qw(kh_cod::a_code::atom);
use strict;

use mysql_a_word;
use mysql_exec;
use POSIX qw(log10);

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
);

my $dn;

#--------------------#
#   WHERE節用SQL文   #
#--------------------#

sub expr{
	my $self = shift;
	my %args = @_;
	
	my $t = $self->tables;
	unless ($t){ return '0';}
	
	my ($sql, $n) = ('',0);
	foreach my $i (@{$t}){
		if ($n){$sql .= ' + '}
		my ($col,$tab);
		#if ($args{parents}){
			$col = (split /\_/, $i)[2].(split /\_/, $i)[3];
			$tab = $self->parent_table;
		#} else {
		#	$col = 'num';
		#	$tab = $i;
		#}
		$sql .= "IFNULL($tab.$col,0)";
		++$n;
	}
	if ($n > 1){
		$sql = '( '."$sql".' )';
	}
	return $sql;
}

sub idf{
	my $self = shift;

	my $t = $self->tables;
	unless ($t){ return '0';}

	# 全文書数の取得・保持
	unless (
		($dn->{$self->{tani}}) && ($dn->{check} eq $::project_obj->file_target)
	){
		$dn->{$self->{tani}} = mysql_exec->select(
			"SELECT COUNT(*) FROM $self->{tani}",1
		)->hundle->fetch->[0];
		$dn->{check} = $::project_obj->file_target;
	}

	my $df = 0;
	# 1種類の場合
	if (@{$t} == 1){
		return 0 unless $self->{list};
		$df = mysql_exec->select("
			SELECT f
			FROM   df_$self->{tani}
			WHERE  genkei_id = $self->{list}->[0]
		",1)->hundle;
		$df = $df->fetch or return 0;
		$df = $df->[0];
	}
	# 2種類以上の場合
	elsif (@{$t} > 1){
		my $sql;
		$sql .= "SELECT COUNT(*)\n";
		$sql .= "FROM $self->{tani}\n";
		foreach my $i (@{$t}){
			$sql .= "	LEFT JOIN $i ON $self->{tani}.id = $i.id\n";
		}
		$sql .= "WHERE\n";
		my $n = 0;
		foreach my $i (@{$t}){
			$sql .= " OR " if $n;
			$sql .= "	($i.num is not null)";
			$n = 1;
		}
		#print "$sql\n";
		$df = mysql_exec->select($sql,1)->hundle;
		$df = $df->fetch or return 0;
		$df = $df->[0];
	}
	
	return 0 unless $df;
	
	# debug print
	#my $debug = $self->raw."\t$df\t";
	#$debug .= log10($dn->{$self->{tani}} / $df);
	#print Jcode->new("$debug\n")->sjis;
	
	return log10($dn->{$self->{tani}} / $df);
}

#---------------------------------------#
#   コーディング準備（tmp table作成）   #
#---------------------------------------#

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;
	
	if ($self->raw =~ /^"(.+)"$/){
		$self->{raw} = $1;
	}
	
	my $list = mysql_a_word->new(
		genkei => $self->raw
	)->genkei_ids;
	unless (defined($list) ){
		print 
			"\tCould NOT find the word : \"".$self->raw."\"\n";
		return '';
	}
	$self->{list} = $list;
	
	foreach my $i (@{$list}){
		my $table = 'ct_'."$tani".'_kihon_'. "$i";
		push @{$self->{tables}}, $table;
		
		if ( mysql_exec->table_exists($table) ){
			#print Jcode->new(
			#	"table exists: \"".$self->raw."\"\n"
			#)->sjis;
			next;
		}
		#print Jcode->new(
		#	"table dose not exist: \"".$self->raw."\"\n"
		#)->sjis;
		
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

sub hyosos{
	my $self = shift;
	return mysql_a_word->new(
		genkei => $self->raw
	)->hyoso_id_s;
}

sub pattern{
	return '.*';
}
sub name{
	return 'word';
}




1;