# 複合語を検出・検索するためのロジック

package mysql_hukugo_te;

use strict;
use Benchmark;

use kh_jchar;
use mysql_exec;
use gui_errormsg;

my $debug = 0;


sub search{
	my $class = shift;
	my %args = @_;
	
	if (length($args{query}) == 0){
		my @r = @{&get_majority()};
		return \@r;
	}
	
	$args{query} = Jcode->new($args{query},'sjis')->euc;
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
	#print Jcode->new($sql)->sjis, "\n";
	
	my $h = mysql_exec->select($sql,1)->hundle;
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
		LIMIT 1000
	",1)->hundle;
	
	my @r = ();
	while (my $i = $h->fetch){
		push @r, [$i->[0], $i->[1]];
	}
	return \@r;
}

sub run_from_morpho{
	my $class = shift;
	#my $target = shift;

	# 形態素解析
	my $t0 = new Benchmark;
	print "01. Marking...\n" if $debug;
	my $source = $::project_obj->file_target;
	my $dist   = $::project_obj->file_m_target;
	unlink($dist);
	my $icode = kh_jchar->check_code($source);
	open (MARKED,">$dist") or 
		gui_errormsg->open(
			type => 'file',
			thefile => $dist
		);
	open (SOURCE,"$source") or
		gui_errormsg->open(
			type => 'file',
			thefile => $source
		);
	while (<SOURCE>){
		chomp;
		my $text = Jcode->new($_,$icode)->h2z->euc;
		$text =~ s/ /　/go;
		$text =~ s/\\/￥/go;
		$text =~ s/'/’/go;
		$text =~ s/"/”/go;
		print MARKED "$text\n";
	}
	close (SOURCE);
	close (MARKED);
	
	print "02. Converting Codes...\n" if $debug;
	kh_jchar->to_sjis($dist) if $::config_obj->os eq 'win32';
	
	print "03. Chasen...\n" if $debug;
	kh_morpho->run;

	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_euc($::project_obj->file_MorphoOut);
	}

	# フィルタリング用に単名詞のリストを作成
	print "04. Making the Filter...\n" if $debug;
	my %is_alone = ();
	open (CHASEN,$::project_obj->file_MorphoOut) or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $::project_obj->file_MorphoOut
			);
	while (<CHASEN>){
		$is_alone{(split /\t/, $_)[0]} = 1;
	}
	close (CHASEN);

	# TermExtractの実行
	print "05. TermExtract...\n" if $debug;
	use TermExtract::Chasen;
	my $te_obj = new TermExtract::Chasen;
	my @noun_list = $te_obj->get_imp_word($::project_obj->file_MorphoOut);

	# 出力
	print "06. Output...\n" if $debug;
	my $data_out = '';
	$data_out .= "キーワード,重要度\n";

	mysql_exec->drop_table("hukugo_te");
	mysql_exec->do("
		CREATE TABLE hukugo_te (
			name varchar(255),
			num double
		)
	",1);

	foreach (@noun_list) {
		next if $is_alone{$_->[0]};  # 単名詞
		
		my $tmp = Jcode->new($_->[0], 'euc')->tr('０-９','0-9'); 
		next if $tmp =~ /^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+分)*(\d+秒)*$/o;   # 日付・時刻
		next if $tmp =~ /^\d+$/o;    # 数値のみ

		$data_out .= kh_csv->value_conv($_->[0]).",$_->[1]\n";
		mysql_exec->do("
			INSERT INTO hukugo_te (name, num)
			VALUES (\"$_->[0]\", $_->[1])
		");
	}

	$data_out = Jcode->new($data_out, 'euc')->sjis
		if $::config_obj->os eq 'win32';

	my $target_csv = $::project_obj->file_HukugoListTE;
	open (OUT,">$target_csv") or
		gui_errormsg->open(
			type => 'file',
			thefile => $target_csv
		);
	print OUT $data_out;
	close (OUT);
	
	my $t1 = new Benchmark;
	print timestr(timediff($t1,$t0)),"\n" if $debug;

	return 1;
}


1;