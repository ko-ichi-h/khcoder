# 上位見出しによる指定

package kh_cod::a_code::atom::heading;
use base qw(kh_cod::a_code::atom);
use strict;

sub expr{
	my $self = shift;
	if ($self->{valid}){
		return " $self->{tani}.$self->{heading_tani}"."_id = $self->{heading_id} ";
	} else {
		return 0;
	}
}

sub num_expr{
	return 1;
}

sub ready{
	my $self = shift;
	my $tani = shift;
	$self->{tani} = $tani;
	
	# ルール指定の解釈
	my ($var, $val);
	if ($self->raw =~ /<>見出し([1-5])\-\->(.+)$/o){
		$var = $1;
		$val = $2;
		$self->{heading_tani} = "h"."$var";
	} else {
		die("something wrong!");
	}
	
	# 集計単位が矛盾しないかどうか確認
	$self->{valid} = 1;
	if ($tani =~ /h([1-5])/i){
		if ($1 > $var){
			$self->{valid} = 0;
			return;
		}
	}
	
	# 見出しIDを取得
	my $temp = "h"."$var"."_id";
	$val = '\'<h'."$var".'>'."$val".'</h'."$var".'>\'';
	my $h = mysql_exec->select("
		SELECT $temp
		FROM   bun, bun_r
		WHERE
			    bun.id = bun_r.id
			AND bun_id = 0
			AND dan_id = 0
			AND rowtxt = $val
	",1)->hundle;
	unless ($val = $h->fetch){
			$self->{valid} = 0;
			return;
	}
	$self->{heading_id} = $val->[0];
	print "h_id: $self->{heading_id}\n";
	return $self;
}

sub tables{
	return 0;
}

sub pattern{
	return '^<>見出し[1-5]\-\->.+';
}
sub name{
	return 'heading';
}


1;