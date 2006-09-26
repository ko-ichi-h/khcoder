# 語のフレーズによる指定

package kh_cod::a_code::atom::phrase;
use base qw(kh_cod::a_code::atom);
use strict;
use mysql_a_word;
use POSIX qw(log10);

my $num = 0;
sub reset{
	$num = 0;
}

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
my %sql_join2 = (
	'bun' =>
		'bun.id = hb0.bun_idt',
	'dan' =>
		'
			    dan.dan_id = hb0.dan_id
			AND dan.h5_id = hb0.h5_id
			AND dan.h4_id = hb0.h4_id
			AND dan.h3_id = hb0.h3_id
			AND dan.h2_id = hb0.h2_id
			AND dan.h1_id = hb0.h1_id
		',
	'h5' =>
		'
			    h5.h5_id = hb0.h5_id
			AND h5.h4_id = hb0.h4_id
			AND h5.h3_id = hb0.h3_id
			AND h5.h2_id = hb0.h2_id
			AND h5.h1_id = hb0.h1_id
		',
	'h4' =>
		'
			    h4.h4_id = hb0.h4_id
			AND h4.h3_id = hb0.h3_id
			AND h4.h2_id = hb0.h2_id
			AND h4.h1_id = hb0.h1_id
		',
	'h3' =>
		'
			    h3.h3_id = hb0.h3_id
			AND h3.h2_id = hb0.h2_id
			AND h3.h1_id = hb0.h1_id
		',
	'h2' =>
		'
			    h2.h2_id = hb0.h2_id
			AND h2.h1_id = hb0.h1_id
		',
	'h1' =>
		'h1.h1_id = hb0.h1_id',
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
	my $t = $self->tables;
	unless ($t){ return '0';}
	
	$t = $t->[0];
	my $col = (split /\_/, $t)[2].(split /\_/, $t)[3];
	my $sql = "IFNULL(".$self->parent_table.".$col,0)";
	return $sql;
}

sub idf{
	my $self = shift;
	return 0 unless $self->tables;
	
	# 全文書数の取得・保持
	unless (
		($dn->{$self->{tani}}) && ($dn->{check} eq $::project_obj->file_target)
	){
		$dn->{$self->{tani}} = mysql_exec->select(
			"SELECT COUNT(*) FROM $self->{tani}",1
		)->hundle->fetch->[0];
		$dn->{check} = $::project_obj->file_target;
	}
	
	# 計算
	my $df;
	$df = mysql_exec->select(
		"SELECT COUNT(*) FROM $self->{tables}[0]",1
	)->hundle->fetch->[0];
	return 0 unless $df;
	
	return log10($dn->{$self->{tani}} / $df);
}

#---------------------------------------#
#   コーディング準備（tmp table作成）   #
#---------------------------------------#

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;
	
	# ルール指定の解釈
	my @wlist = split /\+/, $self->raw;
	
	# 各単語の出現文書リストを作製
	my (%w2tab, %w2hyoso, @hyosos);
	foreach my $i (@wlist){
		my $list = mysql_a_word->new(
			genkei => $i
		);
		$w2hyoso{$i} = $list->hyoso_id_s;
		$list = $list->genkei_ids;
		unless ( $w2hyoso{$i} ){
			print Jcode->new(
				"no such word in the text: \"".$self->raw."\"\n"
			)->sjis;
			return '';
		}
		@hyosos = (@hyosos ,@{$w2hyoso{$i}});
		
		foreach my $h (@{$list}){
			my $table = 'ct_'."$tani".'_kihon_'. "$h";
			push @{$w2tab{$i}}, $table;
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
					AND genkei.id = $h
					AND $sql_join{$tani}
				GROUP BY $sql_group{$tani}
			",1);
		}
	}
	
	# テーブル名決定とキャッシュのチェック
	my $debug = 0;
	my @c_c = kh_cod::a_code->cache_check(
		tani => $tani,
		kind => 'phrase',
		name => $self->raw
	);
	my $table = 'ct_'."$tani"."_phrase_$c_c[1]";
	$self->{tables} = ["$table"];
	$self->{hyosos} = \@hyosos;
	
	print "cache: $table" if $debug;
	if ($c_c[0]){
		print " hit\n" if $debug;
		return $self;
	} else {
		print "\n" if $debug;
	}

	# AND検索による絞り込みを実施
	mysql_exec->drop_table("ct_tmp_phrase");
	mysql_exec->do("
		CREATE TEMPORARY TABLE ct_tmp_phrase (id int) TYPE=HEAP
	",1);
	my $sql = '';
	$sql .= "INSERT INTO ct_tmp_phrase (id)\n";
	$sql .= "SELECT $tani.id\n";
	$sql .= "FROM $tani\n";
	foreach my $i (@wlist){
		foreach my $h (@{$w2tab{$i}}){
			$sql .= " LEFT JOIN $h ON $tani.id = $h.id\n";
		}
	}
	$sql .= "WHERE (\n";
	my $n0 = 0;
	foreach my $i (@wlist){
		$sql .= "AND " if $n0;
		my ($part, $n1) = ('',0);
		foreach my $h (@{$w2tab{$i}}){
			$part .= " or " if $n1;
			$part .= "IFNULL($h.num,0)";
			++$n1;
		}
		$part = '( '."$part".' )' if $n1 > 1;
		$sql .= "$part\n";
		++$n0;
	}
	$sql .= ")";
	mysql_exec->do("$sql",1);

	# TMPテーブルの作製
	#my $table = "ct_$tani"."_phrase_$num";
	$self->{tables} = ["$table"];
	++$num;
	mysql_exec->drop_table($table);
	mysql_exec->do("
		CREATE TABLE $table (
			id INT primary key not null,
			num INT
		)
	",1);

	# 連続して出現しているかどうかをチェック
	my $n2 = @wlist - 1;
	$sql = '';
	$sql .= "INSERT INTO $table (id, num)\n";
	$sql .= "SELECT $tani.id, count(*)\n";
	$sql .= "FROM $tani, ct_tmp_phrase, hyosobun as hb0\n";
	for (my $n = $n2; $n; --$n){
		$sql .= "	LEFT JOIN hyosobun as hb$n ON hb0.id + $n = hb$n.id\n"
	}
	$sql .= "WHERE\n";
	$sql .= "$sql_join2{$tani}\n";
	$sql .= "AND $tani.id = ct_tmp_phrase.id\n";
	my $n3 = 0;
	foreach my $i (@wlist){
		my ($n4,$part) = (0,'');
		foreach my $h (@{$w2hyoso{$i}}){
			$part .= " OR " if $n4;
			$part .= "hb$n3.hyoso_id = $h";
			++$n4;
		}
		$part = ' ( '."$part".' ) ' if $n4 > 1;
		$sql .= "AND $part\n";
		++$n3;
	}
	$sql .= "GROUP BY $tani.id";
	mysql_exec->do("$sql",1);
	
}

#--------------#
#   アクセサ   #
#--------------#

sub tables{
	my $self = shift;
	return $self->{tables};
}

sub hyosos{
	my $self = shift;
	return $self->{hyosos};
}

sub parent_table{
	my $self = shift;
	my $new  = shift;
	
	if (length($new)){
		$self->{parent_table} = $new;
	}
	return $self->{parent_table};
}

sub pattern{
	return '.+\+.+';
}
sub name{
	return 'phrase';
}

1;