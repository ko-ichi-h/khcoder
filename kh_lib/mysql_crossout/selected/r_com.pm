package mysql_crossout::selected::r_com;
use base qw(mysql_crossout::selected);
use strict;

# 今のところ見出しの付与や、文書長の書き出しには未対応

sub run{
	my $self = shift;
	my $tani = $self->{tani};

	# データの取り出し1: 語のリスト
	my @word_ids = ();
	my @word_nms = ();
	my $h = mysql_exec->select("
		SELECT genkei.id, genkei.name
		FROM   genkei, tmp_words_4net
		WHERE
			genkei.id = tmp_words_4net.genkei_id
		ORDER BY genkei.khhinshi_id, genkei.num DESC, genkei.name
	",1)->hundle;
	
	while (my $i = $h->fetch){
		push @word_ids, $i->[0];
		push @word_nms, $i->[1];
	}

	# データの取り出し2: 文書-語
	my $d;
	if ($tani eq 'bun'){
		$h = mysql_exec->select("
			SELECT temp_word_ass.id,  tmp_words_4net.genkei_id
			FROM hyosobun, hyoso, tmp_words_4net, temp_word_ass
			WHERE
				hyosobun.hyoso_id = hyoso.id
				AND hyoso.genkei_id = tmp_words_4net.genkei_id
				AND hyosobun.bun_idt = temp_word_ass.id
		",1)->hundle;
	} else {
		$h = mysql_exec->select("
			SELECT temp_word_ass.id,  tmp_words_4net.genkei_id
			FROM hyosobun, hyoso, tmp_words_4net, ".$tani."_hb, temp_word_ass
			WHERE
				hyosobun.hyoso_id = hyoso.id
				AND hyoso.genkei_id = tmp_words_4net.genkei_id
				AND hyosobun.id = ".$tani."_hb.hyosobun_id
				AND ".$tani."_hb.tid = temp_word_ass.id
		",1)->hundle;
	}

	while (my $i = $h->fetch){
		++$d->{$i->[0]}{$i->[1]};
	}

	# R用のデータ作成
	my $nrow = 0;
	my $ncol = @word_ids;
	my $r_cmd = "d <- matrix( c(";
	foreach my $i ( sort { $a <=> $b } keys %{$d} ){
		foreach my $h (@word_ids){
			if ($d->{$i}{$h}){
				$r_cmd .= "1,";
			} else {
				$r_cmd .= "0,";
			}
		}
		$r_cmd .= "\n";
		++$nrow;
	}
	chop $r_cmd;
	chop $r_cmd;
	$r_cmd .= "), ncol=$nrow, nrow=$ncol)\n";
	
	$r_cmd .= "rownames(d) = c(";
	foreach my $i (@word_nms){
		$r_cmd .= "\"$i\",";
	}
	chop $r_cmd;
	$r_cmd .= ")\n\n";
	$r_cmd .= "# END: DATA\n\n";

	return $r_cmd;
}

1;