#------------------------------#
#   単語関係のサブルーチン群   #
#------------------------------#

package mysql_words;
use strict;
use mysql_exec;

#--------------#
#   単語検索   #

# Usage: mysql_word->search(
# 	query  => 'EUC検索文',
# 	method => 'AND/OR',
# 	kihone => 1/0             # 基本形で検索するかどうか
# 	katuyo => 1/0             # 活用形を表示するかどうか
# );

sub search{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	my $query = $args{query};
	$query =~ s/　/ /g;
	my @query = split / /, $query;
	
	my $result;
	
	if ($args{kihon}){        # KHCの抽出語(基本形)を検索
		my $sql;
		$sql = '
			SELECT
				genkei.name, hselection.name, genkei.num, genkei.id, hinshi.name
			FROM
				genkei, hselection, hinshi
			WHERE
				    genkei.khhinshi_id = hselection.khhinshi_id
				AND genkei.hinshi_id = hinshi.id
				AND hselection.ifuse = 1
				AND genkei.nouse = 0'."\n";
		$sql .= "\t\t\tAND (\n";
		foreach my $i (@query){
			unless ($i){ next; }
			my $word = $self->conv_query($i);
			$sql .= "\t\t\t\tgenkei.name LIKE $word";
			if ($args{method} eq 'AND'){
				$sql .= " AND\n";
			} else {
				$sql .= " OR\n";
			}
		}
		substr($sql,-4,3) = '';
		$sql .= "\t\t\t)\n\t\tORDER BY\n\t\t\tgenkei.num DESC";
		my $t = mysql_exec->select($sql,1);
		$result = $t->hundle->fetchall_arrayref;
		
		# 「その他」対策
		if (
			mysql_exec->select("
				SELECT ifuse FROM hselection WHERE name = \'その他\'
			",1)->hundle->fetch->[0]
		){
			foreach my $i (@{$result}){
				if ($i->[1] eq 'その他'){
					$i->[0] = "$i->[0]($i->[4])";
				}
			}
		}
		
		if ( ! $args{katuyo} ){         # 活用語なしの場合
			foreach my $i (@{$result}){
				pop @{$i};
				pop @{$i};
			}
		} else {                        # 活用語ありの場合
			my $result2;
			foreach my $i (@{$result}){
				my $hinshi = pop @{$i};
				my $id = pop @{$i};
				push @{$result2}, $i;
				
				if ( index("$hinshi",'名詞-') == 0 ){
					next;
				}
				
				my $r = mysql_exec->select("      # 活用語を探す
					SELECT hyoso.name, katuyo.name, hyoso.num
					FROM hyoso, katuyo
					WHERE
						    hyoso.katuyo_id = katuyo.id
						AND hyoso.genkei_id = $id
				",1)->hundle->fetchall_arrayref;
				
				foreach my $h (@{$r}){            # 活用語の追加
					if ( length($h->[1]) > 1 ){
						$h->[1] = '   '.$h->[1];
						unshift @{$h}, 'katuyo';
						push @{$result2}, $h;
					}
				}
			}
			$result = $result2
		}

	} else {                  # 非-抽出語 検索
		my $sql;
		$sql = '
			SELECT hyoso.name, hinshi.name, katuyo.name, hyoso.num
			FROM hyoso, genkei, hinshi, katuyo
			WHERE
				    hyoso.genkei_id = genkei.id
				AND genkei.hinshi_id = hinshi.id
				AND hyoso.katuyo_id = katuyo.id AND (
		';
		foreach my $i (@query){
			my $word = $self->conv_query($i);
			$sql .= "\t\t\t\thyoso.name LIKE $word";
			if ($args{method} eq 'AND'){
				$sql .= " AND\n";
			} else {
				$sql .= " OR\n";
			}
		}
		substr($sql,-4,3) = '';
		$sql .= ") \n ORDER BY hyoso.num DESC";
		$result = mysql_exec->select($sql,1)->hundle->fetchall_arrayref;
	}

	return $result;
}
sub conv_query{
	my $self = shift;
	my $q = shift;
	
	if ($self->{mode} eq 'p'){
		$q = '\'%'."$q".'%\'';
	}
	elsif ($self->{mode} eq 'c'){
		$q = "\'$q\'";
	}
	elsif ($self->{mode} eq 'k'){
		$q = '\'%'."$q\'";
	}
	elsif ($self->{mode} eq 'z'){
		$q = "\'$q".'%\'';
	}
	return $q;
}

#-------------------------#
#   CSV形式リストの出力   #

sub csv_list{
	use kh_csv;
	my $class = shift;
	my $target = shift;
	
	
	my $list = &_make_list;
	
	open (LIST,">$target") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$target"
		);
	
	# 1行目
	my $line = '';
	foreach my $i (@{$list}){
		$line .= kh_csv->value_conv($i->[1]).',,';
	}
	chop $line;
	print LIST "$line\n";
	# 2行目以降
	my $row = 0;
	while (1){
		my $line = '';
		my $check;
		foreach my $i (@{$list}){
			$line .=kh_csv->value_conv($i->[1][$row][0]).",$i->[1][$row][1],";
			$check += $i->[1][$row][1];
		}
		chop $line;
		unless ($check){
			last;
		}
		print LIST "$line\n";
		++$row;
	}
	close (LIST);
	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_sjis($target);
	}
}

#-----------------------#
#   出現回数 度数分布   #

sub freq_of_f{
	my $class = shift;
	
	my $list = &_make_list;
	
	my ($n, %freq, $sum, $sum_sq); 
	foreach my $i (@{$list}){
		foreach my $h (@{$i->[1]}){
			++$freq{$h->[1]};
			++$n;
			$sum += $h->[1];
			$sum_sq += $h->[1] ** 2;
		}
	}
	my $mean = sprintf("%.2f", $sum / $n);
	my $sd = sprintf("%.2f", sqrt( ($sum_sq - $sum ** 2 / $n) / ($n - 1)) );
	
	my @r1;
	push @r1, ['異なり語数 (n)  ', $n];
	push @r1, ['平均 出現数', $mean];
	push @r1, ['標準偏差', $sd];
	
	my (@r2, $cum); 
	foreach my $i (sort {$a <=> $b} keys %freq){
		$cum += $freq{$i};
		push @r2, [
			$i,
			$freq{$i},
			sprintf("%.2f",($freq{$i} / $n) * 100),
			$cum,
			sprintf("%.2f",($cum / $n) * 100)
		];
	}
	return(\@r1, \@r2);
}

#----------------------#
#   単語リストの作成   #

# 品詞リストアップ
sub _make_hinshi_list{
	my @hinshi = ();
	my $sql = '
		SELECT hselection.name, hselection.khhinshi_id
		FROM genkei, hselection
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			AND hselection.ifuse = 1
		GROUP BY hselection.khhinshi_id
		ORDER BY hselection.khhinshi_id
	';
	my $t = mysql_exec->select($sql,1);
	while (my $i = $t->hundle->fetch){
		push @hinshi, [ $i->[0], $i->[1] ];
	}
	return \@hinshi;
}

sub _make_list{

	my $temp = &_make_hinshi_list;
	unless (eval (@{$temp})){
		print "oh, well, I don't know...\n";
		return;
	}

	my @hinshi = @{$temp};
	# 単語リストアップ
	my @result = ();
	foreach my $i (@hinshi){
		my $sql;
		if ($i->[0] eq 'その他'){
			$sql  = "
				SELECT concat(genkei.name,'(',hinshi.name,')'), genkei.num
				FROM genkei, hinshi
				WHERE
					genkei.hinshi_id = hinshi.id
					and khhinshi_id = $i->[1]
					and genkei.nouse = 0
				ORDER BY num DESC
			";
		} else {
			$sql  = "
				SELECT name, num FROM genkei
				WHERE
					khhinshi_id = $i->[1]
					and genkei.nouse = 0
				ORDER BY num DESC
			";
		}
		my $t = mysql_exec->select($sql,1);
		push @result, ["$i->[0]", $t->hundle->fetchall_arrayref];
	}
	return \@result;
}

#--------------------------#
#   単語数を返すルーチン   #
#--------------------------#

sub num_kinds{
	my $hinshi = &_make_hinshi_list;
	my $sql = '';
	$sql .= 'SELECT count(*) ';
	$sql .= 'FROM genkei ';
	$sql .= "WHERE genkei.nouse = 0 and (\n";
	my $n = 0;
	foreach my $i (@{$hinshi}){
		if ($n){
			$sql .= '    or ';
		} else {
			$sql .= '       ';
		}
		$sql .= "khhinshi_id=$i->[1]\n";
		++$n;
	}
	$sql .= " )";
	return mysql_exec->select($sql,1)->hundle->fetch->[0];
}
sub num_kinds_all{
	return mysql_exec                   # HTMLおよび幽霊を除く単語種類数を返す
		->select("
			select count(*)
			from genkei
			where
				khhinshi_id!=99999 and genkei.nouse=0
		",1)->hundle->fetch->[0];
}
sub num_all{
	return mysql_exec                   # HTMLおよび幽霊を除く単語数を返す
		->select("
			select sum(num)
			from genkei
			where 
				khhinshi_id!=99999 and genkei.nouse=0
		",1)->hundle->fetch->[0];
}

sub num_kotonari_ritsu{
	my $total = mysql_exec->select("
		select sum(num)
		from genkei
		where 
			khhinshi_id!=99999 and genkei.nouse=0
	",1)->hundle->fetch->[0];
	
	my $koto = mysql_exec->select("
		select count(*)
		from genkei
		where
			khhinshi_id!=99999 and genkei.nouse=0
	",1)->hundle->fetch->[0];
	
	unless ($total){return 0;}
	
	return sprintf("%.2f",($koto / $total) * 100)."%";
}

1;
