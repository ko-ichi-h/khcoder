# 「ツール」 -> 「コーディング」メニュー以下のコマンドのためのロジック群

package kh_cod::func;
use base qw(kh_cod);
use strict;

use mysql_getheader;
use Jcode;

#-----------------------------------------#
#   コーディング結果の出力（不定長CSV）   #

sub cod_out_var{
	my $self    = shift;
	my $tani    = shift;
	my $outfile = shift;
	
	# コーディングとコーディング結果のチェック
	$self->code($tani) or return 0;
	unless ($self->valid_codes){ return 0; }
	$self->cumulate if @{$self->{valid_codes}} > 30;
	
	# 出力用SQL・一行目の作成
	my ($sql,$head);
	my $flag = 0;
	my $hnum = 0;
	foreach my $i ('bun','dan','h5','h4','h3','h2','h1'){
		if ($i eq $self->tani){
			$flag = 1;
		}
		if ($flag){
			$sql = "$i"."_id,"."$sql";
			$head = "$i,"."$head";
			++$hnum;
		}
	}
	$head .= 'コード';
	$sql = "SELECT "."$sql";
	
	my @codename;                                 # ここでコード名もチェック
	my $n = 0;
	foreach my $i (@{$self->valid_codes}){
		$sql .= "IF(".$i->res_table.".".$i->res_col.",1,0),";
		use kh_csv;
		$codename[$n] = $i->name;
		substr($codename[$n],0,2) = '';
		++$n;
	}
	chop $sql;
	$sql .= "\nFROM ".$self->tani."\n";
	foreach my $i (@{$self->tables}){
		$sql .= "LEFT JOIN $i ON ".$self->tani.".id = $i.id\n";
	}
	
	# 出力開始
	open(CODO,">$outfile") or
		gui_errormsg->open(
			type => 'file',
			thefile => $outfile
		);
	print CODO "$head\n";
	my $h = mysql_exec->select($sql,1)->hundle;
	
	while (my $i = $h->fetch){
		my $current;
		my $current_code;
		my $n = 0;
		foreach my $j (@{$i}){
			if ($n < $hnum){                     # 位置情報
				$current .= "$j,";
			} else {                              # コード
				if ($j){
					my $cnum = $n - $hnum;
					$current_code .= "$codename[$cnum] ";
				}
			}
			++$n;
		}
		if ($current_code){
			chop $current_code if $current_code;
			$current_code = kh_csv->value_conv($current_code);
		}
		print CODO "$current$current_code\n";
	}
	close (CODO);
	
	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_sjis($outfile);
	}
}

#------------------------------------#
#   コーディング結果の出力（SPSS）   #

sub cod_out_spss{
	my $self     = shift;
	my $tani     = shift;
	my $outfile  = shift;
	my $outfile2 = substr($outfile,0,length($outfile)-4).".dat";

	# コーディングとコーディング結果のチェック
	$self->code($tani) or return 0;
	unless ($self->valid_codes){ return 0; }
	$self->cumulate if @{$self->{valid_codes}} > 30;
	
	my ($sql,@head);
	my $flag = 0;
	foreach my $i ('bun','dan','h5','h4','h3','h2','h1'){
		if ($i eq $self->tani){
			$flag = 1;
		}
		if ($flag){
			$sql = "$i"."_id,"."$sql";
			push @head, $i;
		}
	}
	@head = reverse @head;
	my %codes; my $cn = 1;
	$sql = "SELECT "."$sql";
	foreach my $i (@{$self->valid_codes}){
		$sql .= "IF(".$i->res_table.".".$i->res_col.",1,0),";
		push @head, "code$cn";
		$codes{"code$cn"} = Jcode->new($i->name)->sjis;
		++$cn;
	}
	chop $sql;

	$sql .= "\nFROM ".$self->tani."\n";
	foreach my $i (@{$self->tables}){
		$sql .= "LEFT JOIN $i ON ".$self->tani.".id = $i.id\n";
	}
	
	# データファイル
	open(CODO,">$outfile2") or
		gui_errormsg->open(
			type => 'file',
			thefile => $outfile2
		);
	
	my $h = mysql_exec->select($sql,1)->hundle;
	while (my $i = $h->fetch){
		my $current;
		foreach my $j (@{$i}){
			$current .= "$j,";
		}
		chop $current;
		print CODO "$current\n";
	}
	close (CODO);
	
	# シンタックスファイル
	my $spss;
	$spss .= "file handle trgt1 /name=\'";
	#if ($::config_obj->os eq 'win32'){
	#	$spss .= Jcode->new($outfile2,'sjis')->euc;
	#} else {
	#	$spss .= $outfile2;
	#}
	$spss .= $outfile2;
	$spss .= "\'\n";
	$spss .= "                 /lrecl=32767 .\n";
	$spss .= "data list list(',') file=trgt1 /\n";
	foreach my $i (@head){
		$spss .= "  $i(f10.0)\n";
	}
	$spss .= ".\n";
	$spss .= ".variable labels\n";
	foreach my $i (keys %codes){
		$spss .= "  $i \'$codes{$i}\'\n";
	}
	$spss .= ".\n";
	$spss .= "execute.\n";
	
	open(CODO,">$outfile") or
		gui_errormsg->open(
			type => 'file',
			thefile => $outfile
		);
	print CODO "$spss";
	close (CODO);
}

