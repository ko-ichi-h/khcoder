package mysql_crossout::r_com;
use base qw(mysql_crossout);
use strict;
use utf8;

sub run{
	my $self = shift;
	
	use Benchmark;
	
	# 見出しの取得
	$self->{midashi} = mysql_getheader->get_selected(tani => $self->{tani2});

	$self->make_list;

	$self->{tani} = $self->{tani2};

	# random sampling
	$self->{th} = 2;
	if ($self->{sampling}) {
		my $target = $self->{sampling};
		my $n = mysql_exec->select("select count(*) from $self->{tani}",1)->hundle->fetch->[0];
		if ($target < $n){
			$self->{th} = $target / $n;
			$self->{th} = sprintf("%.5f",$self->{th});
		}
		print "sampling th: $self->{th}\n";
	}

	my $t0 = new Benchmark;
	$self->out2;
	#$self->finish;
	
	my $t1 = new Benchmark;
	print "\n",timestr(timediff($t1,$t0)),"\n";
	
	print "Data matrix for R: $self->{num_w} words x $self->{num_ra} ($self->{num_r}) docs\n";
	
	return $self->{r_command};
}

#----------------#
#   データ作製   #

sub out2{                               # length作製をする
	my $self = shift;

	# 無視する語をリストアップ
	my %ignore;
	my $h = mysql_exec->select(
		"SELECT id FROM genkei WHERE ( nouse = 1 ) OR khhinshi_id = 99999",
		1
	)->hundle;
	print "ignore: ";
	while (my $i = $h->fetch) {
		$ignore{$i->[0]} = 1;
		print "$i->[0],";
	}
	print "\n";
	
	# hyoso2テーブルを作成
	mysql_exec->do("DROP TABLE IF EXISTS hyoso2", 1);
	my $sql1 = "
		CREATE TABLE hyoso2(
			id INT primary key,
			len INT,
			genkei_id INT
		)";
	$sql1 .= " ENGINE = MEMORY" if $::config_obj->use_heap;
	mysql_exec->do($sql1, 1);
	
	mysql_exec->do("
		INSERT INTO hyoso2 (id, len, genkei_id)
		SELECT id, len, genkei_id
		FROM hyoso
		",
		1
	);
	
	# データを保存するファイル
	my $file = $::project_obj->file_TempR;
	#my $icode = 'UTF-8';
	#if (
	#	$::project_obj->morpho_analyzer_lang eq 'ru'
	#	&& $::config_obj->os eq 'win32'
	#) {
	#	$icode = 'cp1251';
	#}
	
	open my $fh, ">:encoding(UTF-8)", $file or # $icode
		gui_errormsg->open(
			type    => 'file',
			thefile => $file,
		);
	
	print $fh "d <- NULL\n";
	print $fh "d <- matrix( c(";
	
	my $row_names = '';
	
	my $length = 'doc_length_mtr <- matrix( c( ';
	
	my $num_r  = 0;
	my $num_ra = 0;
	srand 11;
	
	# セル内容の作製
	my $id = 1;
	my $last = 1;
	my $increment = 30000;
	my $started = 0;
	my %current = ();
	while (1){
		my $sth = mysql_exec->select(
			$self->sql2($id, $id + $increment),
			1
		)->hundle;
		$id += $increment;
		unless ($sth->rows > 0){
			last;
		}
		
		while (my $i = $sth->fetch){
			if ($last != $i->[0] && $started == 1){
				# 書き出し
				my $temp = "$last,";
				foreach my $h (@{$self->{wList}} ){
					if ($current{$h}){
						$temp .= "$current{$h},";
					} else {
						$temp .= "0,";
					}
				}
				chop $temp;
				$current{length_c} = "0" unless length($current{length_c});
				$current{length_w} = "0" unless length($current{length_w});
				if (rand() <= $self->{th}) {
					print $fh "," if $num_ra;
					print $fh "$temp\n";
					$length .= "$current{length_c},$current{length_w},";
					if ($self->{midashi}){
						$self->{midashi}->[$last - 1] =~ s/"/ /g;
						$row_names .= '"'.$self->{midashi}->[$last - 1].'",';
					}
					++$num_ra;
				}
				# 初期化
				%current = ();
				$last = $i->[0];
				++$num_r;
			}
			
			$last = $i->[0] unless $started;
			$started = 1;
			
			# HTMLタグと未使用語を無視
			if ( $ignore{$i->[1]} ){
				next;
			}
			
			# 集計
			++$current{'length_w'};
			#$current{'length_c'} += length($i->[2]);
			$current{'length_c'} += $i->[2];
			if ($self->{wName}{$i->[1]}){
				++$current{$i->[1]};
			}
		}
		$sth->finish;
	}
	
	# 最終行の出力
	my $temp = "$last,";
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
	$current{length_c} = "0" unless length($current{length_c});
	$current{length_w} = "0" unless length($current{length_w});
	if (rand() <= $self->{th}) {
		++$num_ra;
		print $fh "," if $num_ra;
		print $fh "$temp), byrow=T, nrow=$num_ra, ncol=$ncol )\n";
		$length .= "$current{length_c},$current{length_w},";
		if ($self->{midashi}){
			$self->{midashi}->[$last - 1] =~ s/"/ /g;
			$row_names .= '"'.$self->{midashi}->[$last - 1].'",';
		}
	} else {
		print $fh "), byrow=T, nrow=$num_ra, ncol=$ncol )\n";
	}
	chop $row_names;
	
	# データ整形
	if ($self->{rownames}){
		if ($self->{midashi}){
			$row_names = kh_r_plot->escape_unicode($row_names);
			print $fh "row.names(d) <- c($row_names)\n";
		} else {
			print $fh "row.names(d) <- d[,1]\n";
		}
	}

	print $fh "d <- d[,-1]\n";

	my $colnames = '';
	$colnames .= "colnames(d) <- c(";
	foreach my $i (@{$self->{wList}}){
		my $t;
		if ($self->{not_word_but_id}) {
			$t = $i;
		} else {
			$t = $self->{wName}{$i};
			$t =~ s/"/ /g;
		}
		$colnames .= "\"$t\",";
	}
	chop $colnames;
	$colnames .= ")\n";
	$colnames = kh_r_plot->escape_unicode($colnames);
	print $fh $colnames;

	chop $length;
	$length .= "), ncol=2, byrow=T)\n";
	$length .= "colnames(doc_length_mtr) <- c(\"length_c\", \"length_w\")\n";
	print $fh $length;
	close($fh);

	$self->{num_ra} = $num_ra;
	$self->{num_r} = $num_r;

	# Rコマンド
	$file = $::config_obj->uni_path($file);
	$self->{r_command} = "source(\"$file\", encoding=\"UTF-8\")\n";
	
	#if ($icode eq 'UTF-8') {
	#	$self->{r_command} = "source(\"$file\", encoding=\"UTF-8\")\n";
	#}
	#else { # for Russian on Win32
	#	$self->{r_command} = "source(\"$file\")\n";
	#}

	return $self;
}


#--------------------------#
#   出力する単語数を返す   #

sub wnum{
	my $self = shift;
	my $nc   = shift;
	
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
	unless ($nc){
		1 while s/(.*\d)(\d\d\d)/$1,$2/; # 位取り用のコンマを挿入
	}
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