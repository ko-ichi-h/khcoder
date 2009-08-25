package kh_nbayes;

use strict;
use Algorithm::NaiveBayes;

sub learn_from_ov{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	bless $self, $class;

	unless ( length($self->{max}) ){
		$self->{max} = 0;
	}

	$self->{cls} = Algorithm::NaiveBayes->new;

	$self->make_list;
	$self->get_ov;
	$self->out2;

	print "start training... ";
	$self->{cls}->train;
	print "ok\n";

	$self->{cls}->save_state($self->{path});

	#use Data::Dumper;
	#print Dumper($self->{cls});

	undef $self;
	return 1;
}

#----------------#
#   データ作製   #

sub out2{                               # length作製をする
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
				unless (
					   length($self->{outvar_cnt}{$last}) == 0
					|| $self->{outvar_cnt}{$last} eq '.'
					|| $self->{outvar_cnt}{$last} eq '欠損値'
					|| $self->{outvar_cnt}{$last} =~ /missing/i
				){
					$self->{cls}->add_instance(
						attributes => \%current,
						label      => $self->{outvar_cnt}{$last},
					);
					
					#print "out: $last\n";
					#print Jcode->new("label: $self->{outvar_cnt}{$last}\n", 'euc')->sjis;
					#foreach my $h (keys %current){
					#	print Jcode->new("at: $h, $current{$h}\n", 'euc')->sjis;
					#}
				}
				
				# 初期化
				%current = ();
				$last = $i->[0];
			}

			if ($self->{wName}{$i->[1]}){
				my $t = '';
				$t .= $self->{wName}{$i->[1]};
				$t .= '-';
				$t .= $self->{hName}{"$self->{wHinshi}{$i->[1]}"};
				
				#print Jcode->new("r: $t\n",'euc')->sjis;
				
				++$current{$t};
			}
		}
		$sth->finish;
	}
	
	unless (
		   length($self->{outvar_cnt}{$last}) == 0
		|| $self->{outvar_cnt}{$last} eq '.'
		|| $self->{outvar_cnt}{$last} eq '欠損値'
		|| $self->{outvar_cnt}{$last} =~ /missing/i
	){
		$self->{cls}->add_instance(
			attributes => \%current,
			label      => $self->{outvar_cnt}{$last},
		);
		
		#print "out: $last\n";
		#print Jcode->new("label: $self->{outvar_cnt}{$last}\n", 'euc')->sjis;
		#foreach my $h (keys %current){
		#	print Jcode->new("at: $h, $current{$h}\n", 'euc')->sjis;
		#}
	}

	return $self;
}

sub sql2{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;


	my $sql;
	$sql .= "SELECT $self->{tani}.id, genkei.id\n";
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
	$sql .= "SELECT id, $var_obj->{column} FROM $var_obj->{table} ";
	$sql .= "ORDER BY id";

	my $h = mysql_exec->select($sql,1)->hundle;

	my $outvar;
	while (my $i = $h->fetch){
		if ( length( $var_obj->{labels}{$i->[1]} ) ){
			$outvar->{$i->{0}} = $var_obj->{labels}{$i->[1]};
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


1;