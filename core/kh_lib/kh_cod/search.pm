package kh_cod::search;
use base qw(kh_cod);
use strict;

# 直接入力コードの読み込み
sub add_direct{
	my $self   = shift;
	my $direct = shift;
	
	# 既に追加されていた場合はいったん削除
	if ($self->{codes}[0]->name eq 'direct'){
		print "Delete old \'direct\'\n";
		shift @{$self->{codes}};
	}
	
	
	unshift @{$self->{codes}}, kh_cod::a_code->new('direct',$direct);
}

# 検索の実行
sub search{
	my $self = shift;
	my %args = @_;
	
	# 取りあえずコーディング
	foreach my $i (@{$args{selected}}){
		my $res_table = "ct_$args{tani}"."_code_$i";
		$self->{codes}[$i]->ready($args{tani}) or next;
		$self->{codes}[$i]->code($res_table) or next;
		if ($i->res_table){ push @{$self->{valid_codes}}, $i; }
	}
	
	# AND条件の時に、0コードが存在した場合はreturn
	if (
		   ( $args{method} eq 'and' )
		&& ( @{$self->{valid_codes}} < @{$args{selected}} )
	) {
		return undef;
	}
	
	

}



1;