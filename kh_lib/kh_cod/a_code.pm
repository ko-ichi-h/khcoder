package kh_cod::a_code;
use kh_cod::a_code::atom;
use mysql_exec;
use strict;

sub count{
	my $self = shift;
	my $tani = shift;
	unless ($self->{condition}){
		return 0;
	}
	unless ($self->tables){
		return 0;
	}
	
	my $sql = "SELECT count(*)\n";
	$sql .= "FROM $tani\n";
	foreach my $i (@{$self->tables}){
		$sql .= "\tLEFT JOIN $i ON $tani.id = $i.id\n";
	}
	$sql .= "WHERE\n";
	foreach my $i (@{$self->{condition}}){
		$sql .= "\t".$i->expr."\n";
	}
	# print "$sql";
	
	return mysql_exec->select($sql,1)->hundle->fetch->[0];
}

sub tables{
	my $self = shift;
	return $self->{tables};
}

sub clear_tmp{
	my $self = shift;
	if ($self->tables){
		foreach my $i (@{$self->tables}){
			mysql_exec->drop_table($i);
		}
	}
	return $self;
}

sub ready{
	my $self = shift;
	my $tani = shift;
	unless ($self->{condition}){
		return 0;
	}
	
	# ATOMごとのテーブルを作製
	my ($n0, $n1,@t,$unique_check) = (0,0); 
	foreach my $i (@{$self->{condition}}){
		$i->ready($tani);
		if ($i->tables){
			$n0 += @{$i->tables};
			if ($n0 > 25){
				++$n1; $n0 = 0;
			}
			$i->parent_table("ct_$tani"."_$n1");
			foreach my $h (@{$i->tables}){
				if ($unique_check->{$n1}{$h}){
					next;
				} else {
					push @{$t[$n1]}, $h;
					$unique_check->{$n1}{$h} = 1;
				}
			}
		}
	}
	
	# ATOMテーブルをまとめる
	my $n = 0;
	foreach my $i (@t){
		# テーブル作製
		mysql_exec->drop_table("ct_$tani"."_$n");
		my $sql =
			"CREATE TABLE ct_$tani"."_$n ( id int primary key not null,\n";
		foreach my $h (@{$i}){
			my $col = (split /\_/, $h)[2].(split /\_/, $h)[3];
			$sql .= "$col INT,"
		}
		chop $sql;
		$sql .= ') TYPE = HEAP ';
		mysql_exec->do($sql,1);
		push @{$self->{tables}}, "ct_$tani"."_$n";
		
		# INSERT
		$sql = '';
		$sql .= "INSERT INTO ct_$tani"."_$n\n(id,";
		foreach my $h (@{$i}){
			my $col = (split /\_/, $h)[2].(split /\_/, $h)[3];
			$sql .= "$col,";
		}
		chop $sql;
		$sql .= ")\n";
		$sql .= "SELECT $tani.id,";
		foreach my $h (@{$i}){
			$sql .= "$h.num,";
		}
		chop $sql;
		$sql .= "\n";
		$sql .= "FROM $tani \n";
		foreach my $h (@{$i}){
			$sql .= "\tLEFT JOIN $h ON $tani.id = $h.id\n"
		}
		$sql .= "WHERE ";
		my $nn = 0;
		foreach my $h (@{$i}){
			if ($nn){ $sql .= ' OR '; }
			$sql .= " $h.num ";
			++$nn;
		}
		mysql_exec->do($sql,1);
		
		++$n;
	}
}

sub new{
	my $self;
	my $class = shift;
	$self->{name} = shift;
	$self->{row_condition} = shift;
	
	my $condition = Jcode->new($self->{row_condition},'euc')->tr('　',' ');
	$condition =~ tr/\t\n/  /;
	my @temp = split / /, $condition;
	
	foreach my $i (@temp){
		unless ( length($i) ){next;}
		push @{$self->{condition}}, kh_cod::a_code::atom->new($i);
	}
	
	bless $self, $class;
	return $self;
}

sub name{
	my $self = shift;
	return $self->{name};
}




1;