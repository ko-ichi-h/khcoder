package kh_nbayes;

use strict;
use List::Util qw(max sum);
use Algorithm::NaiveBayes;
use Algorithm::NaiveBayes::Model::Frequency;

# 学習関連
# ・学習結果の内容を確認
# ・外部変数の出力機能
# ・分類結果の詳細をログに出力する機能
# ※このファイルのリファクタリング: オブジェクト化／カプセル化

#----------#
#   学習   #

sub learn_from_ov{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	bless $self, $class;

	unless ( length($self->{max}) ){
		$self->{max} = 0;
	}

	# 既存のファイルに追加するかどうか
	if ($self->{add_data}){
		$self->{cls} = Algorithm::NaiveBayes->restore_state($self->{path});
		rename($self->{path}, $self->{path}.'.tmp');
	} else {
		$self->{cls} = Algorithm::NaiveBayes->new(purge => 0);
	}

	# 学習モードにセット
	$self->{mode} = 't';
	$self->{command} = sub {
		my $current = shift;
		my $last    = shift;
		$self->add($current,$last);
	} ;

	# 準備
	$self->make_list;
	$self->get_ov;

	# 実行
	print "Start training... ";
	$self->{train_cnt} = 0;
	$self->out2;
	$self->{cls}->train;
	print $self->{cls}->instances, " instances. ok.\n";

	unlink($self->{path}) if -e $self->{path};
	$self->{cls}->save_state($self->{path});
	unlink($self->{path}.'.tmp');

	# use Data::Dumper;
	# print Dumper($self->{cls});

	my $n   = $self->{cls}->instances;
	my $n_c = $self->{train_cnt};

	# 交差妥当化
	my ($tested, $correct, $kappa);
	if ( $self->{cross_vl} ){
		my @labels = $self->{cls}->labels;
		
		print "Cross validation:\n";
		$self->cross_validate;
		
		$tested  = @{$self->{test_result}};
		$correct = 0;
		foreach my $i (@{$self->{test_result}}){
			++$correct if $i;
		}
		
		# kappaの計算
		my (%outvar, $outvar_n);
		foreach my $h (values %{$self->{outvar_cnt}}){
			unless (
				   length($h) == 0
				|| $h eq '.'
				|| $h eq '欠損値'
				|| $h =~ /missing/io
			){
				++$outvar{$h};
				++$outvar_n;
			}
		}
		
		my (%test, $test_n);
		foreach my $i ( @{$self->{test_result_raw}} ){
			++$test{$i};
			++$test_n;
		}
		
		my $pe = 0;
		foreach my $i (@labels){
			$pe += ($outvar{$i} / $outvar_n) * ( $test{$i} / $test_n );
		}
		
		my $pa = $correct / $tested;
		$kappa = ( $pa - $pe ) / ( 1 - $pe );
		
		print "Tested: $correct / $tested, kappa: $kappa\n";
	}

	undef $self;
	return {
		instances       => $n_c,
		instances_all   => $n,
		cross_vl_tested => $tested,
		cross_vl_ok     => $correct,
		kappa           => $kappa,
	};
}

sub add{
	my $self = shift;
	my $current = shift;
	my $last    = shift;
	unless (
		   length($self->{outvar_cnt}{$last}) == 0
		|| $self->{outvar_cnt}{$last} eq '.'
		|| $self->{outvar_cnt}{$last} eq '欠損値'
		|| $self->{outvar_cnt}{$last} =~ /missing/io
	){
		$self->{cls}->add_instance(
			attributes => $current,
			label      => $self->{outvar_cnt}{$last},
		);
		++$self->{train_cnt};
		
		# テストプリント
		# print "out: $last\n";
		# print Jcode->new("label: $self->{outvar_cnt}{$last}\n", 'euc')->sjis;
		# foreach my $h (keys %{$current}){
		# 	print Jcode->new("at: $h, $current->{$h}\n", 'euc')->sjis;
		# }
	}
	return 1;
}

#----------------#
#   交差妥当化   #

