package mysql_ready::check;
use strict;

# 前処理データの整合性テスト

sub do{
	my $self = shift;
	my @error;

	# 各集計単位
	foreach my $i ("h1","h2","h3","h4","h5"){
		unless (
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){next;}
		
		my $num1 = mysql_exec->select(
			"SELECT num FROM genkei WHERE name like \'%$i%\'",
			1
		)->hundle->fetch->[0];
		
		my $num2 = mysql_exec->select(
			"SELECT count(*) FROM $i",
			1
		)->hundle->fetch->[0];
		
		unless ($num1 == $num2){
			push @error, $i;
		}
	}

	# genkei & hyosobun
	unless (
		mysql_exec->select("SELECT sum(num) FROM genkei",1)->hundle->fetch->[0]
		==
		mysql_exec->select("SELECT count(*) FROM hyosobun",1)->hundle->fetch->[0]
	){
		push @error, 'genkei-hyosobun';
	}
	
	# bun & bun_r 1
	unless (
		mysql_exec->select("SELECT count(*) FROM bun",1)->hundle->fetch->[0]
		==
		mysql_exec->select("SELECT count(*) FROM bun_r",1)->hundle->fetch->[0]
	){
		push @error, 'bun-bun_r1';
	}

	# bun & bun_r 2
	my $t = mysql_exec->select("
		SELECT bun_r.rowtxt
		FROM   bun, bun_r
		WHERE
			    bun.id = bun_r.id
			AND bun_id = 0
			AND dan_id = 0
	",1)->hundle;
	
	while (my $i = $t->fetch){
		unless ($i->[0] =~ /<[h|H][1-5]>.*<\/[h|H][1-5]>/o){
			push @error, 'bun-bun_r2'
		}
	}
	
	# 完了
	if (@error){
		my $msg = "前処理データの整合性が失われました。\n";
		my $n = 0;
		foreach my $i (@error){
			if ($n){$msg .= ', ';}
			$msg .= $i;
			++$n;
		}
		gui_errormsg->open(type => 'msg', msg => $msg);
		exit;
	} else {
		return 1;
	}
}


1;