package mysql_crossout::csv;
use base qw(mysql_crossout);
use strict;

sub finish{
	my $self = shift;
	
	open (OUTF,">$self->{file}") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $self->{file},
		);
	
	# ヘッダ行の作製
	my $head = ''; my @head;
	foreach my $i ('h1','h2','h3','h4','h5','dan','bun'){
		$head .= "$i,";
		push @head, $i;
		if ($self->{tani} eq $i){
			last;
		}
	}
	$head .= 'id,length_c,length_w,';
	foreach my $i (@{$self->{wList}}){
		$head .= "$self->{wName}{$i},";
	}
	chop $head;
	if ($::config_obj->os eq 'win32'){
		$head = Jcode->new($head)->sjis;
	}
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
	
	open (F,"temp.dat") or die;
	while (<F>){
		my $srow = $sth->fetchrow_hashref;
		my $head;
		foreach my $i (@head){
			$head .= $srow->{"$i"."_id"};
			$head .= ',';
		}
		print OUTF "$head"."$_";
	}
	close (F);
	close (OUTF);
	unlink('temp.dat');
}



1;