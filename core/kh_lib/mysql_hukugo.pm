# 複合名詞のリストを作製するためのロジック

package mysql_hukugo;

use strict;
use Benchmark;

use kh_jchar;
use mysql_exec;
use gui_errormsg;

sub run_from_morpho{
	my $class = shift;
	my $target = shift;

	my $t0 = new Benchmark;

	# 形態素解析
	print "1. morpho\n";
	$::config_obj->use_hukugo(1);
	$::config_obj->save;
	kh_morpho->run;
	$::config_obj->use_hukugo(0);
	$::config_obj->save;
	
	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_euc($::project_obj->file_MorphoOut);
			my $ta2 = new Benchmark;
	}
	
	# 読み込み
	print "2. read\n";
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
	mysql_exec->do("LOAD DATA LOCAL INFILE $thefile INTO TABLE rowdata_h",1);
	
	# 中間テーブル作製
	mysql_exec->drop_table("rowdata_h2");
	mysql_exec->do("
		create table rowdata_h2 (
			genkei varchar(40) not null
		)
	",1);
	mysql_exec->do("
		insert into rowdata_h2
		select genkei
		from rowdata_h
		where
			    hinshi = \'複合名詞\'
			AND length(genkei) < 41
	",1);
	
	
	# 変形
	print "3. reform\n";
	mysql_exec->drop_table("hukugo");
	mysql_exec->do("
		CREATE TABLE hukugo (
			num int,
			name varchar(40)
		)
	",1);
	mysql_exec->do("
		INSERT INTO hukugo (num, name)
		SELECT count(*), genkei
		FROM rowdata_h2
		GROUP BY genkei
	",1);
	
	# 平均値を取得
	my $mean = mysql_exec->select(
		"select sum(num) / count(*)from hukugo",
		1
	)->hundle->fetch->[0];
	
	# 書き出し
	print "4. print out\n";
	open (F,">$target") or
		gui_errormsg->open(
			type => 'file',
			thefile => $target
		);
	print F "複合名詞,出現数\n";
	
	my $oh = mysql_exec->select(
		"SELECT name, num FROM hukugo WHERE num > $mean ORDER BY num DESC",
		1
	)->hundle;
	
	use kh_csv;
	while (my $i = $oh->fetch){
		print F kh_csv->value_conv($i->[0]).",$i->[1]\n";
	}
	
	close (F);
	
	kh_jchar->to_sjis($target);
	
	my $t1 = new Benchmark;
	print timestr(timediff($t1,$t0)),"\n";
}


1;