#-----------------------------------#
#   コーディング結果の出力（CSV）   #

sub cod_out_csv{
	my $self    = shift;
	my $tani    = shift;
	my $outfile = shift;
	
	# コーディングとコーディング結果のチェック
	$self->code($tani) or return 0;
	unless ($self->valid_codes){ return 0; }
	$self->cumulate if @{$self->{valid_codes}} > 30;

	my ($sql,$head);
	my $flag = 0;
	foreach my $i ('bun','dan','h5','h4','h3','h2','h1'){
		if ($i eq $self->tani){
			$flag = 1;
		}
		if ($flag){
			$sql = "$i"."_id,"."$sql";
			$head = "$i,"."$head";
		}
	}
	$sql = "SELECT "."$sql";
	foreach my $i (@{$self->valid_codes}){
		$sql .= "IF(".$i->res_table.".".$i->res_col.",1,0),";
		use kh_csv;
		if ($::config_obj->os eq 'win32'){
			$head .= kh_csv->value_conv(Jcode->new($i->name)->sjis).",";
		} else {
			$head .= kh_csv->value_conv($i->name).",";
		}
	}
	chop $sql;
	chop $head;
	$sql .= "\nFROM ".$self->tani."\n";
	foreach my $i (@{$self->tables}){
		$sql .= "LEFT JOIN $i ON ".$self->tani.".id = $i.id\n";
	}
	
	open(CODO,">$outfile") or
		gui_errormsg->open(
			type => 'file',
			thefile => $outfile
		);
	print CODO "$head\n";
	
	my $h = mysql_exec->select($sql,1)->hundle;
	while (my $i = $h->fetch){
		my $current;
		foreach my $j (@{$i}){
			$current .= "$j,";
		}
		chop $current;
		print CODO "$current\n";
	}
	
	close (CODO);
}

#------------------------------------------#
#   コーディング結果の出力（タブ区切り）   #

sub cod_out_tab{
	my $self    = shift;
	my $tani    = shift;
	my $outfile = shift;
	
	# コーディングとコーディング結果のチェック
	$self->code($tani) or return 0;
	unless ($self->valid_codes){ return 0; }
	$self->cumulate if @{$self->{valid_codes}} > 30;

	my ($sql,$head);
	my $flag = 0;
	foreach my $i ('bun','dan','h5','h4','h3','h2','h1'){
		if ($i eq $self->tani){
			$flag = 1;
		}
		if ($flag){
			$sql = "$i"."_id,"."$sql";
			$head = "$i\t"."$head";
		}
	}
	$sql = "SELECT "."$sql";
	foreach my $i (@{$self->valid_codes}){
		$sql .= "IF(".$i->res_table.".".$i->res_col.",1,0),";
		use kh_csv;
		if ($::config_obj->os eq 'win32'){
			$head .= kh_csv->value_conv_t(Jcode->new($i->name)->sjis)."\t";
		} else {
			$head .= kh_csv->value_conv_t($i->name)."\t";
		}
	}
	chop $sql;
	chop $head;
	$sql .= "\nFROM ".$self->tani."\n";
	foreach my $i (@{$self->tables}){
		$sql .= "LEFT JOIN $i ON ".$self->tani.".id = $i.id\n";
	}
	
	open(CODO,">$outfile") or
		gui_errormsg->open(
			type => 'file',
			thefile => $outfile
		);
	print CODO "$head\n";
	
	my $h = mysql_exec->select($sql,1)->hundle;
	while (my $i = $h->fetch){
		my $current;
		foreach my $j (@{$i}){
			$current .= "$j\t";
		}
		chop $current;
		print CODO "$current\n";
	}
	
	close (CODO);
}

