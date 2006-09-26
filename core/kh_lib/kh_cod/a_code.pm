package kh_cod::a_code;
use kh_cod::a_code::atom;
use gui_errormsg;
use mysql_exec;
use strict;

my $debug = 0;

#----------------------#
#   コーディング実行   #

sub code{
	my $self           = shift;
	$self->{res_table} = shift;
	$self->{sort}      = shift;
	$self->{if_done}   = 1;

	print "* Coding: Checking conditions...\n" if $debug;
	print "\tres_table: $self->{res_table}\n" if $debug;
	unless ($self->{condition}){
		$self->{res_table} = '';
		return 0;
	}
	unless ($self->{row_condition}){
		$self->{res_table} = '';
		return 0;
	}
	unless ($self->tables){
		$self->{tables} = [];
	}

	# キャッシュの有無をチェック
	my $raw = $self->{ed_condition};
	$raw =~ s/'/\\'/g;
	my $kind = 'code';
	if ($self->{sort} eq 'tf*idf'){
		$kind .= '_idf_m';
	}
	elsif ($self->{sort} eq 'tf/idf'){
		$kind .= '_idf_d';
	}
	my $tani = $self->{tani};
	my @c_c = kh_cod::a_code->cache_check(
		tani => $tani,
		kind => $kind,
		name => $raw
	);
	my $cache_table = "ct_$tani"."_ccode_"."$c_c[1]";

	#print "1st: $c_c[0]\n";
	#print "2nd: $c_c[1]\n";
	#print "table: $cache_table\n";
	print "\tcache found[1]\n" if $c_c[0] && $debug;

	# キャッシュが無い場合はまずキャッシュを作成
	unless ($c_c[0]){

		mysql_exec->drop_table($cache_table);               # テーブル作成
		mysql_exec->do("
			CREATE TABLE $cache_table (
				id int not null primary key,
				num float
			)
		",1);

		my $sql = '';                                       # 条件チェック
		$sql .= "INSERT INTO $cache_table (id, num)\n";
		$sql .= "SELECT $self->{tani}.id, ";
		my $nn = 0;
		foreach my $i (@{$self->{condition}}){
			if ($nn){ $sql .= " + "; } else { $nn = 1; }
			$sql .= $i->num_expr($self->{sort});
		}
		$sql .= "\n";
		$sql .= "FROM $self->{tani}\n";
		foreach my $i (@{$self->tables}){
			unless ($i){next;}
			$sql .= "\tLEFT JOIN $i ON $self->{tani}.id = $i.id\n";
		}
		$sql .= "WHERE\n";
		foreach my $i (@{$self->{condition}}){
			$sql .= "\t".$i->expr()."\n";
		}
		
		my $error_flag = 0;                                 # エラーチェック
		my $check = mysql_exec->do($sql);
		if ($check->err){
			gui_errormsg->open(
				type => 'msg',
				msg  =>
					"コーディング・ルールの書式に誤りがありました。\n".
					"誤りを含むコード： ".$self->name."\n".$check->err
			);
			$error_flag = 1;
		}
		unless ($error_flag){
			my $check2 = mysql_exec->select(
				"SELECT * FROM $cache_table LIMIT 1"
			)->hundle;
			unless (my $ch = $check2->fetch){
				$self->{res_table} = '';
				$error_flag = 1;
			}
		}
		
		my $words = '';                                     # キャッシュの登録
		my $n =0;
		foreach my $i (@{$self->{hyosos}}){
			$words .= "\t";
			$words .= $i;
			++$n;
		}
		$words = '-1' if $error_flag;
		$self->cache_regist(
			tani   => $tani,
			kind   => $kind,
			name   => $raw,
			hyosos => $words,
		);
	}
	
	# キャッシュを$self->{res_table}にコピー
	my $chk = $self->cache_code_if_ok(
			tani   => $tani,
			kind   => $kind,
			name   => $raw,
	);
	unless ($chk){
		print "\nthis is an error code (cache)!\n" if $debug;
		$self->{res_table} = '';
		return 0;
	}

	mysql_exec->drop_table($self->{res_table});
	mysql_exec->do("
		CREATE TABLE $self->{res_table} (
			id int not null primary key,
			num float
		) type = heap
	",1);
	mysql_exec->do("
		INSERT INTO $self->{res_table} (id, num)
		SELECT id, num
		FROM   $cache_table
	",1);
	
	# 検索に使用した文字列のリスト
	foreach my $i (@{$self->{condition}}){
		if ($i->name eq 'string'){
			my $t = $i->raw;
			chop $t;
			substr($t, 0, 1) = '';
			push @{$self->{strings}}, $t;
		}
	}
	
	# $self->{tani}.num が0だった場合のための手当
	mysql_exec->do("
		UPDATE $self->{res_table}
		SET    num = 1
		WHERE  num = 0
	",1);
	
	#print " done\n" if $debug;

	return $self;
}

#----------------------#
#   コーディング準備   #

sub ready{
	my $self = shift;
	my $tani = shift;
	my $sort = shift;
	
	print "***\n" if $debug;
	print "* Coding: making tables for atoms...\n" if $debug;

	$self->{tani} = $tani;
	unless ($self->{condition}){
		return 0;
	}

	# キャッシュのチェック
	my $raw = $self->{ed_condition};
	$raw =~ s/'/\\'/g;
	my $kind = 'code';
	if ($sort eq 'tf*idf'){
		$kind .= '_idf_m';
	}
	elsif ($sort eq 'tf/idf'){
		$kind .= '_idf_d';
	}
	my @c_c = kh_cod::a_code->cache_check(
		tani => $tani,
		kind => $kind,
		name => $raw
	);
	
	if ( $c_c[0] == 1 ) {                            # キャッシュ有りの場合
		print "\tcache found[0]!\n" if $debug;
		my $t = mysql_exec->select("
			SELECT hyosos
			FROM ct_cache_tables
			WHERE id = $c_c[1]
		",1)->hundle->fetch->[0];
		my @words = split /\t/, $t;
		$self->{hyosos} = \@words;
		return $self;
	}
	
	# ATOMごとのテーブルを作製
	my %words;
	my ($length_frag,$n,$n0, $n1,$unique_check,@tmp_tab) = (0,0,0,0,undef,undef);
	my @t = ();
	foreach my $i (@{$self->{condition}}){
		$i->ready($tani);
		my $temp_w = $i->hyosos;
		if ($temp_w){
			foreach my $h (@{$temp_w}){
				++$words{$h};
			}
		}
		if ($i->name eq 'length'){$length_frag = 1;}
		if ( ($i->tables) and not ($i->name eq 'length') ){
			$n0 += @{$i->tables};
			$n  += @{$i->tables};
			if ($n0 > 25){
				++$n1; $n0 = 0;
			}
			$i->parent_table("ct_$tani"."_$n1");
			foreach my $h (@{$i->tables}){
				if ($unique_check->{$n1}{$h}){
					next;
				} else {
					push @{$t[$n1]}, $h;
					if ($h) {push @tmp_tab,   $h;}
					$unique_check->{$n1}{$h} = 1;
				}
			}
		}
	}
	my @words = (keys %words);
	$self->{hyosos} = \@words;
	if ($length_frag) {push @{$self->{tables}},"$tani"."_length";}
	
	#if ($n < 30){
	#	$self->{parents} = 0;
	#	$self->{tables}  = \@tmp_tab;
	#	print "tables: $n\n";
	#	return 1;
	#} else {
	#	$self->{parents} = 1;
	#}
	unless ($unique_check){return 1;}
	
	# ATOMテーブルをまとめる
	print "* Coding: Joining the tables...\n" if $debug;
	my $n = 0;
	foreach my $i (@t){
		# テーブル作製
		mysql_exec->drop_table("ct_$tani"."_$n");
		my $sql =
			"CREATE TABLE ct_$tani"."_$n ( id int primary key not null,\n";
		foreach my $h (@{$i}){
			# print "atom table: $h\n";
			my $col = (split /\_/, $h)[2].(split /\_/, $h)[3];
			$sql .= "$col FLOAT,"
		}
		chop $sql;
		$sql .= ') TYPE = HEAP ';
		mysql_exec->do($sql,1);
		push @{$self->{tables}}, "ct_$tani"."_$n";
		
		# INSERT
		$sql = '';
		$sql .= "INSERT INTO ct_$tani"."_$n\n(id,";
		foreach my $h (@{$i}){
			my $col = (split /\_/, $h)[2].(split /\_/, $h)[3];
			$sql .= "$col,";
		}
		chop $sql;
		$sql .= ")\n";
		$sql .= "SELECT $tani.id,";
		foreach my $h (@{$i}){
			$sql .= "$h.num,";
		}
		chop $sql;
		$sql .= "\n";
		$sql .= "FROM $tani \n";
		foreach my $h (@{$i}){
			$sql .= "\tLEFT JOIN $h ON $tani.id = $h.id\n"
		}
		$sql .= "WHERE ";
		my $nn = 0;
		foreach my $h (@{$i}){
			if ($nn){ $sql .= ' OR '; }
			$sql .= " $h.num is not null";
			++$nn;
		}
		mysql_exec->do($sql,1);
		
		++$n;
	}
	return $self;
}

#------------------------------#
#   コーディングルールの解釈   #

sub new{
	my $self;
	my $class = shift;
	$self->{name} = shift;
	$self->{row_condition} = shift;
	
	my $condition = Jcode->new($self->{row_condition},'euc')->tr('　',' ');
	$condition =~ tr/\t\n\r/   /;
	#print "$condition\n";
	my @temp = split / /, $condition;
	
	my $n = 0;
	foreach my $i (@temp){
		next unless length($i);
		next if ($i eq ' ');
		push @{$self->{condition}}, kh_cod::a_code::atom->new($i);
		$self->{ed_condition} .= ' ' if $n;
		$self->{ed_condition} .= $i;
		++$n;
	}
	
	bless $self, $class;
	return $self;
}

# 利用語のリストを返す
sub hyosos{
	my $self = shift;
	return $self->{hyosos};
}
sub strings{
	my $self = shift;
	return $self->{strings};
}

# 2回目以降のコーディングに備える
sub clear{
	my $self = shift;
	
	$self->{res_table} = undef;
	$self->{res_col}   = undef;
	$self->{tables}    = undef;
	$self->{tani}      = undef;
	$self->{if_done}   = 0;
	foreach my $i (@{$self->{condition}}){
		$i->{tables} = undef;
		$i->clear;
	}
}

#--------------------#
#   キャッシュ管理   #
#--------------------#

sub cache_check{
	my $self_ = shift;
	my %args = @_;

	# キャッシュリストが存在する場合
	if ( mysql_exec->table_exists('ct_cache_tables') ){
		# 既にキャッシュがあるかどうかを検索
		my $h = mysql_exec->select("
			SELECT id
			FROM ct_cache_tables
			WHERE 
				    tani = \"$args{tani}\"
				AND kind = \"$args{kind}\"
				AND name = \"$args{name}\"
		",1)->hundle;
		my $n = $h->fetch;
		if ($n){                        # キャッシュが存在した場合
			#print "[list y, cache y]\n" if $debug;
			return (1,$n->[0]);
		} else {                        # キャッシュが存在しなかった場合
			my $num = 0;
			if ($args{kind} =~ /^code/ ){
				# 番号を返す
				$num = mysql_exec->select("
					SELECT MAX(id)
					FROM   ct_cache_tables
				",1)->hundle->fetch->[0];
				++$num;
				#print "[list y, cache n, code y]\n" if $debug;
			} else {
				# 新規キャッシュとして登録
				mysql_exec->do("
					INSERT INTO ct_cache_tables (tani,kind,name)
					VALUES (\"$args{tani}\", \"$args{kind}\",\"$args{name}\")
				",1);
				# 番号を返す
				$num = mysql_exec->select("
					SELECT MAX(id)
					FROM   ct_cache_tables
				",1)->hundle->fetch->[0];
				#print "[list y, cache n, code n]\n"  if $debug;
			}
			return (0, $num);
		}
	}
	# キャッシュリストが存在しなかった場合
	else {
		mysql_exec->do("
			CREATE TABLE ct_cache_tables (
				id     int auto_increment primary key not null,
				tani   varchar(5),
				kind   varchar(20),
				name   text,
				hyosos text
			)
		",1);
		# 種類が「code」でなければ登録してしまう
		mysql_exec->do("
			INSERT INTO ct_cache_tables (tani,kind,name)
			VALUES (\"$args{tani}\", \"$args{kind}\",\"$args{name}\")
		",1) unless ($args{kind} =~ /^code/ );
		return (0,1);
	}
}

sub cache_regist{
	my $self_ = shift;
	my %args = @_;
	
	# 新規キャッシュとして登録
	mysql_exec->do("
		INSERT INTO ct_cache_tables (tani,kind,name,hyosos)
		VALUES (
			\"$args{tani}\",
			\"$args{kind}\",
			\"$args{name}\",
			\"$args{hyosos}\"
		)
	",1);
}

sub cache_code_if_ok{
	my $self_ = shift;
	my %args = @_;

	my $h = mysql_exec->select("
		SELECT hyosos
		FROM ct_cache_tables
		WHERE 
			    tani = \"$args{tani}\"
			AND kind = \"$args{kind}\"
			AND name = \"$args{name}\"
	",1)->hundle;
	my $t = $h->fetch;
	$t = $t->[0];
	#print "cache code chk: $t\n";
	return 0 unless $t;
	return 0 if $t eq '-1';
	return 1;
}

#--------------#
#   アクセサ   #

sub if_done{                  # コーディングが実行されているか
	my $self = shift;
	return $self->{if_done};
}

sub tables{                   # アトム・テーブルをまとめたテーブルのリスト
	my $self = shift;
	return $self->{tables};
}

sub tani{                     # コーディング単位
	my $self = shift;         # $self->ready("単位")で指定されたもの
	return $self->{tani};
}

sub res_table{                # コーディング結果を保存したテーブル
	my $self = shift;         # $self->code("テーブル名")で指定されたもの
	my $val  = shift;
	if ( length($val) ){
		$self->{res_table} = $val;
	}
	return $self->{res_table};
}

sub res_col{                  # コーディング結果を保存したカラム
	my $self = shift;
	my $val  = shift;
	if ( length($val) ){
		$self->{res_col} = $val;
	}
	
	if (length($self->{res_col})){
		return $self->{res_col};
	} else {
		return 'num';
	}
}

sub name{                     # コード名
	my $self = shift;         # ファイルから読み込み
	return $self->{name};
}
sub row_condition{
	my $self = shift;
	return $self->{row_condition};
}

1;