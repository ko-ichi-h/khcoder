package mysql_getdoc;
use strict;
use mysql_exec;

use mysql_getdoc::bun;
use mysql_getdoc::dan;
use mysql_getdoc::h1;
use mysql_getdoc::h2;
use mysql_getdoc::h3;
use mysql_getdoc::h4;
use mysql_getdoc::h5;

sub get{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	$class .= '::'."$args{tani}";
	bless $self, $class;

	# 文書の特定
	unless ( length($self->{doc_id}) ){
		$self->{doc_id} = $self->get_doc_id;
	}

	# 本文の取り出し
	my $d = $self->get_body;

	my %for_color = ();                           # 強調指定の準備
	foreach my $i (@{$self->{w_force}}){               # その他のコード
		$for_color{$i} = "force";
	}
	foreach my $i (@{$self->{w_other}}){               # その他のコード
		$for_color{$i} = "CodeW";
	}
	foreach my $i (@{$self->{w_search}}){              # 検索語
		$for_color{$i} = "search";
	}
	#print "p2 ";
	my $html = mysql_exec->select("                    # HTMLタグ
		select hyoso.id
		from  hselection,
			genkei LEFT JOIN hyoso ON hyoso.genkei_id = genkei.id
		where
			genkei.khhinshi_id = hselection.khhinshi_id
			AND hselection.name = 'HTMLタグ'
	",1)->hundle;
	while (my $i = $html->fetch){
		$for_color{$i->[0]} = 'html';
	}
	
	#print "p3, ";
	my @body = (); my $last = -1;                 # 改行付加＆検索語強調
	my $lastw;
	foreach my $i (@{$d}){
		unless ($i->[2] == $last){
			$last = $i->[2];
			push @body, ["\n",''];
		}
		
		my $c = "$lastw"."$i->[0]";
		if ($c =~ /^<\/[Hh][1-5]><[Hh][1-5]>$/o){ push @body, ["\n",'']; }
		
		my $k = ''; if ($for_color{$i->[1]}){$k = $for_color{$i->[1]};}
		push @body, [Jcode->new("$i->[0]")->sjis, $k];
		$lastw = $i->[0];
		
	}
	$self->{body} = \@body;
	
	# 上位見出しの取り出し
	#print "head\n";
	$self->{header} = $self->get_header;
	
	
	return $self;
}

#----------------#
#   本文の取得   #

sub get_body{
	my $self = shift;
	my $tani = $self->{tani};
	
	my $sql = "SELECT hyoso.name, hyoso.id, hyosobun.dan_id\n";
	$sql   .= "FROM hyoso, hyosobun, $tani\n";
	$sql   .= "WHERE\n";
	$sql   .= "    $tani.id = $self->{doc_id}\n";
	$sql   .= "    AND hyosobun.hyoso_id = hyoso.id\n";
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$sql .= "    AND hyosobun.$i"."_id = $tani.$i"."_id\n";
		if ($tani eq $i){last;}
	}
	$sql   .= "ORDER BY hyosobun.id";
	return mysql_exec->select($sql,1)->hundle->fetchall_arrayref;
}


#----------------#
#   文書の特定   #

sub get_doc_id{
	my $self = shift;
	my $tani = $self->{tani};
	
	my $sql = "SELECT $tani.id\n";
	$sql   .= "FROM hyosobun, $tani\n";
	$sql   .= "WHERE\n";
	$sql   .= "    hyosobun.id = $self->{hyosobun_id}\n";
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$sql .= "    AND hyosobun.$i"."_id = $tani.$i"."_id\n";
		if ($tani eq $i){last;}
	}
	if (my $check = mysql_exec->select($sql,1)->hundle->fetch){
		return $check->[0]
	} else {
		my $n = 1;
		while (1){
			my $try = $self->{hyosobun_id} + $n;
			my $sql = "SELECT $tani.id\n";
			$sql   .= "FROM hyosobun, $tani\n";
			$sql   .= "WHERE\n";
			$sql   .= "    hyosobun.id = $try\n";
			foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
				$sql .= "    AND hyosobun.$i"."_id = $tani.$i"."_id\n";
				if ($tani eq $i){last;}
			}
			if (my $check = mysql_exec->select($sql,1)->hundle->fetch){
				#print "$n tries\n";
				return $check->[0];
			}
			++$n;
			if ($n > 1000){
				return 1;
			}
		}
	}
}


#----------------------#
#   上位見出しの取得   #

sub get_header{
	my $self = shift;
	my $tani = $self->{tani};
	my @possible_header = ('h1','h2','h3','h4','h5');
	my $headers = '';
	
	my $sql = "SELECT id,";
	foreach my $i (@possible_header){
		$sql .= "$i"."_id,";
		if ($i eq $tani){last;}
	}
	chop $sql;
	$sql .= "\n";
	$sql .= "FROM $tani\n";
	$sql .= "WHERE id = $self->{doc_id}";
	my $id_info = mysql_exec->select($sql,1)->hundle->fetch;

	my %possible;
	foreach my $i (@possible_header){
		if ($i eq $tani){last;}                   # 上位かどうかチェック
		if (                                      # タグがあるかチェック
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){
			#print "getting $i header...\n";
			my $sql = "SELECT rowtxt\n";
			$sql   .= "FROM bun_r, bun\n";
			$sql   .= "WHERE\n";
			$sql   .= "    bun_r.id = bun.id\n";
			$sql   .= "    AND bun_id = 0\n";
			$sql   .= "    AND dan_id = 0\n";
			my $frag = 0; my $n = 5;
			foreach my $h ('h5','h4','h3','h2','h1'){
				if ($i eq $h){$frag = 1}
				if ($frag){
					$sql .= "    AND $h"."_id = $id_info->[$n]\n";
				} else {
					$sql .= "    AND $h"."_id = 0\n";
				}
				--$n;
			}
			$sql   .= "LIMIT 1";
			my $h = mysql_exec->select("$sql",1)->hundle->fetch->[0];
			$h = Jcode->new($h)->sjis;
			$headers .= "$h\n";
		}
	}
	return $headers;
}

sub if_next{
	my $self = shift;
	my $max = mysql_exec->select("
		SELECT max(id)
		FROM $self->{tani}
	",1)->hundle->fetch->[0];
	if ($self->{doc_id} < $max){
		return 1;
	} else {
		return 0;
	}
}


sub doc_id{
	my $self = shift;
	return $self->{doc_id};
}
sub body{
	my $self = shift;
	return $self->{body};
}
sub header{
	my $self = shift;
	return $self->{header};
}




1;