#--------------#
#   単純集計   #

sub count{
	my $self = shift;
	my $tani = shift;
	
	use Benchmark;
	my $t0 = new Benchmark;
	
	$self->code($tani) or return 0;
	unless ($self->codes){ return 0; }
	
	# 総数を取得
	my $total = mysql_exec->select("select count(*) from $tani",1)
		->hundle->fetch->[0];
	
	# 各コードの出現数を取得
	my $result;
	foreach my $i (@{$self->codes}){
		my $rows = 0;
		if ($i->res_table){                  # 出現数0に対処
			$rows = mysql_exec->select(
				"SELECT sum(IF(".$i->res_col.",1,0)) FROM ".$i->res_table
			)->hundle;
			if ($rows = $rows->fetch){
				$rows = $rows->[0]; 
			} else {
				$rows = 0;
			}
		}
		
		push @{$result}, [
			$i->name,
			$rows,
			sprintf("%.2f",($rows / $total) * 100 )."%"
		];
	}
	
	# 1つでもコードが与えられた文書の数を取得
	
	my $least1 = 0;
	if ($self->valid_codes){
		$self->cumulate if @{$self->{valid_codes}} > 30;
		
		my $sql = "SELECT count(*)\nFROM $tani\n";
		foreach my $i (@{$self->tables}){
			$sql .= "LEFT JOIN $i ON $tani.id = $i.id\n";
		}
		$sql .= "WHERE\n";
		my $n = 0;
		foreach my $i (@{$self->valid_codes}){
			if ($n){ $sql .= "or "; }
			$sql .= $i->res_table.".".$i->res_col."\n";
			++$n;
		}
		$least1 = mysql_exec->select($sql,1)->hundle->fetch->[0];
	}
	
	push @{$result}, [
		'＃コード無し',
		$total - $least1,
		sprintf("%.2f",( ($total - $least1) / $total ) * 100)."%"
	];
	push @{$result}, [
		'（文書数）',
		$total,
		''
	];
	
	my $t1 = new Benchmark;
	print timestr(timediff($t1,$t0)),"\n";
	
	return $result;
}

#----------------------------#
#   外部変数とのクロス集計   #

