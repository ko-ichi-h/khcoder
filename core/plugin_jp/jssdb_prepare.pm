package jssdb_prepare;

sub plugin_config{
	return {
		name     => 'データ準備',
		menu_grp => 'JSSDB',
	};
}

use strict;

sub exec{

	# 基本形テーブル

	# 分析対象品詞のみ、5文書以上に出現している語のみに絞る
	# genkei_jss:
	#	genkei_id	id
	#	name		語
	#	df			文書数

	my $length_genkei = 255;                            # 文字数チェック
	$length_genkei = mysql_exec->select(
		"select max( length(name) ) from genkei",
		1
	)->hundle->fetch->[0];

	mysql_exec->drop_table("genkei_jss");               # テーブル作成
	mysql_exec->do("create table genkei_jss
		(
			genkei_id int primary key not null,
			df        int not null,
			name      varchar($length_genkei) not null
		)
	",1);

	mysql_exec->do("                                    # INSERT
		INSERT INTO genkei_jss (genkei_id, df, name)
		select genkei.id, f, genkei.name
		from genkei, khhinshi, df_dan
		where
			genkei.khhinshi_id = khhinshi.id
			AND genkei.id = df_dan.genkei_id
			AND genkei.nouse = 0
			AND khhinshi.name != \"名詞B\"
			AND khhinshi.name != \"動詞B\"
			AND khhinshi.name != \"形容詞B\"
			AND khhinshi.name != \"副詞B\"
			AND khhinshi.name != \"否定助動詞B\"
			AND khhinshi.name != \"形容詞（非自立）B\"
			AND khhinshi.name != \"その他\"
			AND f >= 5
	",1);

	mysql_exec->do("alter table genkei_jss add index index0 (genkei_id, df)",1);
	mysql_exec->do("alter table genkei_jss add index index1 (genkei_id, df, name)",1);

	# 基本形-段落テーブル

	# distinctをつけなくてもcount()で文書数がわかる
	# genkei_dan:
	#	genkei_id	基本形id
	#	dan_id		文書id

	mysql_exec->drop_table("genkei_dan");               # テーブル作成
	mysql_exec->do("create table genkei_dan
		(
			dan_id    int not null,
			genkei_id int not null
		)
	",1);

	mysql_exec->do("
		INSERT INTO genkei_dan (dan_id, genkei_id)
		select dan_hb.tid, genkei_jss.genkei_id
		from hyosobun, hyoso, genkei_jss, dan_hb
		where
			hyosobun.hyoso_id = hyoso.id
			AND hyoso.genkei_id = genkei_jss.genkei_id
			AND hyosobun.id = dan_hb.hyosobun_id
		GROUP BY dan_hb.tid, genkei_jss.genkei_id
	",1);

	mysql_exec->do("alter table genkei_dan add index index0 (dan_id, genkei_id)",1);
	mysql_exec->do("alter table genkei_dan add index index1 (genkei_id, dan_id)",1);


	# 段落-原文テーブル

	my $rows_per_once = 30000;
	my $data_per_1ins = 200;

	mysql_exec->drop_table("dan_r");
	mysql_exec->do("create table dan_r(id int auto_increment primary key not null, txt TEXT )",1);

	my ($c,$last,$values,$sql,$temp)
		=(0,1,'','INSERT into dan_r (txt) VALUES ','');

	my $id = 1; my $tc = 0;
	while (1){
		my $h = mysql_exec->select(
			jssdb_prepare->rowtxt_sql($id, $id + $rows_per_once),
			1,
		)->hundle;
		unless ($h->rows > 0){
			last;
		}
		$id += $rows_per_once;

		while (my $i = $h->fetch){
			++$tc;
			if ($last == $i->[0]){
				$temp .= $i->[1];
			} else {
				# エラー・チェック
				if ( length($temp) > 65535 ){
					gui_errormsg->open(type => 'msg',msg => "32,767文字を超える文がありました。\nKH Coderを終了します。");
					exit;
				}
				unless ($last + 1 == $i->[0]){
					gui_errormsg->open(type => 'msg',msg => "「bun_r」テーブル作成中にデータの整合性が失われました。\nKH Coderを終了します。");
					exit;
				}
				# エスケープ
				$temp =~ s/'/\\'/go;
				
				$values .= "(\'$temp\'),";
				$temp = $i->[1];
				$last = $i->[0];
				++$c;
			}
			
			if ($c == $data_per_1ins){
				chop $values;
				mysql_exec->do("$sql $values",1);
				$c = 0; $values = '';
			}
		}
		$h->finish;
	}
	
	if ($values or $temp){
		if ($temp){
			$temp =~ s/'/\\'/go;
			$values .= "(\'$temp\'),";
		}
		chop $values;
		mysql_exec->do("$sql $values",1);
	}

	my $chk1 = mysql_exec->select("select max(id) from dan_r")
		->hundle->fetch->[0];
	my $chk2 = mysql_exec->select("select max(id) from dan")
		->hundle->fetch->[0];
	print "dan_r, dan: $chk1, $chk2\n";



	print "OK!\n";
}

sub rowtxt_sql{
	my $self = shift;
	my $d1   = shift;
	my $d2   = shift;

	my $sql ="
		SELECT dan_hb.tid, hyoso.name
		FROM hyosobun, hyoso, dan_hb
		WHERE 
			    hyosobun.hyoso_id = hyoso.id
			AND hyosobun.id >= $d1
			AND hyosobun.id < $d2
			AND hyosobun.id = dan_hb.hyosobun_id
		ORDER BY hyosobun.id
	";

	#unless ($debug_print_frag){
	#	print "$sql\n";
	#	my $h = mysql_exec->select("explain\n$sql")->hundle;
	#	while (my $i = $h->fetch){
	#		foreach my $ii (@{$i}){
	#			print "$ii: ";
	#		}
	#		print "\n";
	#	}
	#	$debug_print_frag = 1;
	#}

	return $sql;
}



1;


__END__




	