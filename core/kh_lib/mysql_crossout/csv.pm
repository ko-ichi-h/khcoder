package mysql_crossout::csv;
use base qw(mysql_crossout);
use strict;

sub finish{
	my $self = shift;
	
	use File::BOM;
	open (OUTF, '>:encoding(utf8):via(File::BOM)', $self->{file}) or 
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
	if ($self->{midashi}){
		$head .= 'id,name,length_c,length_w,';
	} else {
		$head .= 'id,length_c,length_w,';
	}
	
	foreach my $i (@{$self->{wList}}){
		$head .= kh_csv->value_conv($self->{wName}{$i}).',';
	}
	chop $head;
	#if ($::config_obj->os eq 'win32'){
	#	$head = Jcode->new($head)->sjis;
	#}
	
	if ($self->{for_R}) {
		$head = mysql_crossout::r_com->clean_up($head);
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
	
	open (F, '<:encoding(utf8)', "$self->{file_temp}") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$self->{file_temp}",
		);
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
	unlink("$self->{file_temp}");
}



1;