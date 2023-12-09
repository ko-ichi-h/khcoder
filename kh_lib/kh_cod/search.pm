package kh_cod::search;
use base qw(kh_cod);
use strict;
use utf8;
use mysql_exec;

my $last_tani = '';
my $last_order = '';
my $docs_per_once = 200;

my %sql_join = (
	'bun' =>
		'bun.id = bun_r.id',
	'dan' =>
		'
			    dan.dan_id = bun.dan_id
			AND dan.h5_id = bun.h5_id
			AND dan.h4_id = bun.h4_id
			AND dan.h3_id = bun.h3_id
			AND dan.h2_id = bun.h2_id
			AND dan.h1_id = bun.h1_id
		',
	'h5' =>
		'
			    h5.h5_id = bun.h5_id
			AND h5.h4_id = bun.h4_id
			AND h5.h3_id = bun.h3_id
			AND h5.h2_id = bun.h2_id
			AND h5.h1_id = bun.h1_id
		',
	'h4' =>
		'
			    h4.h4_id = bun.h4_id
			AND h4.h3_id = bun.h3_id
			AND h4.h2_id = bun.h2_id
			AND h4.h1_id = bun.h1_id
		',
	'h3' =>
		'
			    h3.h3_id = bun.h3_id
			AND h3.h2_id = bun.h2_id
			AND h3.h1_id = bun.h1_id
		',
	'h2' =>
		'
			    h2.h2_id = bun.h2_id
			AND h2.h1_id = bun.h1_id
		',
	'h1' =>
		'h1.h1_id = bun.h1_id'
);

sub new{
	my $class = shift;
	my $self;
	$self->{dummy} = '0';
	
	bless $self, $class;
	
	return $self;
}

#------------------------------#
#   直接入力コードの読み込み   #

sub add_direct{
	my $self = shift;
	my %args = @_;
	my $debug = 0;
	
	my $direct = kh_msg->get('direct');
	
	# 既に追加されていた場合はいったん削除
	if ($self->{codes}){
		if ($self->{codes}[0]->name eq $direct){
			print "Deleting old \'direct\' code\n" if $debug;
			shift @{$self->{codes}};
		}
	}
	print "direct-raw: $args{raw}\n" if $debug;
	
	#$args{raw} = Jcode->new($args{raw}, 'sjis')->euc;
	if ($args{raw} =~ /\r|\n/){
		my $t = $args{raw};
		$t =~ tr/\r\n/__/;
		$args{raw} =~ s/\r|\n//g;
		print
			"illegal input! using ATOK? \"",
			$t,
			"\"\n"
		;
	}
	
	if ($args{mode} eq 'code'){                   #「code」の場合
		unshift @{$self->{codes}}, kh_cod::a_code->new(
			$direct,
			$args{raw},
		);
	}
	elsif ($args{mode} eq 'var') {                # 「var」の場合
		if ( length($args{raw}) ) {
			$args{raw} = '<>'.$args{raw}.'<>';
		}
		
		unshift @{$self->{codes}}, kh_cod::a_code->new(
			$direct,
			$args{raw},
		);
	} else {                                      # 「AND」,「OR」の場合
		#$args{raw} = Jcode->new($args{raw},'euc')->tr('　',' ');
		$args{raw} =~ tr/　/ /;
		$args{raw} =~ tr/\t\n/  /;
		
		$args{raw} =~ s/(?:\x0D\x0A|[\x0D\x0A])?$/ /;
		my @temp = ($args{raw} =~ /('(?:[^']|'')*'|"(?:[^"]|"")*"|[^ ]*) /g);
		
		my ($n, $t) = (0,'');
		foreach my $i (@temp){
			unless ( length($i) ){next;}
			if ($n){$t .= " $args{mode} ";}
			if ( $i =~ /^(and|or|not)$/i ){
				$i = "\"$i\"";
			}
			$t .= "$i";
			++$n;
		}
		print "direct-code: $t \n" if $debug;
		
		unshift @{$self->{codes}}, kh_cod::a_code->new(
			$direct,
			$t
		);
	}
}

#----------------------#
#   コーディング実行   #

sub code{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;
	
	unless ($self->{codes}){
		return 0;
	}
	
	my $n = 0;
	foreach my $i (@{$self->{codes}}){
		my $res_table = "ct_$tani"."_dscode_$n";
		++$n;
		$i->ready($tani,$self->{order}) or next;
		$i->code($res_table,$self->{order});
		if ($i->res_table){ push @{$self->{valid_codes}}, $i; }
		
	}
	return $self;
}


