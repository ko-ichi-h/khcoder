# 複合名詞のリストを作製するためのロジック

package mysql_hukugo;

use strict;

sub run_from_morpho{
	# 形態素解析
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
	
	# 最大長を取得
	my $max = mysql_exec->select(
		"SELECT max(length(genkei)) from rowdata_h"
		,1
	)->hundle;
	if (my $i = $max->fetch){
		$max = $i->[0];
		print "max: $max\n";
	} else {
		$max = 10;
	}
	
	# 変形
	mysql_exec->drop_table("hukugo");
	mysql_exec->do("
		CREATE TABLE hukugo (
			num int,
			name varchar($max)
		)
	",1);
	mysql_exec->do("
		INSERT INTO hukugo (num, name)
		SELECT count(*), genkei
		FROM rowdata_h
		WHERE hinshi = \'複合名詞\'
		GROUP BY genkei
	",1);
}


1;