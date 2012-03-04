package mysql_crossout::selected::r_com;
use base qw(mysql_crossout::selected);
use strict;

sub run{
	my $self = shift;
	
	use Benchmark;
	
	# 見出しの取得
	$self->{midashi} = mysql_getheader->get_selected(tani => $self->{tani});

	$self->make_list;

	# $self->{tani} = $self->{tani2};

	my $t0 = new Benchmark;
	$self->out2;
	#$self->finish;
	
	my $t1 = new Benchmark;
	print "\n",timestr(timediff($t1,$t0)),"\n";
	
	return $self->{r_command};
}

#----------------#
#   データ作製   #

sub out2{                               # length作製をする
	my $self = shift;
	
	my %doc_id = ();
	foreach my $i (@{$self->{doc_ids}}){
		$doc_id{$i} = 1;
	}
	
	$self->{r_command} = "d <- NULL\n";
	my $row_names = '';
	
	my $length = 'doc_length_mtr <- matrix( c( ';
	
	# セル内容の作製
	my $id = 1;
	my $last = 1;
	my %current = ();
	my $nrow = 0;
	$self->{r_command} .= "d <- matrix( c(";
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
				my $temp = "$last,";
				if ($self->{midashi} && $doc_id{$last}){
					$self->{midashi}->[$last - 1] =~ s/"/ /g;
					$row_names .= '"'.$self->{midashi}->[$last - 1].'",';
				}
				foreach my $h (@{$self->{wList}} ){
					if ($current{$h}){
						$temp .= "$current{$h},";
					} else {
						$temp .= "0,";
					}
				}
				if ($doc_id{$last}){
					$self->{r_command} .= "$temp\n";
					$length .= "$current{length_c},$current{length_w},";
					++$nrow;
				}
				# 初期化
				%current = ();
				$last = $i->[0];
			}
			
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
			$current{'length_c'} += (length($i->[2]) / 2);
			if ($self->{wName}{$i->[1]}){
				++$current{$i->[1]};
			}
		}
		$sth->finish;
	}
	
	# 最終行の出力
	my $temp = "$last,";
	if ($self->{midashi} && $doc_id{$last}){
		$self->{midashi}->[$last - 1] =~ s/"/ /g;
		$row_names .= '"'.$self->{midashi}->[$last - 1].'",';
	}
	foreach my $h (@{$self->{wList}} ){
		if ($current{$h}){
			$temp .= "$current{$h},";
		} else {
			$temp .= "0,";
		}
	}
	if ($doc_id{$last}){
		$self->{r_command} .= "$temp\n";
		$length .= "$current{length_c},$current{length_w},";
		++$nrow;
	}

	my $ncol = @{$self->{wList}} + 1;

	chop $self->{r_command};
	chop $self->{r_command};
	$self->{r_command} .= "), byrow=T,nrow=$nrow, ncol=$ncol)\n";


	chop $row_names;
	
	if ($self->{rownames}){
		if ($self->{midashi}){
			$self->{r_command} .= "row.names(d) <- c($row_names)\n";
		} else {
			$self->{r_command} .= "row.names(d) <- d[,1]\n";
		}
	}



	$self->{r_command} .= "d <- d[,-1]\n";

	$self->{r_command} .= "colnames(d) <- c(";
	foreach my $i (@{$self->{wList}}){
		my $t = $self->{wName}{$i};
		$t =~ s/"/ /g;
		$self->{r_command} .= "\"$t\",";
	}
	chop $self->{r_command};
	$self->{r_command} .= ")\n";

	#chop $length;
	#$length .= "), ncol=2, byrow=T)\n";
	#$length .= "colnames(doc_length_mtr) <- c(\"length_c\", \"length_w\")\n";
	#$self->{r_command} .= $length;

	return $self;
}


1;