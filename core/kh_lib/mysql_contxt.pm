package mysql_contxt;
use strict;
use mysql_exec;
use mysql_contxt::spss;
use mysql_contxt::csv;
use mysql_contxt::tab;

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

sub new{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	bless $self, $class;

	$self->{max}  = 0 unless length($self->{max} );
	$self->{max2} = 0 unless length($self->{max2});

	return $self;
}

sub save{
	my $self = shift;
	$self->{file_save} = shift;

	#--------------------------#
	#   データファイルの出力   #
	
	my $file_data = $self->data_file;
	open (DOUT,">$file_data") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => "$file_data",
		);
	my $n = 1;
	foreach my $i (@{$self->{wList}}){
	print "\rout, $n.";
		# 各単位の集計を合算
		my %line;
		foreach my $t (@{$self->{tani}}){
			my $table = 'ct_'."$t->[0]".'_contxt_'."$i";
			# 文書数（分母の取得）
			my $r_num = mysql_exec->select("
				SELECT num
				FROM   $table
				WHERE  word = -1
			",1)->hundle->fetch->[0];
			# 期待値計算（割り算＆重み付け）
			my $sth = mysql_exec->select("
				SELECT word, num
				FROM   $table
				WHERE  word > 0
			",1)->hundle;
			while (my $r = $sth->fetch){
				$line{$r->[0]} += ($r->[1] / $r_num) * $t->[1];
			}
			$sth->finish;
		}
		# 書き出し
		my $line =
			Jcode->new($self->{wName}{$i})->sjis
			.'('
			."$self->{wNum}{$i}"
			.'),'
		;
		foreach my $w2 (@{$self->{wList2}}){
			if ($line{$w2}){
				#$line .= sprintf("%.8f",$line{$w2}).',';
				$line .= "$line{$w2},";
			} else {
				$line .= "0,";
			}
		}
		chop $line;
		print DOUT "$line\n";
		++$n;
	}
	print "\n";
	close DOUT;

	$self->_save_finish;
}


sub culc{
	my $self = shift;
	$self->wlist;
	
	foreach my $i (@{$self->{tani}}){
		$self->_culc_each($i->[0]);
	}
	return $self;
}

sub _culc_each{
	my $self = shift;
	my $tani = shift;
	
	my $n = 0;
	foreach my $i (@{$self->{wList}}){
		# テーブルの準備
		print "\r$tani, $n, list, ";
		my $table = 'ct_'."$tani".'_contxt_'."$i";
		mysql_exec->drop_table($table);
		mysql_exec->do("
			CREATE TABLE $table (
				word int primary key,
				num  int
			)
		",1);
		
		# 当該の語が出現している文書のリスト
		my $table_w = 'ct_'."$tani".'_kihon_'. "$i";
		unless ( mysql_exec->table_exists($table_w) ){
			mysql_exec->do("
				CREATE TABLE $table_w (
					id INT primary key not null,
					num INT
				)
			",1);
			mysql_exec->do("
				INSERT
				INTO $table_w (id, num)
				SELECT $tani.id, count(*)
				FROM $tani, hyosobun, hyoso, genkei
				WHERE
					hyosobun.hyoso_id = hyoso.id
					AND genkei.id = hyoso.genkei_id
					AND genkei.id = $i
					AND $sql_join{$tani}
				GROUP BY $tani.id
			",1);
		}
		
		# 当該の語の出現数
		my $d_num = mysql_exec->select("
			SELECT COUNT(*)
			FROM   $table_w
		",1)->hundle->fetch->[0];
		next unless $d_num;
		mysql_exec->do("
			INSERT INTO $table (word, num) VALUES (-1,$d_num)
		",1);
		print "count.";
		
		# 各語の出現数をカウント
		my $sql = "
			INSERT INTO $table (word, num)
			SELECT genkei.id, count(*)
			FROM   $table_w, $tani, hyosobun, hyoso, genkei, hselection
			WHERE
				    $table_w.id = $tani.id
				AND $sql_join{$tani}
				AND hyosobun.hyoso_id = hyoso.id
				AND hyoso.genkei_id = genkei.id
				AND genkei.khhinshi_id = hselection.khhinshi_id
				AND genkei.num >= $self->{min2}
				AND (
		";
		my $nn = 0;
		foreach my $i ( @{$self->{hinshi2}} ){
			if ($nn){ $sql .= ' OR '; }
			$sql .= "hselection.khhinshi_id = $i\n";
			++$nn;
		}
		$sql .= ")\n";
		if ($self->{max2}){
			$sql .= "AND genkei.num <= $self->{max2}\n";
		}
		$sql .= "GROUP BY genkei.id";
		mysql_exec->do($sql,1);
		
		++$n;
	}
	print "\n";
}

#------------------------#
#   抽出語リストの作製   #

sub wlist{
	my $self = shift;
	
	# 抽出語のリスト
	my $sql = "
		SELECT genkei.id, genkei.name, genkei.num
		FROM   genkei, hselection
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			AND genkei.num >= $self->{min}
			AND genkei.nouse = 0
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
	$sql .= "ORDER BY genkei.khhinshi_id, 0 - genkei.num\n";
	
	my $sth = mysql_exec->select($sql, 1)->hundle;
	my (@list, %name, %num);
	while (my $i = $sth->fetch) {
		push @list,        $i->[0];
		$name{$i->[0]}   = $i->[1];
		$num{$i->[0]}    = $i->[2];
	}
	$sth->finish;
	$self->{wList}   = \@list;
	$self->{wName}   = \%name;
	$self->{wNum}    = \%num;
	
	# 文脈語のリスト
	$sql = "
		SELECT genkei.id, genkei.name
		FROM   genkei, hselection
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			AND genkei.num >= $self->{min2}
			AND genkei.nouse = 0
			AND (
	";
	
	$n = 0;
	foreach my $i ( @{$self->{hinshi2}} ){
		if ($n){ $sql .= ' OR '; }
		$sql .= "hselection.khhinshi_id = $i\n";
		++$n;
	}
	$sql .= ")\n";
	if ($self->{max2}){
		$sql .= "AND genkei.num <= $self->{max2}\n";
	}
	$sql .= "ORDER BY genkei.khhinshi_id, 0 - genkei.num\n";
	
	my $sth = mysql_exec->select($sql, 1)->hundle;
	my (@list2, %name2, %ID2Num);
	while (my $i = $sth->fetch) {
		push @list2,        $i->[0];
		$name2{$i->[0]}   = $i->[1];
	}
	$sth->finish;
	$self->{wList2}   = \@list2;
	$self->{wName2}   = \%name2;
	
	
	return $self;
}



1;
