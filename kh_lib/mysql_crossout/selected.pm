package mysql_crossout::selected;

use base qw(mysql_crossout);
use strict;

use mysql_crossout::selected::r_com;



#------------------------------------#
#   出力する単語・品詞リストの作製   #

sub make_list{
	my $self = shift;

	my $sql = "
		SELECT genkei.id, genkei.name, hselection.khhinshi_id
		FROM   genkei, hselection
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			AND (
	";

	my $n = 0;
	foreach my $i ( @{$self->{words}} ){
		$sql .= "				";
		$sql .= "OR " if $n;
		$sql .= "genkei.id = $i\n";
		++$n;
	}
	$sql .= "			)\n";

	$sql .= "\t\t\t\tORDER BY khhinshi_id, genkei.num DESC, genkei.name\n";

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

	# 品詞リストの作製はひとまずスキップ…

	return $self;
}




1;