sub outtab{
	my $self  = shift;
	my $tani = shift;
	my $var_id = shift;
	my $cell  = shift;
	
	# コーディングの実行
	$self->code($tani) or return 0;
	unless ($self->valid_codes){ return 0; }
	$self->cumulate if @{$self->{valid_codes}} > 30;
	
	# 外部変数のチェック
	my ($outvar_tbl,$outvar_clm);
	my $var_obj = mysql_outvar::a_var->new(undef,$var_id);
	if ( $var_obj->{tani} eq $tani){
		$outvar_tbl = $var_obj->{table};
		$outvar_clm = $var_obj->{column};
	} else {
		$outvar_tbl = 'ct_outvar_cross';
		$outvar_clm = 'value';
		mysql_exec->drop_table('ct_outvar_cross');
		mysql_exec->do("
			CREATE TABLE ct_outvar_cross (
				id int primary key not null,
				value varchar(255)
			) TYPE=HEAP
		",1);
		my $sql;
		$sql .= "INSERT INTO ct_outvar_cross\n";
		$sql .= "SELECT $tani.id, $var_obj->{table}.$var_obj->{column}\n";
		$sql .= "FROM $tani, $var_obj->{tani}, $var_obj->{table}\n";
		$sql .= "WHERE\n";
		$sql .= "	$var_obj->{tani}.id = $var_obj->{table}.id\n";
		foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
			$sql .= "	and $var_obj->{tani}.$i"."_id = $tani.$i"."_id\n";
			last if ($var_obj->{tani} eq $i);
		}
		$sql .= "ORDER BY $tani.id";
		#print "$sql\n\n";
		mysql_exec->do("$sql",1);
	}
	
	
	# 集計用SQL文の作製
	my $sql;
	$sql .= "SELECT $outvar_tbl.$outvar_clm, ";
	foreach my $i (@{$self->{valid_codes}}){
		$sql .= "sum( IF(".$i->res_table.".".$i->res_col.",1,0) ),";
	}
	$sql .= " count(*) \n";
	$sql .= "FROM $outvar_tbl\n";
	foreach my $i (@{$self->tables}){
		$sql .= "LEFT JOIN $i ON $outvar_tbl.id = $i.id\n";
	}
	$sql .= "\nGROUP BY $outvar_tbl.$outvar_clm";
	$sql .= "\nORDER BY $outvar_tbl.$outvar_clm";
	#print "$sql\n";
	
	my $h = mysql_exec->select($sql,1)->hundle;
	
	# 結果出力の作製
	my @result;
	my @for_chisq;
	
	# 一行目
	my @head = ('');
	foreach my $i (@{$self->{valid_codes}}){
		push @head, Jcode->new($i->name)->sjis;
	}
	push @head, Jcode->new('ケース数')->sjis;
	push @result, \@head;
	# 中身
	my @sum = (Jcode->new('合計')->sjis);
	my $total;
	while (my $i = $h->fetch){
		my $n = 0;
		my @current;
		my @current_for_chisq;
		my @c = @{$i};
		my $nd = pop @c;
		unless ( length($i->[0]) ){next;}
		foreach my $h (@c){
			if ($n == 0){                         # 行ヘッダ
				if ( length($var_obj->{labels}{$h}) ){
					push @current, Jcode->new($var_obj->{labels}{$h})->sjis;
				} else {
					push @current, Jcode->new($h,'euc')->sjis;
				}
			} else {                              # 中身
				$sum[$n] += $h;
				my $p = sprintf("%.2f",($h / $nd ) * 100);
				push @current_for_chisq, [$h, $nd - $h];
				if ($cell == 0){
					my $pp = "($p"."%)";
					$pp = '  '.$pp if length($pp) == 7;
					push @current, "$h $pp";
				}
				elsif ($cell == 1){
					push @current, $h;
				} else {
					push @current, "$p"."%";
				}
			}
			++$n;
		}
		$total += $nd;
		push @current, $nd;
		push @result, \@current;
		push @for_chisq, \@current_for_chisq if @current_for_chisq;
	}
	# 合計行
	my @c = @sum;
	my @current; my $n = 0;
	foreach my $i (@sum){
		if ($n == 0){
			push @current, $i;
		} else {
			my $p = sprintf("%.2f", ($i / $total) * 100);
			if ($cell == 0){
				my $pp = "($p"."%)";
				$pp = '  '.$pp if length($pp) == 7;
				push @current, "$i $pp";
			}
			elsif ($cell == 1){
				push @current, $i;
			} else {
				push @current, "$p"."%";
			}
		}
		++$n;
	}
	push @current, $total;
	push @result, \@current;

	# chi-square test
	if ($::config_obj->R){
		my @chisq = (Jcode->new('カイ2乗値')->sjis);
		$n = @current - 2;
		$::config_obj->R->lock;
		for (my $c = 0; $c < $n; ++$c){
			my $cmd = 'chi <- chisq.test(matrix( c(';
			my $nrow = 0;
			foreach my $i (@for_chisq){
				$cmd .= "$i->[$c][0],";
				$cmd .= "$i->[$c][1], ";
				++$nrow;
			}
			chop $cmd; chop $cmd;
			$cmd .= "), nrow=$nrow, ncol=2, byrow=TRUE), correct=TRUE)\n".'print (chi$statistic)';
			$::config_obj->R->send($cmd);
			my $ret = $::config_obj->R->read;
			unless (length($ret)){
				push @chisq, '';
				next;
			}

			chop $ret;
			$ret = sprintf("%.3f", substr($ret, index($ret,"\n") + 1, length($ret) - index($ret,"\n") -1));
			$::config_obj->R->send('print (chi$p.value)');
			my $p = $::config_obj->R->read;
			substr($p, 0, 4) = '';
			if ($p < 0.01){
				$ret .= '**';
			}
			elsif ($p < 0.05){
				$ret .= '*';
			}
			push @chisq, $ret;
		}
		$::config_obj->R->unlock;
		push @chisq, ' ';
		push @result, \@chisq;
	}
	
	return \@result;
}

