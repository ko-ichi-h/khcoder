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
	
	my $query = $args{query};
	$query =~ s/　/ /g;
	my @query = split / /, $query;
	
	my $sql;
	if ($args{kihon}){
		$sql = '
			SELECT
				genkei.name, hselection.name, genkei.num
			FROM
				genkei, hselection
			WHERE
				    genkei.khhinshi_id = hselection.khhinshi_id
				AND hselection.ifuse = 1'."\n";
		$sql .= "\t\t\tAND (\n";
	} else {
		$sql = '
			SELECT
				hyoso, hinshi, katuyo, count(*) as num
			FROM
				rowdata
			WHERE
				';
	}

	# SQL文に検索対象語を投入
	foreach my $i (@query){
		my $word;
		if ($i =~ /%/){
			$word = "'$i'";
		} else {
			$word = "'%$i%'";
		}
		if ($args{kihon}){
			$sql .= "\t\t\t\tgenkei.name LIKE $word";
		} else {
			$sql .= "\t\t\t\thyoso LIKE $word";
		}
		if ($args{method} eq 'AND'){
			$sql .= " AND\n";
		} else {
			$sql .= " OR\n";
		}
	}
	substr($sql,-4,3) = '';
	
	if ($args{kihon}){
		$sql .= "\t\t\t)\n\t\tORDER BY\n\t\t\tgenkei.num DESC";
	} else {
		$sql .= 'GROUP BY hyoso ORDER BY num DESC';
	}
	
#	print "\n$sql\n";
	
	my $t = mysql_exec->select($sql,1);
	my $result = $t->hundle->fetchall_arrayref;
	return $result;
}

#-------------------------#
#   CSV形式リストの出力   #

sub csv_list{
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
		$line .= "$i->[0],,";
	}
	chop $line;
	print LIST "$line\n";
	# 2行目以降
	my $row = 0;
	while (1){
		my $line = '';
		my $check;
		foreach my $i (@{$list}){
			$line .= "$i->[1][$row][0],$i->[1][$row][1],";
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

sub spss_freq{
	my $class = shift;
	my $target = shift;
	
	my $list = &_make_list;

	my $text = '';
	$text .= "data list list(',')\n";
	$text .= "  /抽出語(a255) 品詞(a10) 出現回数(f10.0).\n";
	$text .= "BEGIN DATA\n";

	foreach my $i (@{$list}){
		foreach my $h (@{$i->[1]}){
			$text .= "$h->[0],$i->[0],$h->[1]\n";
		}
	}

	$text .= "END DATA.\n";
	$text .= "EXECUTE .\n";
	$text .= "FREQUENCIES\n";
	$text .= "  VARIABLES=出現回数\n";
	$text .= "  /NTILES=  4\n";
	$text .= "  /STATISTICS=MEAN MEDIAN MODE SUM\n";
	$text .= "  /ORDER=  ANALYSIS .\n";

	open (LIST,">$target") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$target"
		);
	print LIST $text;
	close (LIST);
	kh_jchar->to_sjis($target);
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
		print "damn!!!!!!!!!!!!\n";
		return;
	}

	my @hinshi = @{$temp};
	# 単語リストアップ
	my @result = ();
	foreach my $i (@hinshi){
		my $sql = '';
		$sql  = "SELECT name, num FROM genkei ";
		$sql .= "WHERE khhinshi_id = $i->[1] ";
		$sql .= "ORDER BY num DESC";
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
	$sql .= "WHERE\n";
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
	return mysql_exec->select($sql,1)->hundle->fetch->[0];
}
sub num_kinds_all{
	return mysql_exec                   # HTMLタグを除く単語種類数を返す
		->select("select count(*) from genkei where  khhinshi_id!=99999",1)
			->hundle->fetch->[0];
}
sub num_all{
	return mysql_exec                   # HTMLタグを除く単語数を返す
		->select("select sum(num) from genkei where  khhinshi_id!=99999",1)
			->hundle->fetch->[0];
}

1;
