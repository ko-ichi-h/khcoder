package mysql_crossout::tab;
use base qw(mysql_crossout);
use strict;

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
	
	
	open (F,'>:encoding(utf8)', $self->{file_temp}) or die("could not open $self->{file_temp}");
	
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
				my $temp = "$last\t";
				if ($self->{midashi}){
					$temp .= kh_csv->value_conv_t($self->{midashi}->[$last - 1])."\t";
				}
				foreach my $h ( 'length_c','length_w',@{$self->{wList}} ){
					if ($current{$h}){
						$temp .= "$current{$h}\t";
					} else {
						$temp .= "0\t";
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
	my $temp = "$last\t";
	if ($self->{midashi}){
		$temp .= kh_csv->value_conv_t($self->{midashi}->[$last - 1])."\t";
	}
	foreach my $h ( 'length_c','length_w',@{$self->{wList}} ){
		if ($current{$h}){
			$temp .= "$current{$h}\t";
		} else {
			$temp .= "0\t";
		}
	}
	chop $temp;
	print F "$temp\n";
	close (F);
}

sub finish{
	my $self = shift;
	
	open (OUTF,'>:encoding(utf8)', $self->{file}) or
		gui_errormsg->open(
			type    => 'file',
			thefile => $self->{file},
		);
	
	# ヘッダ行の作製
	my $head = ''; my @head;
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$head .= "$i\t";
		push @head, $i;
		if ($self->{tani} eq $i){
			last;
		}
	}
	if ($self->{midashi}){
		$head .= "id\tname\tlength_c\tlength_w\t";
	} else {
		$head .= "id\tlength_c\tlength_w\t";
	}

	foreach my $i (@{$self->{wList}}){
		$head .= kh_csv->value_conv_t($self->{wName}{$i})."\t";
	}
	chop $head;
	#if ($::config_obj->os eq 'win32'){
	#	$head = Jcode->new($head)->sjis;
	#}
	print OUTF "$head\n";
	
	# 位置情報とのマージ
	
	my $sql;
	$sql .= "SELECT ";
	foreach my $i (@head){
		$sql .= "$i"."_id,";
	}
	chop $sql;
	$sql .= "\nFROM $self->{tani}\n";
	$sql .= "ORDER BY id";
	my $sth = mysql_exec->select($sql,1)->hundle;
	
	open (F, '<:encoding(utf8)', $self->{file_temp}) or die;
	while (<F>){
		my $srow = $sth->fetchrow_hashref;
		my $head;
		foreach my $i (@head){
			$head .= $srow->{"$i"."_id"};
			$head .= "\t";
		}
		print OUTF "$head"."$_";
	}
	close (F);
	close (OUTF);
	unlink("$self->{file_temp}");
}



1;