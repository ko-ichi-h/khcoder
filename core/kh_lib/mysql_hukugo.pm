# 複合名詞のリストを作製するためのロジック

package mysql_hukugo;

use strict;
use utf8;
use Benchmark;

use kh_jchar;
use mysql_exec;
use gui_errormsg;

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
	$sql .= "FROM   hukugo\n";
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
	$sql .= "ORDER BY num DESC, ".$::project_obj->mysql_sort('name')."\n";
	$sql .= "LIMIT 500\n";
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
		FROM hukugo
		ORDER BY num DESC, ".$::project_obj->mysql_sort('name')."
		LIMIT 500
	",1)->hundle;
	
	my @r = ();
	while (my $i = $h->fetch){
		push @r, [$i->[0], $i->[1]];
	}
	return \@r;
}

sub run_from_morpho{
	my $class = shift;
	my $target = $::project_obj->file_HukugoList;

	my $t0 = new Benchmark;

	# 形態素解析
	#print "1. morpho\n";
	
	my $source = $::config_obj->os_path( $::project_obj->file_target);
	my $dist   = $::config_obj->os_path( $::project_obj->file_m_target);
	unlink($dist);

	my $icode = kh_jchar->check_code2($source);
	my $ocode;
	if ($::config_obj->os eq 'win32'){
		$ocode = 'cp932';
	} else {
		if (eval 'require Encode::EUCJPMS') {
			$ocode = 'eucJP-ms';
		} else {
			$ocode = 'euc-jp';
		}
	}

	open (MARKED,">:encoding($ocode)", $dist) or 
		gui_errormsg->open(
			type => 'file',
			thefile => $dist
		);
	open (SOURCE,"<:encoding($icode)", $source) or
		gui_errormsg->open(
			type => 'file',
			thefile => $source
		);
	use Lingua::JA::Regular::Unicode qw(katakana_h2z);
	while (<SOURCE>){
		chomp;
		my $text = katakana_h2z($_);
		$text =~ s/ /　/go;
		$text =~ s/\\/￥/go;
		$text =~ s/'/’/go;
		$text =~ s/"/”/go;
		print MARKED "$text\n";
	}
	close (SOURCE);
	close (MARKED);
	#kh_jchar->to_sjis($dist) if $::config_obj->os eq 'win32';
	
	$::config_obj->use_hukugo(1);
	$::config_obj->save;
	kh_morpho->run;
	$::config_obj->use_hukugo(0);
	$::config_obj->save;

	my $mcode = '';
	if ($::config_obj->os eq 'win32') {
		$mcode = 'sjis';
	} else {
		$mcode = 'ujis'
	}
	
	# 読み込み
	#print "2. read\n";
	mysql_exec->drop_table("rowdata_h");
	mysql_exec->do("create table rowdata_h
		(
			hyoso varchar(255) not null,
			yomi varchar(255) not null,
			genkei varchar(255) not null,
			hinshi varchar(255) not null,
			katuyogata varchar(255) not null,
			katuyo varchar(255) not null,
			id int auto_increment primary key not null
		)
	",1);
	my $thefile = "'".$::project_obj->file_MorphoOut."'";
	$thefile =~ tr/\\/\//;
	mysql_exec->do("LOAD DATA LOCAL INFILE $thefile INTO TABLE rowdata_h CHARACTER SET $mcode",1);
	
	# 中間テーブル作製
	mysql_exec->drop_table("rowdata_h2");
	mysql_exec->do("
		create table rowdata_h2 (
			genkei varchar(255) not null
		)
	",1);
	mysql_exec->do("
		insert into rowdata_h2
		select genkei
		from rowdata_h
		where
			    hinshi = \'複合名詞\'
	",1);
	
	# 書き出し
	#print "4. print out\n";
	mysql_exec->drop_table("hukugo");
	mysql_exec->do("
		CREATE TABLE hukugo (
			name varchar(255),
			num int
		)
	",1);

	use Excel::Writer::XLSX;
	my $workbook  = Excel::Writer::XLSX->new($target);
	my $worksheet = $workbook->add_worksheet('Sheet1',1);
	$worksheet->hide_gridlines(1);
	
	#my $font = '';
	#if ($] > 5.008){
	#	$font = 'ＭＳ Ｐゴシック';
	#} else {
	#	$font = 'MS PGothic';
	#}
	#$workbook->{_formats}->[15]->set_properties( # cannot do this with Excel::Writer::XLSX
	#	font       => $font,
	#	size       => 11,
	#	valign     => 'vcenter',
	#	align      => 'center',
	#);
	my $format_n = $workbook->add_format(         # 数値
		num_format => '0',
		size       => 11,
		#font       => $font,
		align      => 'right',
	);
	my $format_c = $workbook->add_format(         # 文字列
		#font       => $font,
		size       => 11,
		align      => 'left',
		num_format => '@'
	);

	# the first line
	$worksheet->write_string(
		0,
		0,
		'複合語',
		$format_c
	);
	$worksheet->write_string(
		0,
		1,
		'出現数',
		$format_c
	);
	
	# body
	my $oh = mysql_exec->select("
		SELECT genkei, count(*) as hoge
		FROM rowdata_h2
		GROUP BY genkei
		ORDER BY hoge DESC
	",1)->hundle;
	
	use Lingua::JA::Regular::Unicode qw(alnum_z2h);
	my $row = 1;
	while (my $i = $oh->fetch){
		#print ".";
		#my $tmp = Jcode->new($i->[0], 'euc')->tr('０-９','0-9');
		my $tmp = alnum_z2h($i->[0]);
		next if $tmp =~ /^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+分)*(\d+秒)*$/o;   # 日付・時刻
		next if $tmp =~ /^\d+$/o;    # 数値のみ
		#print ",";
		
		$worksheet->write_string(
			$row,
			0,
			$i->[0],
			$format_c
		);
		$worksheet->write_number(
			$row,
			1,
			$i->[1],
			$format_n
		);
		
		mysql_exec->do("
			INSERT INTO hukugo (name, num) VALUES (\"$i->[0]\", $i->[1])
		",1);
		#print "!";
		++$row;
	}
	
	$worksheet->freeze_panes(1, 0);
	$workbook->close;
	
	my $t1 = new Benchmark;
	#print timestr(timediff($t1,$t0)),"\n";
}


1;