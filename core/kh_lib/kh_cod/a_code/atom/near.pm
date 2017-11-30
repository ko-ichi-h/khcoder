# 語のフレーズによる指定

package kh_cod::a_code::atom::near;
use base qw(kh_cod::a_code::atom);
use strict;
use mysql_a_word;
use POSIX qw(log10);
use MIME::Base64;

my $debug = 0;

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

#----------------------#
#   コーディング準備   #
#----------------------#

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;
	
	# ルール指定の解釈
	my @wlist;
	my $max_dist = 10;
	my $option   = '';
	if ($self->raw =~ /^near\((.+)\)$/o){                   # デフォルト
		@wlist = split /\-/, $1;
	}
	elsif ( $self->raw =~ /^near\((.+)\)\[(.+)\]$/o ){      # オプション
		@wlist = split /\-/, $1;
		if ($2 =~ /^([0-9]+)$/){
			$max_dist = $1;
		}
		elsif ($2 =~ /^([bd])([0-9]*)$/){
			$max_dist = $2 if length($2) > 0;
			$option = $1;
			if ( ($option eq 'b') && ($tani eq 'bun') ){
				$option = '';
			}
			if (($option eq 'd') && (($tani eq 'bun') || ($tani eq 'dan'))){
				$option = '';
			}
		} else {
			print "error: invalid option \"$2\" found in the NEAR statement\n";
			return '';
		}
		if ($debug){
			print "words: ";
			foreach my $i (@wlist){
				print "$i, ";
			}
			print "\n";
			print "max dist: $max_dist\n";
			print "option: $option\n";
		}
	}
	
	# 各単語の出現文書リストを作製
	my (%w2tab, %w2hyoso, @hyosos, %hyoso2w);
	foreach my $i (@wlist){
		my $list = mysql_a_word->new(
			genkei => $i
		);
		$w2hyoso{$i} = $list->hyoso_id_s;
		unless ( $w2hyoso{$i} ){
			print
				"warn: no such word in the text: \"".$self->raw."\"\n";
			return '';
		}
		$list = $list->genkei_ids;
		@hyosos = (@hyosos ,@{$w2hyoso{$i}});
		foreach my $h (@{$w2hyoso{$i}}){
			$hyoso2w{$h} = $i;
		}
		
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
	my @c_c = kh_cod::a_code->cache_check(
		tani => $tani,
		kind => 'near',
		name => $self->raw
	);
	my $table_cache = 'ct_'."$tani"."_near_$c_c[1]";
	$self->{tables} = ["$table_cache"];
	$self->{hyosos} = \@hyosos;
	
	print "cache: $table_cache" if $debug;
	if ($c_c[0]){
		print " hit\n" if $debug;
		return $self;
	} else {
		print "\n" if $debug;
	}

	# AND検索による絞り込み
	mysql_exec->drop_table("ct_tmp_near");
	mysql_exec->do("
		CREATE TEMPORARY TABLE ct_tmp_near (id int) TYPE=HEAP
	",1);
	my $sql = '';
	$sql .= "INSERT INTO ct_tmp_near (id)\n";
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

	# 近くに出現しているかどうかをチェック:  1. データの取り出し
	$sql  = '';
	$sql .= "SELECT $tani.id, hyosobun.id, hyosobun.hyoso_id";
	if ($option eq 'b'){
		$sql .= ", hyosobun.bun_idt\n";
	}
	elsif ( $option eq 'd' ){
		$sql .= ", dan.id\n";
	}
	else {
		$sql .= "\n";
	}
	$sql .= "FROM $tani, ct_tmp_near, hyosobun";
	if ($option eq 'd'){
		$sql .= ", dan\n";
	}
	else {
		$sql .= "\n";
	}
	$sql .= "WHERE\n";
	$sql .= "$sql_join{$tani}\n";
	$sql .= "AND $tani.id = ct_tmp_near.id\n";
	if ($option eq 'd'){
		$sql .= "AND dan.dan_id = hyosobun.dan_id\n";
		$sql .= "AND dan.h5_id = hyosobun.h5_id\n";
		$sql .= "AND dan.h4_id = hyosobun.h4_id\n";
		$sql .= "AND dan.h3_id = hyosobun.h3_id\n";
		$sql .= "AND dan.h2_id = hyosobun.h2_id\n";
		$sql .= "AND dan.h1_id = hyosobun.h1_id\n";
	}
	$sql .= "AND (\n";
	my $n3 = 0;
	foreach my $i (@wlist){
		$sql .= "\tOR\n" if $n3;
		my ($n4,$part) = (0,'');
		foreach my $h (@{$w2hyoso{$i}}){
			$part .= " OR " if $n4;
			$part .= "hyosobun.hyoso_id = $h";
			++$n4;
		}
		$part = ' ( '."$part".' ) ' if $n4 > 1;
		$sql .= "\t\t$part\n";
		++$n3;
	}
	$sql .= ")\n";
	$sql .= "ORDER BY hyosobun.id";
	my $sth = mysql_exec->select($sql,1)->hundle;
	my @chk_data;
	while (my $i = $sth->fetch){
		push @chk_data, [
			$i->[0],
			$i->[1],
			$hyoso2w{$i->[2]},
			$i->[3]
		];
	}

	# 近くに出現しているかどうかをチェック:  2. チェック実行
	my %result = ();
	my $chk_data_rows = @chk_data - @wlist;
	for (my $n = 0; $n <= $chk_data_rows; ++$n){
		print "$n,$chk_data[$n]->[0],$chk_data[$n]->[1],$chk_data[$n]->[2]\n" if $debug;
		
		# 直後が同じ語の場合はチェックをスキップ
		if ($chk_data[$n]->[2] eq $chk_data[$n+1]->[2]){
			print "\tskip (0)\n" if $debug;
			next;
		}
		
		# 後続をチェック
		my $w_count     = 0;
		my %w_count_chk = ();
		my $sn          = $n;
		my $pos_hb      = $chk_data[$n]->[1];
		my $pos_opt     = $chk_data[$n]->[3];
		while ($chk_data[$sn]->[0] == $chk_data[$n]->[0]){
			# 同じ文書内の後続をチェックしていく
			print "\t$sn,$chk_data[$sn]->[0],$chk_data[$sn]->[1],$chk_data[$sn]->[2],$chk_data[$sn]->[3]\n" if $debug;
			
			# 後続が離れすぎていれば中断
			if (                                                 # 語数
				   ( $max_dist > 0 )
				&& ( $chk_data[$sn]->[1] - $pos_hb > $max_dist )
			){
				print "\ttoo long!\n" if $debug;
				last;
			}
			if (                                                 # 文・段落
				   ( length($option) > 0 )
				&! ( $pos_opt == $chk_data[$sn]->[3] )
			){
				print "\tnot in the same sentence/paragraph!\n" if $debug;
				last;
			}
			
			# 未チェックの語が有ればカウントアップ
			unless ($w_count_chk{$chk_data[$sn]->[2]}){
				print "\tcount up!\n" if $debug;
				$w_count_chk{$chk_data[$sn]->[2]} = 1;
				++$w_count;
				$pos_hb= $chk_data[$sn]->[1];
				if ($w_count >= @wlist){
					print "\tCheck OK!!\n" if $debug;
					++$result{$chk_data[$n]->[0]};
					last;
				}
			}
			++$sn;
		}
	}

	# 近くに出現しているかどうかをチェック:  3. 結果の書き出し
	++$num;
	mysql_exec->drop_table($table_cache);
	mysql_exec->do("
		CREATE TABLE $table_cache (
			id INT primary key not null,
			num INT
		)
	",1);
	foreach my $i (keys %result){
		mysql_exec->do (
			"insert into $table_cache (id, num) values ($i, $result{$i})",
			1
		);
	}
	
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
	return 'near\(.+\-.+\)';
}
sub name{
	return 'near';
}

1;