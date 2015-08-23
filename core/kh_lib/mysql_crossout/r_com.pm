package mysql_crossout::r_com;
use base qw(mysql_crossout);
use strict;

sub run{
	my $self = shift;
	
	use Benchmark;
	
	# 見出しの取得
	$self->{midashi} = mysql_getheader->get_selected(tani => $self->{tani2});

	$self->make_list;

	$self->{tani} = $self->{tani2};

	my $t0 = new Benchmark;
	$self->out2;
	#$self->finish;
	
	my $t1 = new Benchmark;
	print "\n",timestr(timediff($t1,$t0)),"\n";
	
	print "Data matrix for R: $self->{num_w} words x $self->{num_r} docs\n";
	
	return $self->{r_command};
}

#----------------#
#   データ作製   #

sub out2{                               # length作製をする
	my $self = shift;
	
	# データを保存するファイル
	my $file = $::project_obj->file_TempR;
	open my $fh, '>:encoding(utf8)', $file or
		gui_errormsg->open(
			type    => 'file',
			thefile => $file,
		);
	
	print $fh "d <- NULL\n";
	print $fh "d <- matrix( c(";
	
	my $row_names = '';
	
	my $length = 'doc_length_mtr <- matrix( c( ';
	
	my $num_r = 0;
	
	# セル内容の作製
	my $id = 1;
	my $last = 1;
	my %current = ();
	while (1){
		my $sth = mysql_exec->select(
			$self->sql2($id, $id + 100),
			1
		)->hundle;
		$id += 100;
		unless ($sth->rows > 0){
			last;
		}
		
		while (my $i = $sth->fetch){
			if ($last != $i->[0]){
				# 書き出し
				my $temp = "$last,";
				if ($self->{midashi}){
					$self->{midashi}->[$last - 1] =~ s/"/ /g;
					$row_names .= '"'.$self->{midashi}->[$last - 1].'",';
				}
				foreach my $h (@{$self->{wList}} ){
					if ($current{$h}){
						$temp .= "$current{$h},";
					} else {
						$temp .= "0,";
					}
				}
				chop $temp;
				print $fh "$temp,\n";
				$current{length_c} = "0" unless length($current{length_c});
				$current{length_w} = "0" unless length($current{length_w});
				$length .= "$current{length_c},$current{length_w},";
				# 初期化
				%current = ();
				$last = $i->[0];
				++$num_r;
			}
			
			# HTMLタグを無視
			if (
				!  ( $self->{use_html} )
				&& ( $i->[2] =~ /<[h|H][1-5]>|<\/[h|H][1-5]>/o )
			){
				next;
			}
			# 未使用語を無視
			if ($i->[3]){
				next;
			}
			
			# 集計
			++$current{'length_w'};
			$current{'length_c'} += (length($i->[2]) / 2);
			if ($self->{wName}{$i->[1]}){
				++$current{$i->[1]};
			}
		}
		$sth->finish;
	}
	
	# 最終行の出力
	my $temp = "$last,";
	if ($self->{midashi}){
		$self->{midashi}->[$last - 1] =~ s/"/ /g;
		$row_names .= '"'.$self->{midashi}->[$last - 1].'",';
	}
	foreach my $h (@{$self->{wList}} ){
		if ($current{$h}){
			$temp .= "$current{$h},";
		} else {
			$temp .= "0,";
		}
	}
	++$num_r;
	my $ncol = @{$self->{wList}} + 1;
	chop $temp;
	print $fh "$temp), byrow=T, nrow=$num_r, ncol=$ncol )\n";
	$current{length_c} = "0" unless length($current{length_c});
	$current{length_w} = "0" unless length($current{length_w});
	$length .= "$current{length_c},$current{length_w},";
	chop $row_names;
	
	# データ整形
	if ($self->{rownames}){
		if ($self->{midashi}){
			print $fh "row.names(d) <- c($row_names)\n";
		} else {
			print $fh "row.names(d) <- d[,1]\n";
		}
	}

	print $fh "d <- d[,-1]\n";

	my $colnames = '';
	$colnames .= "colnames(d) <- c(";
	foreach my $i (@{$self->{wList}}){
		my $t = $self->{wName}{$i};
		$t =~ s/"/ /g;
		$colnames .= "\"$t\",";
	}
	chop $colnames;
	$colnames .= ")\n";
	print $fh $colnames;

	chop $length;
	$length .= "), ncol=2, byrow=T)\n";
	$length .= "colnames(doc_length_mtr) <- c(\"length_c\", \"length_w\")\n";
	print $fh $length;
	close($fh);

	$self->{num_r} = $num_r;

	# Rコマンド
	$file = $::config_obj->uni_path($file);
	$self->{r_command} = "source(\"$file\", encoding=\"UTF-8\")\n";

	return $self;
}


#--------------------------#
#   出力する単語数を返す   #

