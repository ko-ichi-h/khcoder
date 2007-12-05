package mysql_getheader;
use strict;
use mysql_exec;

# 「章・節・段落ごとの集計」コマンドで利用
sub get{
	my $class = shift;
	my $tani  = shift;
	my $id    = shift;
	
	if ($tani eq 'dan' or $tani eq 'bun' or $tani eq ''){
		return '';
	}
	
	my @list = ('h1','h2','h3','h4','h5');
	
	my %id_info;
	my $sql;
	$sql .= "SELECT ";
	foreach my $i (@list){
		$sql .= "$i".'_id,';
		if ($i eq $tani){last;}
	}
	chop $sql;
	$sql .= "\nFROM $tani\n";
	$sql .= "WHERE id = $id";
	
	my $f = mysql_exec->select($sql,1)->hundle->fetch or return '';
	my $n = 0;
	foreach my $i (@{$f}){
		$id_info{$list[$n]} = $i;
		++$n;
	}
	
	$sql  = "SELECT hyoso.name\n";
	$sql .= "FROM hyosobun, hyoso\n";
	$sql .= "WHERE\n";
	$sql .= "    hyosobun.hyoso_id = hyoso.id\n";
	$sql .= "    AND bun_id = 0\n";
	$sql .= "    AND dan_id = 0\n";
	my $frag = 0; my $n = 5;
	foreach my $i (@list){
		if ($id_info{$i}){
			$sql .= "    AND $i"."_id = $id_info{$i}\n";
		} else {
			$sql .= "    AND $i"."_id = 0\n";
		}
	}
	$sql   .= "ORDER BY hyosobun.id";
	my @h = @{mysql_exec->select("$sql",1)->hundle->fetchall_arrayref};
	shift @h;
	pop   @h;
	my $h;
	foreach my $i (@h){
		$h .= $i->[0];
	}
	return Jcode->new($h)->sjis;
}

# 「部分テキストの取り出し」->「見出し文だけを取り出す」から利用
sub get_all{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	
	open (F,">$self->{file}")
		or gui_errormsg->open(
			type    => 'file',
			thefile => $self->{file}
		);
	
	my $sth = mysql_exec->select ("
		select *
		from bun_r, bun
		where
			bun_r.id = bun.id
			and bun.bun_id = 0
			and bun.dan_id = 0
		order by bun.id
	",1)->hundle;
	
	while (my $i = $sth->fetchrow_hashref){
		foreach my $h ("h5", "h4", "h3", "h2", "h1"){
			if ( $i->{"$h".'_id'} ){
				if ($self->{pic_head}{$h}){
					print F "$i->{rowtxt}\n";
				}
				last;
			}
		}
	}
	close (F);

	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_sjis($self->{file});
	}
}

sub get_selected{
	my $class = shift;
	my %args  = @_;
	my $self = \%args;
	
	unless ($self->{tani} =~ /h[1-5]/i){
		return 0;
	}
	
	my $sql = '';
	$sql .= "select rowtxt\n";
	$sql .= "from bun_r, bun\n";
	$sql .= "where\n";
	$sql .= "\tbun_r.id = bun.id\n";
	$sql .= "\tand bun.bun_id = 0\n";
	$sql .= "\tand bun.dan_id = 0\n";
	foreach my $i ("h5", "h4", "h3", "h2", "h1"){
		last if $self->{tani} eq $i;
		$sql .= "\tand bun.$i"."_id = 0\n";
	}
	$sql .= "\tand bun.$self->{tani}"."_id >= 1\n";
	$sql .= "order by bun.id";

	my $sth = mysql_exec->select ("$sql",1)->hundle;
	my @r = ();
	while (my $i = $sth->fetch){
		$i->[0] = $1 if $i->[0] =~ /^<h[1-5]>(.*)<\/h[1-5]>$/i;
		push @r, $i->[0];
	}
	
	# データチェック
	my $chk = mysql_exec->select(
		"select max(id) from $self->{tani}",
		1
	)->hundle;
	my $num1 = $chk->fetch->[0] or die("oops..");
	my $num2 = @r;
	unless ($num1 == $num2){
		die("oops... $num1, $num2");
	}
	
	return \@r;
}



1;