sub cross_validate{
	my $self = shift;
	
	# グループ分け
	my $groups = $self->{cross_fl}; # いくつのグループに分けるか
	
	my $member_order;
	foreach my $i (keys %{$self->{outvar_cnt}}){
		unless (
			   length($self->{outvar_cnt}{$i}) == 0
			|| $self->{outvar_cnt}{$i} eq '.'
			|| $self->{outvar_cnt}{$i} eq '欠損値'
			|| $self->{outvar_cnt}{$i} =~ /missing/io
		){
			$member_order->{$i} = rand();
		}
	}
	
	my $n = 1;
	foreach my $i (
		sort { $member_order->{$a} <=> $member_order->{$b} }
		keys %{$member_order}
	){
		$self->{member_group}{$i} = $n;
		# print "$i\t$n\n";
		++$n;
		$n = 1 if $n > $groups;
	}
	
	# 交差ループ
	$self->{test_result} = undef;
	$self->{test_result_raw} = undef;
	for (my $c = 1; $c <= $groups; ++$c){
		$self->{cross_vl_c} = $c;
		$self->{cls} = Algorithm::NaiveBayes->new;
		print "  fold $c: ";
		
		# 学習フェーズ
		$self->{mode} = 't';
		$self->{command} = sub {
			my $current = shift;
			my $last    = shift;
			$self->add_p($current,$last);
		};
		$self->out2;
		$self->{cls}->train;
		print "training ", $self->{cls}->instances, ",\t";

		# テストフェーズ
		$self->{test_count} = 0;
		$self->{test_count_hit} = 0;
		$self->{mode} = 'p';
		$self->{command} = sub {
			my $current = shift;
			my $last    = shift;
			$self->prd_p($current,$last);
		};
		$self->out2;
		print "test $self->{test_count_hit} / $self->{test_count}";
		print "\n";
	}
	
	return $self;
}

sub prd_p{
	my $self = shift;
	my $current = shift;
	my $last    = shift;
	
	unless ( $self->{cross_vl_c} == $self->{member_group}{$last} ){
		return 0;
	}
	
	my $r = $self->{cls}->predict(
		attributes => $current
	);
	
	my $cnt     = 0;
	my $max     = 0;
	my $max_lab = 0;
	foreach my $i (keys %{$r}){
		++$cnt if $r->{$i} >= 0.6;
		if ($max < $r->{$i}){
			$max = $r->{$i};
			$max_lab = $i;
		}
	}
	
	if (
		   $cnt == 1
		&& $max >= 0.8
	) {
		push @{$self->{test_result_raw}}, $max_lab;
		if ( $max_lab eq $self->{outvar_cnt}{$last} ){
			push @{$self->{test_result}}, 1;
			++$self->{test_count_hit};
		} else {
			push @{$self->{test_result}}, 0;
		}
	} else {
		push @{$self->{test_result_raw}}, '.';
		push @{$self->{test_result}}, 0;
	}
	
	++$self->{test_count};
	return 1;
}

sub add_p{
	my $self = shift;
	my $current = shift;
	my $last    = shift;
	if (
		    $self->{member_group}{$last}
		and $self->{cross_vl_c} != $self->{member_group}{$last}
	){
		$self->{cls}->add_instance(
			attributes => $current,
			label      => $self->{outvar_cnt}{$last},
		);
	}
	return 1;
}

#----------#
#   分類   #

sub predict{
	my $class = shift;
	my $self = {@_};
	bless $self, $class;
	
	# 学習結果の読み込み
	$self->{cls} = Algorithm::NaiveBayes->restore_state($self->{path});
	
	# 分類モードにセット
	$self->{mode} = 'p';
	$self->{command} = sub {
		my $current = shift;
		my $last    = shift;
		$self->prd($current,$last);
	} ;
	
	# 準備
	$self->make_hinshi_list;
	$self->{result} = undef;
	push @{$self->{result}}, [$self->{outvar}];
	
	# 実行
	$self->out2;
	
	# 保存
	my $type = 'INT';
	foreach my $i ($self->{cls}->labels){
		print "labels: $i\n";
		if ($i =~ /[^0-9]/){
			$type = 'varchar';
			last;
		}
	}
	&mysql_outvar::read::save(
		data     => $self->{result},
		tani     => $self->{tani},
		var_type => $type,
	) or return 0;
	return 1;
}

sub prd{
	my $self = shift;
	my $current = shift;
	my $last    = shift;
	
	my $r = $self->{cls}->predict(
		attributes => $current
	);
	
	my $cnt     = 0;
	my $max     = 0;
	my $max_lab = 0;
	foreach my $i (keys %{$r}){
		++$cnt if $r->{$i} >= 0.6;
		if ($max < $r->{$i}){
			$max = $r->{$i};
			$max_lab = $i;
		}
	}
	
	#print "$last: ";
	if (
		   $cnt == 1
		&& $max >= 0.8
	) {
		push @{$self->{result}}, [$max_lab];
		#print "$max_lab\n";
	} else {
		push @{$self->{result}}, ['.'];
		#print ".\n";
	}
	
	return 1;
}

#--------------------------#
#   学習に使用する語の数   #

# 効率化の余地がだいぶあるかも…

