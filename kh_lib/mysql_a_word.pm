package mysql_a_word;
use strict;
use mysql_exec;

# 基本形IDリストの取得
sub new{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;

	my $sql = "
		SELECT genkei.id
		FROM genkei, hselection
		WHERE
			    genkei.khhinshi_id = hselection.khhinshi_id
			and hselection.ifuse = 1
			and genkei.name = \'$args{genkei}\'
	";
	if ($args{khhinshi}){
		$sql .= "			and hselection.name = \'$args{khhinshi}\'";
	}
	my $t = mysql_exec->select("$sql".1)->hundle;
	while (my $i = $t->fetch){
		push @{$self->{genkei_id_s}}, $i->[0];
	}
	return $self;
}

# 表層語IDリストを返す
sub hyoso_id_s{
	my $self = shift;
	
	my $sql = "SELECT hyoso.id ";
	$sql .= "FROM hyoso, genkei ";
	if ($self->{katuyo}){ $sql .= ",katuyo "; }
	$sql .= "WHERE genkei.id = hyoso.genkei_id ";
	if ($self->{katuyo}){$sql .= "AND hyoso.katuyo_id = katuyo.id ";}
	
	my $n = 0;
	foreach my $i (@{$self->{genkei_id_s}}){
		if ($n){$sql .= 'OR ';}
		$sql .= "genkei.id = $i ";
	}
	
}


1;