sub wnum{
	my $self = shift;
	
	$self->{min_df} = 0 unless length($self->{min_df});
	
	my $sql = '';
	$sql .= "SELECT count(*)\n";
	$sql .= "FROM   genkei, hselection, df_$self->{tani}";
	if ($self->{tani2} and not $self->{tani2} eq $self->{tani}){
		$sql .= ", df_$self->{tani2}\n";
	} else {
		$sql .= "\n";
	}
	$sql .= "WHERE\n";
	$sql .= "	    genkei.khhinshi_id = hselection.khhinshi_id\n";
	$sql .= "	AND genkei.num >= $self->{min}\n";
	$sql .= "	AND genkei.nouse = 0\n";
	$sql .= "	AND genkei.id = df_$self->{tani}.genkei_id\n";
	if ($self->{tani2} and not $self->{tani2} eq $self->{tani}){
		$sql .= "	AND genkei.id = df_$self->{tani2}.genkei_id\n";
		$sql .= "	AND df_$self->{tani2}.f >= 1\n";
	}
	$sql .= "	AND df_$self->{tani}.f >= $self->{min_df}\n";
	$sql .= "	AND (\n";
	
	my $n = 0;
	foreach my $i ( @{$self->{hinshi}} ){
		if ($n){ $sql .= ' OR '; }
		$sql .= "hselection.khhinshi_id = $i\n";
		++$n;
	}
	$sql .= ")\n";
	if ($self->{max}){
		$sql .= "AND genkei.num <= $self->{max}\n";
	}
	if ($self->{max_df}){
		$sql .= "AND df_$self->{tani}.f <= $self->{max_df}\n";
	}
	#print "$sql\n";
	
	$_ = mysql_exec->select($sql,1)->hundle->fetch->[0];
	1 while s/(.*\d)(\d\d\d)/$1,$2/; # 位取り用のコンマを挿入
	return $_;
}

#--------------------------------#
#   出力する単語をリストアップ   #

# tani2による文書数設定が可能な修正版

sub make_list{
	my $self = shift;
	
	# 単語リストの作製
	my $sql = '';
	$sql .= "SELECT genkei.id, genkei.name, hselection.khhinshi_id\n";
	$sql .= "FROM   genkei, hselection, df_$self->{tani}";
	if ($self->{tani2} and not $self->{tani2} eq $self->{tani}){
		$sql .= ", df_$self->{tani2}\n";
	} else {
		$sql .= "\n";
	}
	$sql .= "WHERE\n";
	$sql .= "	    genkei.khhinshi_id = hselection.khhinshi_id\n";
	$sql .= "	AND genkei.num >= $self->{min}\n";
	$sql .= "	AND genkei.nouse = 0\n";
	if ($self->{tani2} and not $self->{tani2} eq $self->{tani}){
		$sql .= "	AND genkei.id = df_$self->{tani2}.genkei_id\n";
		$sql .= "	AND df_$self->{tani2}.f >= 1\n";
	}
	$sql .= "	AND genkei.id = df_$self->{tani}.genkei_id\n";
	$sql .= "	AND df_$self->{tani}.f >= $self->{min_df}\n";
	$sql .= "	AND (\n";

	my $n = 0;
	foreach my $i ( @{$self->{hinshi}} ){
		if ($n){ $sql .= ' OR '; }
		$sql .= "hselection.khhinshi_id = $i\n";
		++$n;
	}
	$sql .= ")\n";
	if ($self->{max}){
		$sql .= "AND genkei.num <= $self->{max}\n";
	}
	if ($self->{max_df}){
		$sql .= "AND df_$self->{tani}.f <= $self->{max_df}\n";
	}
	$sql .= "ORDER BY khhinshi_id, genkei.num DESC, ";
	$sql .= $::project_obj->mysql_sort('genkei.name');
	
	my $sth = mysql_exec->select($sql, 1)->hundle;
	my (@list, %name, %hinshi);
	while (my $i = $sth->fetch) {
		push @list,        $i->[0];
		$name{$i->[0]}   = $i->[1];
		$hinshi{$i->[0]} = $i->[2];
	}
	$sth->finish;
	$self->{wList}   = \@list;
	$self->{wName}   = \%name;
	$self->{wHinshi} = \%hinshi;
	$self->{num_w} = @list;
	
	# 品詞リストの作製
	$sql = '';
	$sql .= "SELECT khhinshi_id, name\n";
	$sql .= "FROM   hselection\n";
	$sql .= "WHERE\n";
	$n = 0;
	foreach my $i ( @{$self->{hinshi}} ){
		if ($n){ $sql .= ' OR '; }
		$sql .= "khhinshi_id = $i\n";
		++$n;
	}
	$sth = mysql_exec->select($sql, 1)->hundle;
	while (my $i = $sth->fetch) {
		$self->{hName}{$i->[0]} = $i->[1];
		if ($i->[1] eq 'HTMLタグ' || $i->[1] eq 'HTML_TAG'){
			$self->{use_html} = 1;
		}
	}
	
	return $self;
}

1;