#----------------------------#
#   章・節・段落ごとの集計   #

sub tab{
	my $self  = shift;
	my $tani1 = shift;
	my $tani2 = shift;
	my $cell  = shift;
	
	$self->code($tani1) or return 0;
	unless ($self->valid_codes){ return 0; }
	
	$self->cumulate if @{$self->{valid_codes}} > 30;

	my $result;

	# 集計用SQL文の作製
	my $sql;
	$sql .= "SELECT $tani2.id, ";
	foreach my $i (@{$self->{valid_codes}}){
		$sql .= "sum( IF(".$i->res_table.".".$i->res_col.",1,0) ),";
	}
	$sql .= " count(*) \n";
	$sql .= "FROM $tani1\n";
	foreach my $i (@{$self->tables}){
		$sql .= "LEFT JOIN $i ON $tani1.id = $i.id\n";
	}
	$sql .= "LEFT JOIN $tani2 ON ";
	my ($flag1,$n);
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($tani2 eq $i){
			$flag1 = 1;
		}
		if ($flag1){
			if ($n){$sql .= " AND ";}
			$sql .= "$tani1.$i".'_id = '."$tani2.$i".'_id ';
			++$n;
		}
	}
	$sql .= "\n";
	$sql .= "\nGROUP BY ";
	my $flag2 = 0;
	foreach my $i ("bun","dan","h5","h4","h3","h2","h1"){
		if ($tani2 eq $i){
			$flag2 = 1;
		}
		if ($flag2){
			$sql .= "$tani1.$i".'_id,';
		}
	}
	chop $sql;
	$sql .= "\nORDER BY $tani2.id";
	
	my $h = mysql_exec->select($sql,1)->hundle;
	
	# 結果出力の作製
	my @result;
	my @for_chisq;

	# 一行目
	my @head = ('');
	foreach my $i (@{$self->{valid_codes}}){
		push @head, Jcode->new($i->name)->sjis;
	}
	push @head, Jcode->new('ケース数')->sjis;
	push @result, \@head;
	# 中身
	my @sum = (Jcode->new('合計')->sjis);
	my $total;
	while (my $i = $h->fetch){
		my $n = 0;
		my @current;
		my @current_for_chisq;
		my @c = @{$i};
		my $nd = pop @c;
		unless ( length($i->[0]) ){next;}
		foreach my $h (@c){
			if ($n == 0){                         # 行ヘッダ
				if (index($tani2,'h') == 0){
					push @current, mysql_getheader->get($tani2, $h);
				} else {
					push @current, $h;
				}
			} else {                              # 中身
				$sum[$n] += $h;
				my $p = sprintf("%.2f",($h / $nd ) * 100);
				push @current_for_chisq, [$h, $nd - $h];
				if ($cell == 0){
					my $pp = "($p"."%)";
					$pp = '  '.$pp if length($pp) == 7;
					push @current, "$h $pp";
				}
				elsif ($cell == 1){
					push @current, $h;
				} else {
					push @current, "$p"."%";
				}
			}
			++$n;
		}
		$total += $nd;
		push @current, $nd;
		push @result, \@current;
		push @for_chisq, \@current_for_chisq if @current_for_chisq;
	}
	# 合計行
	my @c = @sum;
	my @current; my $n = 0;
	foreach my $i (@sum){
		if ($n == 0){
			push @current, $i;
		} else {
			my $p = sprintf("%.2f", ($i / $total) * 100);
			if ($cell == 0){
				my $pp = "($p"."%)";
				$pp = '  '.$pp if length($pp) == 7;
				push @current, "$i $pp";
			}
			elsif ($cell == 1){
				push @current, $i;
			} else {
				push @current, "$p"."%";
			}
		}
		++$n;
	}
	push @current, $total;
	push @result, \@current;

	# chi-square test
	my $R_debug = 0;
	if ($::config_obj->R){
		my @chisq = (Jcode->new('カイ2乗値')->sjis);
		$n = @current - 2;
		$::config_obj->R->lock;
		for (my $c = 0; $c < $n; ++$c){
			my $cmd = 'chi <- chisq.test(matrix( c(';
			my $nrow = 0;
			foreach my $i (@for_chisq){
				$cmd .= "$i->[$c][0],";
				$cmd .= "$i->[$c][1], ";
				++$nrow;
			}
			chop $cmd; chop $cmd;
			$cmd .= "), nrow=$nrow, ncol=2, byrow=TRUE), correct=TRUE)\n".'print (chi$statistic)';
			print "send: $cmd ..." if $R_debug;
			$::config_obj->R->send($cmd);
			print "ok\n" if $R_debug;
			my $ret = $::config_obj->R->read(3);
			print "read: $ret\n" if $R_debug;
			unless (length($ret)){
				push @chisq, '';
				next;
			}

			chop $ret;
			$ret = sprintf("%.3f", substr($ret, index($ret,"\n") + 1, length($ret) - index($ret,"\n") -1));
			print 'send: print (chi$p.value) ...' if $R_debug;
			$::config_obj->R->send('print (chi$p.value)');
			print "ok\n" if $R_debug;
			my $p = $::config_obj->R->read(3);
			print "read: $p\n" if $R_debug;
			substr($p, 0, 4) = '';
			if ($p < 0.01){
				$ret .= '**';
			}
			elsif ($p < 0.05){
				$ret .= '*';
			}
			push @chisq, $ret;
		}
		$::config_obj->R->unlock;
		push @chisq, ' ';
		push @result, \@chisq;
	}

	
	return \@result;
}