sub wnum{
	my $class = shift;
	my $self = {@_};
	bless $self, $class;

	return undef unless length($self->{tani});
	return undef unless length($self->{outvar});

	my $missing = 0;
	$self->get_ov;
	foreach my $i (values %{$self->{outvar_cnt}}){
		if (
			   length($i) == 0
			|| $i eq '.'
			|| $i eq '欠損値'
			|| $i =~ /missing/io
		){
			$missing = 1;
			last;
		}
	}
	
	if ( $missing == 0 ){     # 外部変数に欠損値がない場合
		my $check = mysql_crossout::r_com->new(
			tani   => $self->{tani},
			hinshi => $self->{hinshi},
			max    => $self->{max},
			min    => $self->{min},
			max_df => $self->{max_df},
			min_df => $self->{min_df},
		)->wnum;
		return $check;
	} else {                  # 外部変数に欠損値がある場合

		# カウントモードにセット
		$self->{mode} = 't';
		$self->{command} = sub {
			my $current = shift;
			my $last    = shift;
			$self->cnt($current,$last);
		} ;

		$self->make_list;
		$self->out2;

		$_ = keys %{$self->{count}};
		1 while s/(.*\d)(\d\d\d)/$1,$2/; # 位取り用のコンマを挿入
		return $_;
	}
}

sub cnt{
	my $self = shift;
	my $current = shift;
	my $last    = shift;
	unless (
		   length($self->{outvar_cnt}{$last}) == 0
		|| $self->{outvar_cnt}{$last} eq '.'
		|| $self->{outvar_cnt}{$last} eq '欠損値'
		|| $self->{outvar_cnt}{$last} =~ /missing/io
	){
		foreach my $k (keys %{$current}) {
			$self->{count}{$k} += $current->{$k};
		}
	}
	return $self;
}

#----------------#
#   データ操作   #

sub out2{
	my $self = shift;
	
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
				&{$self->{command}}(\%current, $last);
				
				# 初期化
				%current = ();
				$last = $i->[0];
			}

			if (
				   ( $self->{mode} eq 't' && $self->{wName}{$i->[1]} )
				|| ( $self->{mode} eq 'p' && $self->{hName}{$i->[3]} )
			){
				my $t = '';
				$t .= $i->[2];
				$t .= '-';
				$t .= $self->{hName}{$i->[3]};
				
				++$current{$t};
			}
		}
		$sth->finish;
	}
	
	# 最終行の書き出し
	&{$self->{command}}(\%current, $last);



	return $self;
}

sub sql2{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;


	my $sql;
	$sql .= "SELECT $self->{tani}.id, genkei.id, genkei.name, genkei.khhinshi_id\n";
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
	$sql .= "	AND genkei.nouse = 0\n";
	$sql .= "	AND $self->{tani}.id >= $d1\n";
	$sql .= "	AND $self->{tani}.id <  $d2\n";
	$sql .= "ORDER BY hyosobun.id";
	return $sql;
}

#------------------------#
#   外部変数の値を取得   #

sub get_ov{
	my $self = shift;

	my $var_obj = mysql_outvar::a_var->new(undef,$self->{outvar});
	
	my $sql = '';
	
	if ($self->{tani} eq $var_obj->{tani}){
		$sql .= "SELECT id, $var_obj->{column} FROM $var_obj->{table} ";
		$sql .= "ORDER BY id";
	} else {
		my $tani = $self->{tani};
		$sql .= "SELECT $tani.id, $var_obj->{table}.$var_obj->{column}\n";
		$sql .= "FROM $tani, $var_obj->{tani}, $var_obj->{table}\n";
		$sql .= "WHERE\n";
		$sql .= "	$var_obj->{tani}.id = $var_obj->{table}.id\n";
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			$sql .= "	and $var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
			last if ($var_obj->{tani} eq $i);
		}
		$sql .= "ORDER BY $tani.id";
	}

	my $h = mysql_exec->select($sql,1)->hundle;

	my $outvar;
	while (my $i = $h->fetch){
		if ( length( $var_obj->{labels}{$i->[1]} ) ){
			$outvar->{$i->[0]} = $var_obj->{labels}{$i->[1]};
		} else {
			$outvar->{$i->[0]} = $i->[1];
		}
	}
	
	$self->{outvar_cnt} = $outvar;
	
	return $self;
}


#------------------------------------#
#   出力する単語・品詞リストの作製   #

sub make_list{
	my $self = shift;
	
	# 単語リストの作製
	my $sql = "
		SELECT genkei.id, genkei.name, hselection.khhinshi_id
		FROM   genkei, hselection, df_$self->{tani}
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			AND genkei.num >= $self->{min}
			AND genkei.nouse = 0
			AND genkei.id = df_$self->{tani}.genkei_id
			AND df_$self->{tani}.f >= $self->{min_df}
			AND (
	";
	
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
	$sql .= "ORDER BY khhinshi_id, genkei.num DESC, genkei.name\n";
	
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
		if ($i->[1] eq 'HTMLタグ'){
			$self->{use_html} = 1;
		}
	}
	
	return $self;
}

sub make_hinshi_list{
	my $self = shift;
	
	my $sql = '';
	$sql .= "SELECT khhinshi_id, name\n";
	$sql .= "FROM   hselection\n";
	$sql .= "WHERE ifuse = 1";
	
	my $sth = mysql_exec->select($sql, 1)->hundle;
	
	while (my $i = $sth->fetch) {
		$self->{hName}{$i->[0]} = $i->[1];
	}
	
	return $self;
}

1;