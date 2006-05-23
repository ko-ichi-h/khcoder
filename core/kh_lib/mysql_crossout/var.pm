package mysql_crossout::var;
use base qw(mysql_crossout);
use strict;

sub sql3{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;

	my $sql;
	$sql .= "SELECT $self->{tani}.id, genkei.name, khhinshi.id\n";
	$sql .= "FROM   hyosobun, hyoso, genkei, khhinshi, $self->{tani}\n";
	$sql .= "WHERE\n";
	$sql .= "	hyosobun.hyoso_id = hyoso.id\n";
	$sql .= "	AND hyoso.genkei_id = genkei.id\n";
	$sql .= "	AND genkei.khhinshi_id = khhinshi.id\n";

	my $flag = 0;
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($i eq $self->{tani}){ $flag = 1; }
		if ($flag){
			$sql .= "	AND hyosobun.$i"."_id = $self->{tani}.$i"."_id\n";
		}
	}
	$sql .= "	AND genkei.nouse = 0\n";
	$sql .= "	AND genkei.num >= $self->{min}\n";
	if ($self->{max}){
		$sql .= "	AND genkei.num <= $self->{max}\n";
	}
	$sql .= "	AND (\n";
	my $n = 0;
	foreach my $i ( @{$self->{hinshi}} ){
		if ($n){
			$sql .= '		OR ';
		} else {
			$sql .= "		";
		}
		$sql .= "khhinshi.id = $i\n";
		++$n;
	}
	$sql .= "	)\n";
	$sql .= "	AND $self->{tani}.id >= $d1\n";
	$sql .= "	AND $self->{tani}.id <  $d2\n";
	$sql .= "ORDER BY hyosobun.id";
	return $sql;
}

sub sql4{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;

	my $sql;
	$sql .= "SELECT $self->{tani}.id, genkei.name, genkei.nouse\n";
	$sql .= "FROM   hyosobun, hyoso, genkei, $self->{tani}\n";
	$sql .= "WHERE\n";
	$sql .= "	hyosobun.hyoso_id = hyoso.id\n";
	$sql .= "	AND hyoso.genkei_id = genkei.id\n";

	my $flag = 0;
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($i eq $self->{tani}){ $flag = 1; }
		if ($flag){
			$sql .= "	AND hyosobun.$i"."_id = $self->{tani}.$i"."_id\n";
		}
	}
	$sql .= "	AND $self->{tani}.id >= $d1\n";
	$sql .= "	AND $self->{tani}.id <  $d2\n";
	$sql .= "ORDER BY hyosobun.id";
	return $sql;
}


sub out2{
	my $self = shift;
	
	# セル内容の作製(1)
	my $id = 1;
	my $last = 1;
	my %current = ();
	my %data;
	while (1){
		my $sth = mysql_exec->select(
			$self->sql3($id, $id + 100),
			1
		)->hundle;
		$id += 100;
		unless ($sth->rows > 0){
			last;
		}
		while (my $i = $sth->fetch){
			if ($last != $i->[0]){
				# 書き出し
				my $temp;
				foreach my $h ( @{$self->{hinshi}} ){
					if ($current{$h}){
						chop $current{$h};
						$temp .= kh_csv->value_conv($current{$h}).',';
					} else {
						$temp .= ",";
					}
				}
				chop $temp;
				$data{$last} = $temp;
				# 初期化
				%current = ();
				$last = $i->[0];
			}
			# 集計
			$current{$i->[2]} .= "$i->[1] ";
		}
		$sth->finish;
	}
	# 最終行の出力
	my $temp;
	foreach my $h ( @{$self->{hinshi}} ){
		if ($current{$h}){
			chop $current{$h};
			$temp .= kh_csv->value_conv($current{$h}).',';
		} else {
			$temp .= ",";
		}
	}
	chop $temp;
	$data{$last} = $temp;
	$self->{data} = \%data;
	# 欠損ケース用
	foreach my $h ( @{$self->{hinshi}} ){
		$self->{data}{kesson} .= ',';
	}
	chop $self->{data}{kesson};
	
	
	# セル内容の作製(2)
	$id = 1;
	$last = 1;
	my $current;
	my %data2;
	while (1){
		my $sth = mysql_exec->select(
			$self->sql4($id, $id + 100),
			1
		)->hundle;
		$id += 100;
		unless ($sth->rows > 0){
			last;
		}
		while (my $i = $sth->fetch){
			if ($last != $i->[0]){
				# 書き出し
				chop $current;
				$data2{$last} = kh_csv->value_conv($current);
				# 初期化
				$current = '';
				$last = $i->[0];
			}
			# 集計
			$current .= "$i->[1] "
				unless ($i->[1] eq '---無記入・空白---' and $i->[2]);
		}
		$sth->finish;
	}
	# 最終行の出力
	if ( length($current) ){
		chop $current;
		$data2{$last} = kh_csv->value_conv($current);
	}
	$self->{data2} = \%data2;
	
	return $self;
}

sub finish{
	my $self = shift;
	
	open (OUTF,">$self->{file}") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $self->{file},
		);
	
	# ヘッダ行の作製
	my $head = ''; my @head;
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$head .= "$i,";
		push @head, $i;
		if ($self->{tani} eq $i){
			last;
		}
	}
	$head .= "id,length_c,length_w,茶筌出力（基本形）,";
	foreach my $i (@{$self->{hinshi}}){
		$head .= kh_csv->value_conv($self->{hName}{$i}).',';
	}
	chop $head;

	print OUTF "$head\n";
	
	# 位置情報とのマージ
	
	my $sql;
	$sql .= "SELECT ";
	foreach my $i (@head){
		$sql .= "$i"."_id,";
	}
	$sql .= "$self->{tani}.id, $self->{tani}_length.c, $self->{tani}_length.w";
	$sql .= "\nFROM $self->{tani}, $self->{tani}"."_length\n";
	$sql .= "WHERE $self->{tani}.id = $self->{tani}"."_length.id\n";
	$sql .= "ORDER BY $self->{tani}.id";
	my $sth = mysql_exec->select($sql,1)->hundle;
	
	my $n = 1;
	while (my $srow = $sth->fetch){
		my $head;
		foreach my $i (@{$srow}){
			$head .= "$i,"
		}
		if ($self->{data}{$n}){
			print OUTF "$head"."$self->{data2}{$n},$self->{data}{$n}\n";
		} else {
			print OUTF "$head"."$self->{data2}{$n},$self->{data}{kesson}\n";
		}
		++$n;
	}
	close (OUTF);
	$self->{data} = '';
	
	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_sjis($self->{file});
	}
}



1;