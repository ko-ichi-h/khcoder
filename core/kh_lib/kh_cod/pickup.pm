# 「部分テキストの取り出し」->「特定のコードが与えられた文書だけ」コマンド
#                                                         のためのロジック

package kh_cod::pickup;
use base qw(kh_cod);
use strict;

my $records_per_once = 5000;


sub pick{
	my $self = shift;
	my %args = @_;
	
	use Benchmark;                                    # 時間計測用
	my $t0 = new Benchmark;                           # 時間計測用
	
	# 取り合えずコーディング
	my $the_code = $self->{codes}[$args{selected}];
	$the_code->ready($args{tani});
	$the_code->code('ct_pickup');
	unless ($the_code->res_table){
		gui_errormsg->open(
			type => 'msg',
			msg  =>
				"選択されたコードは、どの文書にも与えられませんでした。\n".
				"ファイル作製は中止されました。"
		);
		return 0;
	}

	# 書き出し（テキスト）
	open (F, '>:encoding(utf8)', $args{file}) or
		gui_errormsg->open(
			thefile => $args{file},
			type    => 'file'
		);

	my $last = 0;
	my $last_seq = 0;
	my $id = 1;
	my $bun_num = mysql_exec->select("SELECT MAX(id) FROM bun")
		->hundle->fetch->[0]; # データに含まれる文の数

	while ($id <= $bun_num){
		my $sth = mysql_exec->select(
			$self->sql(
				tani    => $args{tani},
				pick_hi => $args{pick_hi},
				d1      => $id,
				d2      => $id + $records_per_once,
			),
			1
		)->hundle;
		#unless ($sth->rows > 0){
		#	last;
		#}
		$id += $records_per_once;

		while (my $i = $sth->fetchrow_hashref){
			if ($i->{bun_id} == 0 && $i->{dan_id} == 0){    # 見出し行
				if ($last){
					print F "\n";
				}
				print F "$i->{rowtxt}\n" if $args{pick_hi};
				$last = 0;
			} else {
				if ($last == $i->{dan_id}){     # 同じ段落の続き
					if (                  # 文単位の場合の特殊処理
						   ($args{tani} eq 'bun')
						&! ($last_seq + 1 == $i->{seq})
					){
						print F "\n$i->{rowtxt}";
						print ".";
					} else {
						print F "$i->{rowtxt}";
						print "-";
					}
				}
				else {      # 段落の変わり目
					print F "\n" if $last;# 直前が見出しでなければ改行付加
					print F "$i->{rowtxt}";
					$last = $i->{dan_id};
				}
			}
			$last_seq = $i->{seq};
		}
		print "$id,";
	}
	close (F);
	my $t1 = new Benchmark;                           # 時間計測用
	print timestr(timediff($t1,$t0)),"\n";            # 時間計測用


	# 書き出し（外部変数）
	my $var_file = $args{file};                   # 出力ファイル名
	if ($var_file =~ /(.+)\.txt/){
		$var_file = $1."_var.csv";
	} else {
		$var_file .= "_var.csv";
	}
	
	my @vars = ();                                # 変数のリストを作成
	my %tani_check = ();
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$tani_check{$i} = 1;
		last if ($args{tani} eq $i);
	}
	my $h = mysql_outvar->get_list;
	my @options = ();
	foreach my $i (@{$h}){
		if ($tani_check{$i->[0]}){
			push @vars, $i->[2];
		}
	}
	my $tani = $args{tani};
	
	if (@vars){
		my $vd;                                       # 変数データを読み出し
		my @vnames = ();
		foreach my $i (@vars){
			my $var_obj = mysql_outvar::a_var->new(undef,$i);
			push @vnames, $var_obj->{name};
			my $sql = '';
			if ( $var_obj->{tani} eq $tani){
				$sql .= "SELECT $var_obj->{column}\n";
				$sql .= "FROM $var_obj->{table}, ct_pickup\n";
				$sql .= "WHERE $var_obj->{table}.id = ct_pickup.id\n";
				$sql .= "    AND ct_pickup.num >= 1\n";
				$sql .= "ORDER BY $var_obj->{table}.id";
			} else {
				$sql .= "SELECT $var_obj->{table}.$var_obj->{column}\n";
				
				$sql .= "FROM ct_pickup, $tani\n";
				$sql .= "LEFT JOIN $var_obj->{tani} ON\n";
				my $n = 0;
				foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
					$sql .= "\t";
					$sql .= "and " if $n;
					$sql .= "$var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
					++$n;
					last if ($var_obj->{tani} eq $i);
				}
				$sql .= "LEFT JOIN $var_obj->{table} ON $var_obj->{tani}.id = $var_obj->{table}.id\n";
				$sql .= "WHERE $tani.id = ct_pickup.id\n";
				$sql .= "    AND ct_pickup.num >= 1\n";
				$sql .= "ORDER BY $tani.id";
				#print "\n$sql\n";
			}
		
			my $h = mysql_exec->select($sql,1)->hundle;
			while (my $i = $h->fetch){
				if ( length( $var_obj->{labels}{$i->[0]} ) ){
					push
						@{$vd->{$var_obj->{name}}},
						$var_obj->{labels}{$i->[0]}
					;
				} else {
					push @{$vd->{$var_obj->{name}}}, $i->[0];
				}
			}
		}
		
		use File::BOM;
		open my $fh, '>:encoding(utf8):via(File::BOM)' ,$var_file or # ファイルへ書き出し
			gui_errormsg->open(
				thefile => $var_file,
				type    => 'file'
			);
		
		my $t = '';                                             # 1行目
		foreach my $i (@vnames){
			$t .= kh_csv->value_conv($i).',';
		}
		chop $t;
		print $fh "$t\n";
		
		my $n = @{$vd->{$vnames[0]}} - 1;                        # 2行目以降
		for (my $i = 0; $i <= $n; ++$i){
			my $t = '';
			foreach my $name (@vnames){
				$t .= kh_csv->value_conv( $vd->{$name}[$i] ).',';
			}
			chop $t;
			print $fh "$t\n";
		}
		close($fh);
	}
	
	return 1;
}

