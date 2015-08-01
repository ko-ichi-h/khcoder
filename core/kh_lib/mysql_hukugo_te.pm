# 複合語を検出・検索するためのロジック

package mysql_hukugo_te;

use strict;
use utf8;
use Benchmark;

use kh_jchar;
use mysql_exec;
use gui_errormsg;

use TermExtract::Chasen;
use TermExtract::Chasen_kh;

my $debug = 0;


sub search{
	my $class = shift;
	my %args = @_;
	
	if (length($args{query}) == 0){
		my @r = @{&get_majority()};
		return \@r;
	}
	
	#$args{query} = Jcode->new($args{query},'sjis')->euc;
	$args{query} =~ s/　/ /g;
	my @query = split(/ /, $args{query});
	
	
	my $sql = '';
	$sql .= "SELECT name, num\n";
	$sql .= "FROM   hukugo_te\n";
	$sql .= "WHERE\n";
	
	my $num = 0;
	foreach my $i (@query){
		next unless length($i);
		
		if ($num){
			$sql .= "\t$args{method} ";
		}
		
		if ($args{mode} eq 'p'){
			$sql .= "\tname LIKE ".'"%'.$i.'%"';
		}
		elsif ($args{mode} eq 'c'){
			$sql .= "\tname LIKE ".'"'.$i.'"';
		}
		elsif ($args{mode} eq 'z'){
			$sql .= "\tname LIKE ".'"'.$i.'%"';
		}
		elsif ($args{mode} eq 'k'){
			$sql .= "\tname LIKE ".'"%'.$i.'"';
		}
		else {
			die('illegal parameter!');
		}
		$sql .= "\n";
		++$num;
	}
	$sql .= "ORDER BY num DESC, name\n";
	$sql .= "LIMIT 500\n";
	#print Jcode->new($sql)->sjis, "\n";
	
	my $h = mysql_exec->select($sql)->hundle;
	my @r = ();
	while (my $i = $h->fetch){
		push @r, [$i->[0], $i->[1]];
	}
	return \@r;
}

# 検索文字列が指定されなかった場合
sub get_majority{
	my $h = mysql_exec->select("
		SELECT name, num
		FROM hukugo_te
		ORDER BY num DESC, name
		LIMIT 500
	")->hundle;
	
	my @r = ();
	while (my $i = $h->fetch){
		push @r, [$i->[0], $i->[1]];
	}
	return \@r;
}

sub run_from_morpho{
	my $class = shift;
	
	use mysql_hukugo_te::ipadic;
	use mysql_hukugo_te::ptb;
	
	if (
		   $::config_obj->c_or_j eq 'chasen'
		|| $::config_obj->c_or_j eq 'mecab'
	){
		$class .= '::ipadic';
	}
	elsif (
		   $::config_obj->c_or_j                eq 'stanford'
		&& $::project_obj->morpho_analyzer_lang eq 'en'
	) {
		$class .= '::ptb';
	}
	else{
		return 0;
	}
	
	my $self->{dummy} = 1;
	bless $self, $class;
	
	$self->_run_from_morpho;
}



1;