package mysql_crossout;
use strict;
use utf8;

use mysql_exec;
use mysql_crossout::csv;
use mysql_crossout::spss;
use mysql_crossout::tab;
use mysql_crossout::var;
use mysql_crossout::r_com;

use mysql_crossout::selected;

sub new{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	bless $self, $class;

	unless ( length($self->{max}) ){
		$self->{max} = 0;
	}

	return $self;
}

sub run{
	my $self = shift;
	
	use Benchmark;
	
	# 見出しの取得
	$self->{midashi} = mysql_getheader->get_selected(tani => $self->{tani});

	# 一時ファイルの命名
	$self->{file_temp} = "temp.dat";
	while (-e $self->{file_temp}){
		$self->{file_temp} .= ".tmp";
	}

	$self->make_list;
	
	my $t0 = new Benchmark;
	$self->out2;
	$self->finish;
	
	my $t1 = new Benchmark;
	print "\n",timestr(timediff($t1,$t0)),"\n";
}

#----------------#
#   データ作製   #

sub out2{                               # length作製をする
	my $self = shift;
	
	open (F,'>:encoding(utf8)', $self->{file_temp}) or die;
	
	# セル内容の作製
	my $id = 1;
	my $last = 1;
	my $started = 0;
	my %current = ();
	while (1){
		my $sth = mysql_exec->select(
			$self->sql2($id, $id + 30000),
			1
		)->hundle;
		$id += 30000;
		unless ($sth->rows > 0){
			last;
		}
		
		while (my $i = $sth->fetch){
			if ($last != $i->[0] && $started == 1){
				# 書き出し
				my $temp = "$last,";
				if ($self->{midashi}){
					my $jcode_tmp = kh_csv->value_conv($self->{midashi}->[$last - 1]).',';
					#my $chk0 = utf8::is_utf8( $self->{midashi}->[$last - 1] );
					#my $chk1 = utf8::is_utf8( $jcode_tmp );
					
					#$jcode_tmp = Jcode->new($jcode_tmp,'euc')->sjis if $::config_obj->os eq 'win32';
					$temp .= $jcode_tmp;
				}
				foreach my $h ( 'length_c','length_w',@{$self->{wList}} ){
					if ($current{$h}){
						$temp .= "$current{$h},";
					} else {
						$temp .= "0,";
					}
				}
				chop $temp;
				print F "$temp\n";
				# 初期化
				%current = ();
				$last = $i->[0];
			}
			
			$last = $i->[0] unless $started;
			$started = 1;
			
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
			$current{'length_c'} += length($i->[2]);
			if ($self->{wName}{$i->[1]}){
				++$current{$i->[1]};
			}
		}
		$sth->finish;
	}
	
	# 最終行の出力
	my $temp = "$last,";
	if ($self->{midashi}){
		my $jcode_tmp = kh_csv->value_conv($self->{midashi}->[$last - 1]).',';
		#$jcode_tmp = Jcode->new($jcode_tmp,'euc')->sjis if $::config_obj->os eq 'win32';
		$temp .= $jcode_tmp;
	}
	foreach my $h ( 'length_c','length_w',@{$self->{wList}} ){
		if ($current{$h}){
			$temp .= "$current{$h},";
		} else {
			$temp .= "0,";
		}
	}
	chop $temp;
	print F "$temp\n";
	close (F);
}

sub sql2{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;


	my $sql;
	$sql .= "SELECT $self->{tani}.id, genkei.id, hyoso.name, genkei.nouse\n";
	$sql .= "FROM   hyosobun USE INDEX (PRIMARY), hyoso, genkei, $self->{tani}\n";
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
	#$sql .= "	AND genkei.nouse = 0\n";
	$sql .= "	AND hyosobun.id >= $d1\n";
	$sql .= "	AND hyosobun.id <  $d2\n";
	$sql .= "ORDER BY hyosobun.id";
	return $sql;
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

#--------------------------#
#   出力する単語数を返す   #

sub wnum{
	my $self = shift;
	my $nc   = shift;
	
	$self->{min_df} = 0 unless length($self->{min_df});
	
	my $sql = "
		SELECT count(*)
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
	#print "$sql\n";
	
	$_ = mysql_exec->select($sql,1)->hundle->fetch->[0];
	unless ($nc){
		1 while s/(.*\d)(\d\d\d)/$1,$2/; # 位取り用のコンマを挿入
	}
	return $_;
}


sub get_default_freq{
	my $self = shift;
	
	my $target = shift;
	
	$self->{min_df} = 0 unless length($self->{min_df});
	
	my $sql = "
		SELECT num, count(*)
		FROM   genkei, hselection, df_$self->{tani}
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			# AND genkei.num >= $self->{min}
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
	$sql .= "GROUP BY genkei.num\n";
	$sql .= "ORDER BY genkei.num DESC\n";
	
	my $h = mysql_exec->select($sql,1)->hundle;

	# stage 1
	my $cum = 0;
	my ($words, $cut);
	while (my $i = $h->fetch){
		$cum += $i->[1]; # 累積
		if ($cum >= $target) {
			my $rem = $i->[0] % 5;
			my $can_0 = $i->[0] - $rem;
			my $can_1 = $can_0 + 5;
			
			$self->{min} = $can_0;
			my $words_0 = $self->wnum(1);
			my $dif_0 = $words_0 - $target;
			
			$self->{min} = $can_1;
			my $words_1 = $self->wnum(1);
			my $dif_1 = $target - $words_1;
			
			print "stage 1: $can_0, $words_0, $dif_0 ; $can_1, $words_1, $dif_1 ; $target\n";
			
			if ($dif_0 < $dif_1) {
				$cut = $can_0;
				$words = $words_0;
				last;
			} else {
				$cut = $can_1;
				$words = $words_1;
				last;
			}
		}
	}
	
	# stage 2
	while ($words < $target / 3 * 2) {
		--$cut;
		$self->{min} = $cut;
		$words = $self->wnum(1);
		print "stage 2: $cut, $words\n";
		if ($cut <= 2) {
			last;
		}
	}
	
	$cut = 2 if $cut < 2;
	return $cut;
}

1;