sub sql{
	my $self = shift;
	my %args = @_;
	
	my $sql;
	#if ($args{pick_hi}){
		$sql .= "SELECT bun.bun_id, bun.dan_id, bun_r.rowtxt, bun.id as seq\n";
		$sql .= "FROM bun_r, bun\n";
		unless ($args{tani} eq 'bun'){
			$sql .= "	LEFT JOIN $args{tani} ON\n";
			my $flag = 0;
			foreach my $i ('bun','dan','h5','h4','h3','h2','h1'){
				if ($i eq $args{tani}){ ++$flag;}
				if ($flag) {
					if ($flag > 1){
						$sql .="\t\tAND bun.$i"."_id = $args{tani}.$i"."_id\n";
					} else {
						$sql .="\t\t    bun.$i"."_id = $args{tani}.$i"."_id\n";
					}
					++$flag;
				}
			}
		}
		$sql .= "\tLEFT JOIN ct_pickup ON ct_pickup.id = $args{tani}.id\n";
		$sql .= "WHERE\n";
		$sql .= "
			    bun.id = bun_r.id
			AND bun.id >= $args{d1}
			AND bun.id <  $args{d2}
			AND (
				IFNULL(ct_pickup.num,0)
				OR
				(
					    bun.bun_id = 0
					AND bun.dan_id = 0
					AND bun.$args{tani}"."_id  = 0
				)
			)
		";
	#} else {
	#	$sql .= "SELECT bun.bun_id, bun.dan_id, bun_r.rowtxt, bun.id as seq\n";
	#	if ($args{tani} eq 'bun'){
	#		$sql .= "FROM bun, bun_r, ct_pickup\n";
	#	} else {
	#		$sql .= "FROM bun, bun_r, $args{tani}, ct_pickup\n";
	#	}
	#	$sql .= "WHERE\n";
	#	$sql .= "	    bun.id = bun_r.id\n";
	#	$sql .= "	AND bun.id >= $args{d1}\n";
	#	$sql .= "	AND bun.id <  $args{d2}\n";
	#	$sql .= "	AND ct_pickup.id = $args{tani}.id\n";
	#	unless ($args{tani} eq 'bun'){
	#		my $flag = 0;
	#		foreach my $i ('bun','dan','h5','h4','h3','h2','h1'){
	#			if ($i eq $args{tani}){$flag=1;}
	#			if ($flag) {
	#				$sql .= "\t\tAND bun.$i"."_id = $args{tani}.$i"."_id\n";
	#			}
	#		}
	#	}
	#}
	
	return $sql;
}


1;