#----------------#
#   検索の実行   #

sub search{
	my $self = shift;
	my %args = @_;
	
	$self->{tani}  = $args{tani};
	$self->{order} = $args{order};
	$self->{last_search_words} = undef;

	# デバッグコード
	#foreach my $i (@{$self->{codes}}){
	#	print Jcode->new($i->name)->sjis."\n".Jcode->new($i->row_condition)->sjis."\n";
	#}
	#print "\n";

	# コーディング
	print "kh_cod::search -> coding...\n";
	
	if (
		   ( $self->{coded} )
		&& ( $last_tani eq $self->{tani} )
		&& (
			   ( $last_order eq $self->{order} )
			|| ( $self->{order} eq 'by' )
		)
	){                                                  # コーディング済み
		#print "\t[re-use]\n";
		$self->{codes}[0]->clear;
		$self->{codes}[0]->ready($args{tani});
		$self->{codes}[0]->code("ct_$args{tani}_dscode_0",$self->{order});
	} else {                                            # 全てコーディング
		unless ($last_tani eq $self->{tani}){
			$self->{valid_codes} = undef;
		}
		if ($self->{codes}){
			foreach my $i (@{$self->{codes}}){
				$i->clear;
			}
		}
		$self->code($self->{tani}) or return 0;
	}

	# AND条件の時に、0コードが存在した場合はreturn
	unless ($self->valid_codes){ return undef; }
	unless ($self->{valid_codes}){
		return undef;
	}
	if (
		   ( $args{method} eq 'and' )
		&& ( @{$self->{valid_codes}} < @{$args{selected}} )
	) {
		return undef;
	}
	
	# 「＃コード無し」の使われ方をチェック
	my $code_num_check = @{$self->{codes}};
	my $no_code_flag = 0;
	foreach my $i (@{$args{selected}}){
		if ($i == $code_num_check){
			print "\    'no code\' selected\n";
			$no_code_flag = 1;
			last;
		}
	}
	if ($no_code_flag){
		unless (
			   (@{$args{selected}} == 1 )
			|| (
					   (@{$args{selected}} == 2)
					&& ($args{selected}->[0] == 0 )
			   )
		){
			print "    error: illegal use of \'no code\'\n";
			return undef;
		};
		$self->cumulate('ds') if @{$self->tables} > 30;
	}
	
	# 合致する文書のリストを作成
	print "kh_cod::search -> searching...\n";
		# テーブルの準備
	mysql_exec->drop_table("temp_doc_search");
	mysql_exec->do("
		create temporary table temp_doc_search(
			rnum int   auto_increment primary key not null,
			id   int   not null,
			num  float not null
		)
	",1);
	
	# リストをテーブルに投入
	my $sql;
	$sql .= "INSERT INTO temp_doc_search (id, num)\n";
			# 「コード無し」を使用している場合
	if ($no_code_flag){
		$sql .= "SELECT $args{tani}.id,1\nFROM $args{tani}\n";
		my $n = 0;
		my %if_table_mentioned = ();
		foreach my $i (@{$self->{codes}}){
			if ($n == 0 && @{$args{selected}} == 1 ){$n = 1; next;}
			next unless $i->res_table;
			next if     $if_table_mentioned{$i->res_table};
			$if_table_mentioned{$i->res_table} = 1;
			$sql .=
				"LEFT JOIN "
				.$i->res_table
				." ON $args{tani}.id = "
				.$i->res_table
				.".id\n";
			++$n;
		}
		
		$sql .= "WHERE\n";
		if (@{$args{selected}} == 2){
			$sql .=
				"IFNULL("
				.$self->{codes}[0]->res_table
				."."
				.$self->{codes}[0]->res_col
				.",0)\n AND ";
		}
		$sql .= "NOT (\n";
		$n = 0;
		foreach my $i (@{$self->{codes}}){
			unless  ($n){$n = 1; next;}
			unless ($i->res_table){next;}
			$sql .= " OR " if ($n > 1);
			$sql .=
				"IFNULL("
				.$i->res_table
				."."
				.$i->res_col
				.",0)\n";
			++$n;
		}
		$sql .= ")\n";
		$sql .= "ORDER BY $args{tani}.id";
	}
	
			# 「コード無し」を使用しない場合
	else {
		$sql .= "SELECT $args{tani}.id, ";
		if ($args{order} =~ /^tf/o){
			$sql .= "100 - (";
			my $nn = 0;
			foreach my $i (@{$args{selected}}){
				if ($nn){
					$sql .= " + ";
				} else {
					$nn = 1;
				}
				
				if ($self->{codes}[$i]->res_table){
					$sql .=
						"IFNULL("
						.$self->{codes}[$i]->res_table
						."."
						.$self->{codes}[$i]->res_col
						.",0)\n";
					$nn = 2;
				}
			}
			if ($nn == 2){
				$sql .= ") / $args{tani}_length.w as tf\n";
			} else {
				$sql .= "0) as tf\n";
			}
			$sql .= "FROM $args{tani}_length, $args{tani}\n";
		}
		elsif ($args{order} eq 'var') {
			my $i = $args{selected}->[0];
			if ($self->{codes}[$i]->res_table){
				$sql .=
					"IFNULL("
					.$self->{codes}[$i]->res_table
					."."
					.$self->{codes}[$i]->res_col
					.",0) as var\n";
			}
			$sql .= "FROM $args{tani}\n";
		}
		else {
			$sql .= "1\n";
			$sql .= "FROM $args{tani}\n";
		}
		
		foreach my $i (@{$args{selected}}){
			unless ($self->{codes}[$i]->res_table){
				next;
			}
			$sql .=
				"LEFT JOIN "
				.$self->{codes}[$i]->res_table
				." ON $args{tani}.id = "
				.$self->{codes}[$i]->res_table
				.".id\n";
		}
		$sql .= "WHERE\n";
		if ($args{order} =~ /^tf/o){
			$sql .= "$args{tani}.id = $args{tani}_length.id AND ";
		}
		$sql .= " (\n";
		my $n = 0;
		foreach my $i (@{$args{selected}}){
			if ($n){ $sql .= "$args{method} "; }
			if ($self->{codes}[$i]->res_table){
				$sql .=
					$self->{codes}[$i]->res_table
					."."
					.$self->{codes}[$i]->res_col
					." is not null\n";
			} else {
				$sql .= "0\n";
			}
			++$n;
		}
		$sql .= ")\n";
		if ($args{order} =~ /^tf/o){
			$sql .= "ORDER BY tf,$args{tani}.id";
		}
		elsif ($args{order} eq 'var') {
			$sql .= "ORDER BY var DESC, $args{tani}.id";
		} else {
			$sql .= "ORDER BY $args{tani}.id";
		}
	}
	#print "\n$sql\n";
	mysql_exec->do($sql,1);
	
	# 検索に利用した語（表層）のリスト
	print "kh_cod::search -> getting word list...\n";
	my (@words, %words);
	foreach my $i (@{$args{selected}}){
		next unless $self->{codes}[$i];
		next unless $self->{codes}[$i]->res_table;
		if ($self->{codes}[$i]->hyosos){
			foreach my $h (@{$self->{codes}[$i]->hyosos}){
				++$words{$h};
			}
		}
	}
	@words = (keys %words);
	$self->{last_search_words} = \@words;
	# 検索に利用した文字列のリスト
	my (@strs, %strs);
	foreach my $i (@{$args{selected}}){
		next unless $self->{codes}[$i];
		next unless $self->{codes}[$i]->res_table;
		if ($self->{codes}[$i]->strings){
			foreach my $h (@{$self->{codes}[$i]->strings}){
				++$strs{$h};
			}
		}
	}
	@strs = (keys %strs);
	$self->{last_search_strings} = \@strs;
	
	$self->{coded} = 1;
	$last_tani  = $self->{tani};
	$last_order = $self->{order};
	
	return $self;
}

#--------------------#
#   結果の取り出し   #

sub last_search_words{
	my $self = shift;
	return $self->{last_search_words};
}
sub last_search_strings{
	my $self = shift;
	return $self->{last_search_strings};
}

sub total_hits{
	my $self = shift;
	
	my $sth = mysql_exec->select("select count(*) from temp_doc_search")->hundle
		or return 0;
	my $n = $sth->fetch or return 0;
	if ($n){
		return $n->[0];
	} else {
		return 0;
	}
}
sub fetch_results{
	my $self  = shift;
	my $start = shift;
	
	print "kh_cod::search -> fetching";

	my $sth = mysql_exec->select("
		SELECT id
		FROM   temp_doc_search
		WHERE
			    rnum >= $start
			AND rnum <  $start + $docs_per_once
		ORDER BY rnum
	",1)->hundle;

	my @result;
	while (my $i = $sth->fetch){
		my $t = kh_cod::search->get_doc_head($i->[0],$self->{tani});
		
		if ($::project_obj->morpho_analyzer_lang eq 'kr' ) {
			$t = gui_window->kchar_patchim($t);
		}
		
		push @result, [
			$i->[0],
			$t
		];
		print ".";
	}
	print "\n";
	
	return \@result;
}

sub fetch_results_var{
	my $self  = shift;
	my $start = shift;
	my $var   = shift;
	
	print "kh_cod::search -> fetching (var)";

	my $var_obj = mysql_outvar::a_var->new($var);
	
	
	my $sth = mysql_exec->select("
		SELECT temp_doc_search.id, $var_obj->{table}.$var_obj->{column}
		FROM   temp_doc_search, $var_obj->{table}
		WHERE
			    temp_doc_search.rnum >= $start
			AND temp_doc_search.rnum <  $start + $docs_per_once
			AND temp_doc_search.id = $var_obj->{table}.id
		ORDER BY temp_doc_search.rnum
	",1)->hundle;

	my @result;
	while (my $i = $sth->fetch){
		push @result, [
			$i->[0],
			kh_cod::search->get_doc_head($i->[0],$self->{tani}),
			$i->[1]
		];
		print ".";
	}
	print "\n";
	return \@result;
}

#-----------------------------------------#
#   1つの文書に与えられたコードのリスト   #

sub check_a_doc{
	my $self   = shift;
	my $doc_id = shift;
	
	# コーディング結果の読み出し
	my $text = kh_msg->get('codes')."\n"; # ・この文書にヒットしたコード （現在開いているコーディング・ルールファイルの中で）
	my (@words, %words, $n);
	foreach my $i (@{$self->{codes}}){
		unless ($i->res_table){next;}
		my $sql .= 
			"SELECT ".$i->res_col." FROM ".$i->res_table." WHERE id = $doc_id";
		if (mysql_exec->select($sql,1)->hundle->rows){
			$text .= "    ".gui_window->gui_jchar( $i->name )."\n";
			if ($i->hyosos){
				foreach my $h (@{$i->hyosos}){
					++$words{$h};
				}
			}
			++$n;
		}
	}
	@words = (keys %words);
	unless ($n){
		$text .= "    ".kh_msg->get('no_codes')."\n"; # ＃コード無し
	}
	$text .= "\n";
	
	# いくつ目の検索結果かをチェック
	my $text2 = '';
	my ($rnum_all, $rnum);
	if (
		$rnum = mysql_exec->select("
			SELECT rnum
			FROM temp_doc_search
			WHERE id = $doc_id
		",1)->hundle->fetch
	){
		$rnum = $rnum->[0];
		$rnum_all = $self->total_hits;
		$text2 .= kh_msg->get('gui_window::word_conc->currentDoc')."$rnum / $rnum_all,  ";
	} else {
		$text2 .= kh_msg->get('gui_window::doc_view->current_doc'); # ・現在表示中の文書：  
	}
	
	#$text = Encode::encode('cp932', $text);
	return ($text,\@words, $text2);
}


#--------------------------#
#   文書の先頭部分を取得   #

sub get_doc_head{
	my $self = shift;
	my $id   = shift;
	my $tani = shift;
	
	my $sql;
	if ($tani eq 'bun'){
		$sql = "
			SELECT rowtxt
			FROM bun_r, bun
			WHERE
				    bun_r.id = bun.id
				AND bun.id = $id
		";
	} else {
		$sql = "
			SELECT rowtxt
			FROM bun_r, bun, $tani
			WHERE $sql_join{$tani}
				AND bun_r.id = bun.id
				AND $tani.id = $id
			LIMIT 5
		";
	}
	
	my $sth = mysql_exec->select($sql,1)->hundle;
	
	my $spacer = $::project_obj->spacer;  # スペーサー設定
	
	my $r;
	while (my $i = $sth->fetch){
		$r .= $spacer if length($r);
		$r .= $i->[0];
		if (length($r) > $::config_obj->DocSrch_CutLength){
			last;
		}
	}
	
	# 切り落とし
	if (length($r) > $::config_obj->DocSrch_CutLength){
		my $len = $::config_obj->DocSrch_CutLength;
		if (
			substr($r,0,$len) =~ /\x8F$/
			or substr($r,0,$len) =~ tr/\x8E\xA1-\xFE// % 2 
		){
			--$len;
			if (
				substr($r,0,$len) =~ /\x8F$/
				or substr($r,0,$len) =~ tr/\x8E\xA1-\xFE// % 2 
			){
				--$len;
			}
		}
		$r = substr($r,0,$len);
		$r .= '…';
	}
	
	return $r;
	
}

sub docs_per_once{
	return $docs_per_once;
}


1;