#------------------------------#
#   ジャッカードの類似性測度   #
sub jaccard{
	my $self = shift;
	my $tani = shift;
	
	# コーディングとコーディング結果のチェック
	$self->code($tani) or return 0;
	unless ($self->valid_codes){ return 0; }
	
	my ($n, @head) = (0, (''));
	foreach my $i (@{$self->valid_codes}){
		push @head, Jcode->new($i->name)->sjis;        # 出力結果・ヘッダ行
		++$n;
	}
	unless ($n > 1){return 0;}
	
	# 結果出力の作製
	my @result;
	push @result, \@head;
	
	foreach my $i (@{$self->valid_codes}){           # 出力結果・相関行列
		my @current = (Jcode->new($i->name)->sjis);
		foreach my $h (@{$self->valid_codes}){
			if ($i->name eq $h->name){
				push @current,"1.000";
			} else {
				push @current, kh_cod::func->_jaccard($i,$h);
			}
		}
		push @result, \@current;
	}
	return \@result;
}


sub _jaccard{
	my $class = shift;
	my $c1    = shift;
	my $c2    = shift;
	
	my @tables;
	push @tables, $c1->res_table;
	unless ($c1->res_table eq $c2->res_table){
		push @tables, $c2->res_table;
	}

	# 両方出現しているケース
	my $sql1 = "SELECT * FROM ".$c1->tani."\n";
	foreach my $i (@tables){
		$sql1 .= "LEFT JOIN $i ON ".$c1->tani.".id = $i.id\n";
	}
	$sql1 .= "WHERE\n";
	$sql1 .= $c1->res_table.".".$c1->res_col." AND ".$c2->res_table.".".$c2->res_col;
	
	my $both =  mysql_exec->select($sql1,1)->hundle->rows;

	# どちらかが出現しているケース
	my $sql2 = "SELECT * FROM ".$c1->tani."\n";
	foreach my $i (@tables){
		$sql2 .= "LEFT JOIN $i ON ".$c1->tani.".id = $i.id\n";
	}
	$sql2 .= "WHERE\n";
	$sql2 .= "IFNULL(".$c1->res_table.".".$c1->res_col.",0) OR IFNULL(".$c2->res_table.".".$c2->res_col.",0)";
	
	my $n = mysql_exec->select($sql2,1)->hundle->rows;
	
	unless ($n){return '0.000'; }
	return sprintf("%.3f",$both / $n);
}


1;