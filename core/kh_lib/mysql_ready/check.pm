package mysql_ready::check;
use strict;

# 前処理データの整合性テスト

sub do{
	my $self = shift;
	my @error;

	# number of cases
	my %cases = ();
	foreach my $i ("h1","h2","h3","h4","h5"){
		unless (
			mysql_exec->select(
				"select status from status where name = \'$i\'",1
			)->hundle->fetch->[0]
		){next;}
		
		my $num1 = mysql_exec->select(
			"SELECT num FROM genkei WHERE name = \'<$i>\'",
			1
		)->hundle;
		$num1 = $num1->[0] if $num1 = $num1->fetch;
		
		my $num2 = mysql_exec->select(
			"SELECT count(*) FROM $i",
			1
		)->hundle;
		$num2 = $num2->[0] if $num2 = $num2->fetch;
		
		unless ($num1 == $num2){
			push @error, $i;
		}
		$cases{$i} = $num1;
	}

	# variables
	my $vars = mysql_outvar->get_list;
	foreach my $i (@{$vars}){
		my $var = mysql_outvar::a_var->new( undef, $i->[2] );
		#print "$i->[2], ", $var->n, ", $cases{$var->tani}\n";
		unless ( $cases{$var->tani} == $var->n ){
			push @error, "variable $i->[2]";
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
		my $msg = kh_msg->get('error'); # 前処理データの整合性が失われました
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