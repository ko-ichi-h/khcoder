package kh_cod::search;
use base qw(kh_cod);
use strict;

use mysql_exec;

my %sql_join = (
	'bun' =>
		'bun.id = bun_r.id',
	'dan' =>
		'
			    dan.dan_id = bun.dan_id
			AND dan.h5_id = bun.h5_id
			AND dan.h4_id = bun.h4_id
			AND dan.h3_id = bun.h3_id
			AND dan.h2_id = bun.h2_id
			AND dan.h1_id = bun.h1_id
		',
	'h5' =>
		'
			    h5.h5_id = bun.h5_id
			AND h5.h4_id = bun.h4_id
			AND h5.h3_id = bun.h3_id
			AND h5.h2_id = bun.h2_id
			AND h5.h1_id = bun.h1_id
		',
	'h4' =>
		'
			    h4.h4_id = bun.h4_id
			AND h4.h3_id = bun.h3_id
			AND h4.h2_id = bun.h2_id
			AND h4.h1_id = bun.h1_id
		',
	'h3' =>
		'
			    h3.h3_id = bun.h3_id
			AND h3.h2_id = bun.h2_id
			AND h3.h1_id = bun.h1_id
		',
	'h2' =>
		'
			    h2.h2_id = bun.h2_id
			AND h2.h1_id = bun.h1_id
		',
	'h1' =>
		'h1.h1_id = bun.h1_id'
);

# 直接入力コードの読み込み
sub add_direct{
	my $self   = shift;
	my $direct = shift;
	
	# 既に追加されていた場合はいったん削除
	if ($self->{codes}[0]->name eq 'direct'){
		print "Delete old \'direct\'\n";
		shift @{$self->{codes}};
	}
	
	
	unshift @{$self->{codes}}, kh_cod::a_code->new('direct',$direct);
}

# 検索の実行
sub search{
	my $self = shift;
	my %args = @_;
	
	# 取りあえずコーディング
	foreach my $i (@{$args{selected}}){
		my $res_table = "ct_$args{tani}"."_code_$i";
		$self->{codes}[$i]->ready($args{tani}) or next;
		$self->{codes}[$i]->code($res_table) or next;
		if ($self->{codes}[$i]->res_table){
			push @{$self->{valid_codes}}, $self->{codes}[$i];
		}
	}
	
	# AND条件の時に、0コードが存在した場合はreturn
	unless ($self->{valid_codes}){
		foreach my $i (@{$args{selected}}){
			$self->{codes}[$i]->clear;
		}
		$self->{valid_codes} = undef;
		return undef;
	}
	if (
		   ( $args{method} eq 'and' )
		&& ( @{$self->{valid_codes}} < @{$args{selected}} )
	) {
		foreach my $i (@{$args{selected}}){
			$self->{codes}[$i]->clear;
		}
		$self->{valid_codes} = undef;
		return undef;
	}
	
	# 合致する文書のリストを取得
	my $sql = "SELECT $args{tani}.id\nFROM $args{tani}\n";
	foreach my $i (@{$self->tables}){
		$sql .= "LEFT JOIN $i ON $args{tani}.id = $i.id\n";
	}
	$sql .= "WHERE\n";
	my $n = 0;
	foreach my $i (@{$self->valid_codes}){
		if ($n){ $sql .= "$args{method} "; }
		$sql .= "IFNULL(".$i->res_table.".".$i->res_col.",0)\n";
		++$n;
	}
	my $sth = mysql_exec->select($sql,1)->hundle;
	
	my @result;
	while (my $i = $sth->fetch){
		push @result, [
			$i->[0],
			kh_cod::search->get_doc_head($i->[0],$args{tani})
		];
	}
	
	# 検索に利用した語（表層）のリスト
	my (@words, %words);
	foreach my $i (@{$self->{valid_codes}}){
		if ($i->hyosos){
			foreach my $h (@{$i->hyosos}){
				++$words{$h};
			}
		}
	}
	@words = (keys %words);
	
	# コードのクリア
	foreach my $i (@{$args{selected}}){
		$self->{codes}[$i]->clear;
	}
	$self->{valid_codes} = undef;
	
	return (\@result,\@words);
}

# 文書の先頭部分を取得
sub get_doc_head{
	my $self = shift;
	my $id   = shift;
	my $tani = shift;
	
	my $sql;
	
	if ($tani eq 'bun'){
		$sql = "
			SELECT rowtxt
			FROM bun_r, bun
			WHERE
				    bun_r.id = bun.id
				AND bun.id = $id
		";
	} else {
		$sql = "
			SELECT rowtxt
			FROM bun_r, bun, $tani
			WHERE $sql_join{$tani}
				AND bun_r.id = bun.id
				AND $tani.id = $id
			LIMIT 10
		";
	}
	
	my $sth = mysql_exec->select($sql,1)->hundle;
	
	my $r;
	while (my $i = $sth->fetch){
		$r .= $i->[0];
		if (length($r) > 66){
			last;
		}
	}
	
	# 切り落とし
	if (length($r) > $::config_obj->DocSrch_CutLength){
		my $len = $::config_obj->DocSrch_CutLength;
		if (
			substr($r,0,$len) =~ /\x8F$/
			or substr($r,0,$len) =~ tr/\x8E\xA1-\xFE// % 2 
		){
			--$len;
			if (
				substr($r,0,$len) =~ /\x8F$/
				or substr($r,0,$len) =~ tr/\x8E\xA1-\xFE// % 2 
			){
				--$len;
			}
		}
		$r = substr($r,0,$len);
		$r .= '…';
	}
	
	return $r;
	
}



1;