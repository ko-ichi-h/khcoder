package kh_hinshi;
use strict;

sub output{
	
	my $file_cha1 = $::project_obj->file_base.'_chasen1.csv';
	my $file_cha2 = $::project_obj->file_base.'_chasen2.csv';
	my $file_kh1 = $::project_obj->file_base.'_kh1.csv';
	my $file_kh2 = $::project_obj->file_base.'_kh2.csv';

	my $dun_num = mysql_exec->select("select count(*) from dan")
		->hundle->fetch->[0];

	#----------------------#
	#   品詞度数（茶筌）   #

	# 品詞リスト作成
	my @hinshi = @{&list};
	my %l_hinshi;
	my $h = mysql_exec->select("
		SELECT   id, name
		FROM     hinshi
		ORDER BY name
	")->hundle or die;
	while (my $i = $h->fetch){
		$l_hinshi{$i->[1]} = $i->[0];
	}

	# 品詞リストのチェック
	my $n = 0;
	foreach my $i (keys %l_hinshi){
		my $chk = 0;
		foreach my $ii (@hinshi){
			if ($i eq $ii){
				$chk = 1;
				last;
			}
		}
		if ( ($chk == 0) && ($i ne 'タグ') ){
			gui_errormsg->open(
				msg  => "error: $i",
				type => 'msg',
				icon => 'info',
			);
			return 0;
		}
	}

	# データ作成
	my $sql = "select\n";
	foreach my $i (@hinshi){
		if ($l_hinshi{$i}){
			$sql .= "\tcount(if(hinshi.id = $l_hinshi{$i},1,NULL)),\n";
		} else {
			$sql .= "\t0,\n";
		}
	}
	chop $sql; chop $sql;
	$sql .= "
		from hyosobun,hyoso,genkei,hinshi,khhinshi
		where
			hyosobun.hyoso_id = hyoso.id
			and hyoso.genkei_id = genkei.id
			and genkei.hinshi_id = hinshi.id
			and genkei.khhinshi_id = khhinshi.id
			and khhinshi.name != 'HTMLタグ'
			and dan_id > 0
		group by h1_id,h2_id,h3_id,h4_id,h5_id,dan_id
		order by hyosobun.id";
	$h = mysql_exec->select($sql)->hundle;

	# 書き出し
	open (OUT,">$file_cha1") or die;
	my $fstline;                                      # 一行目
	foreach my $i (@hinshi){
		$fstline .= Jcode->new("$i,")->sjis;
	}
	chop $fstline;
	print OUT "$fstline\n";
	while (my $i = $h->fetch){
		my $line;
		foreach my $ii (@{$i}){
			$line .= "$ii,";
		}
		chop $line;
		print OUT "$line\n";
	}
	close OUT;

	#--------------------------#
	#   品詞別リスト（茶筌）   #

	# データ作成
	$sql = "
		select dan.id, hyoso.name, hinshi.id
		from hyosobun,hyoso,genkei,hinshi,khhinshi,dan
		where
			hyosobun.hyoso_id = hyoso.id
			and hyoso.genkei_id = genkei.id
			and genkei.hinshi_id = hinshi.id
			and genkei.khhinshi_id = khhinshi.id
			and khhinshi.name != 'HTMLタグ'
			and hyosobun.h1_id = dan.h1_id
			and hyosobun.h2_id = dan.h2_id
			and hyosobun.h3_id = dan.h3_id
			and hyosobun.h4_id = dan.h4_id
			and hyosobun.h5_id = dan.h5_id
			and hyosobun.dan_id = dan.dan_id
		order by hyosobun.id";
	$h = mysql_exec->select($sql)->hundle;
	my $data;
	while (my $i = $h->fetch){
		$data->{$i->[0]}{$i->[2]} .= "$i->[1],"
	}

	# 書き出し

	open (OUT,">$file_cha2") or die;
	print OUT "$fstline\n";
	for (my $n = 1; $n <= $dun_num; ++$n){
		my $line;
		foreach my $i (@hinshi){
			my $cell = $data->{$n}{$l_hinshi{$i}};
			chop $cell;
			$cell = kh_csv->value_conv($cell);
			$cell = Jcode->new($cell)->sjis;
			$line .= "$cell,";
		}
		chop $line;
		print OUT "$line\n";
	}
	close (OUT);


	#--------------------#
	#   品詞度数（KH）   #

	# 品詞リスト作成
	my %hinshi;
	my $h = mysql_exec->select("
		SELECT   khhinshi_id, name
		FROM     hselection
		WHERE
		             name != 'HTMLタグ'
		         and name != 'タグ'
		ORDER BY khhinshi_id
	")->hundle or die;
	while (my $i = $h->fetch){
		$hinshi{$i->[0]} = $i->[1];
	}

	# SQL作成
	my $sql = "select\n";
	foreach my $i (sort {$a <=> $b} keys %hinshi){
		$sql .= "\tcount(if(khhinshi.id = $i,1,NULL)),\n";
	}
	chop $sql; chop $sql;
	$sql .= "
		from hyosobun,hyoso,genkei,hinshi,khhinshi
		where
			hyosobun.hyoso_id = hyoso.id
			and hyoso.genkei_id = genkei.id
			and genkei.hinshi_id = hinshi.id
			and genkei.khhinshi_id = khhinshi.id
			and khhinshi.name != 'HTMLタグ'
			and dan_id > 0
		group by h1_id,h2_id,h3_id,h4_id,h5_id,dan_id
		order by hyosobun.id";
	$h = mysql_exec->select($sql)->hundle;

	# 書き出し
	open (OUT,">$file_kh1") or die;
	my $fstline;                                      # 一行目
	foreach my $i (sort {$a <=> $b} keys %hinshi){
		$fstline .= Jcode->new("$hinshi{$i},")->sjis;
	}
	chop $fstline;
	print OUT "$fstline\n";
	while (my $i = $h->fetch){
		my $line;
		foreach my $ii (@{$i}){
			$line .= "$ii,";
		}
		chop $line;
		print OUT "$line\n";
	}
	close OUT;

	#------------------------#
	#   品詞別リスト（KH）   #

	# データ作成
	$sql = "
		select dan.id, genkei.name, khhinshi.id
		from hyosobun,hyoso,genkei,hinshi,khhinshi,dan
		where
			hyosobun.hyoso_id = hyoso.id
			and hyoso.genkei_id = genkei.id
			and genkei.hinshi_id = hinshi.id
			and genkei.khhinshi_id = khhinshi.id
			and khhinshi.name != 'HTMLタグ'
			and hyosobun.h1_id = dan.h1_id
			and hyosobun.h2_id = dan.h2_id
			and hyosobun.h3_id = dan.h3_id
			and hyosobun.h4_id = dan.h4_id
			and hyosobun.h5_id = dan.h5_id
			and hyosobun.dan_id = dan.dan_id
		order by hyosobun.id";
	$h = mysql_exec->select($sql)->hundle;
	$data = undef;
	while (my $i = $h->fetch){
		$data->{$i->[0]}{$i->[2]} .= "$i->[1] "
	}

	# 書き出し

	open (OUT,">$file_kh2") or die;
	print OUT "$fstline\n";
	for (my $n = 1; $n <= $dun_num; ++$n){
		my $line;
		foreach my $i (sort {$a <=> $b} keys %hinshi){
			my $cell = $data->{$n}{$i};
			chop $cell;
			$cell = kh_csv->value_conv($cell);
			$cell = Jcode->new($cell)->sjis;
			$line .= "$cell,";
		}
		chop $line;
		print OUT "$line\n";
	}
	close (OUT);



	gui_errormsg->open(
		msg  => '品詞情報を出力しました',
		type => 'msg',
		icon => 'info',
	);
}

# 茶筌の品詞リストを返す
sub list{
	my @list = (
		'名詞-一般',
		'名詞-固有名詞-一般',
		'名詞-固有名詞-人名-一般',
		'名詞-固有名詞-人名-姓',
		'名詞-固有名詞-人名-名',
		'名詞-固有名詞-組織',
		'名詞-固有名詞-地域-一般',
		'名詞-固有名詞-地域-国',
		'名詞-代名詞-一般',
		'名詞-代名詞-縮約',
		'名詞-副詞可能',
		'名詞-サ変接続',
		'名詞-形容動詞語幹',
		'名詞-数',
		'名詞-非自立-一般',
		'名詞-非自立-副詞可能',
		'名詞-非自立-助動詞語幹',
		'名詞-非自立-形容動詞語幹',
		'名詞-特殊-助動詞語幹',
		'名詞-接尾-一般',
		'名詞-接尾-人名',
		'名詞-接尾-地域',
		'名詞-接尾-サ変接続',
		'名詞-接尾-助動詞語幹',
		'名詞-接尾-形容動詞語幹',
		'名詞-接尾-副詞可能',
		'名詞-接尾-助数詞',
		'名詞-接尾-特殊',
		'名詞-接続詞的',
		'名詞-動詞非自立的',
		'名詞-引用文字列',
		'名詞-ナイ形容詞語幹',
		'接頭詞-名詞接続',
		'接頭詞-動詞接続',
		'接頭詞-形容詞接続',
		'接頭詞-数接続',
		'動詞-自立',
		'動詞-非自立',
		'動詞-接尾',
		'形容詞-自立',
		'形容詞-非自立',
		'形容詞-接尾',
		'副詞-一般',
		'副詞-助詞類接続',
		'連体詞',
		'接続詞',
		'助詞-格助詞-一般',
		'助詞-格助詞-引用',
		'助詞-格助詞-連語',
		'助詞-接続助詞',
		'助詞-係助詞',
		'助詞-副助詞',
		'助詞-間投助詞',
		'助詞-並立助詞',
		'助詞-終助詞',
		'助詞-副助詞／並立助詞／終助詞',
		'助詞-連体化',
		'助詞-副詞化',
		'助詞-特殊',
		'助動詞',
		'感動詞',
		'記号-一般',
		'記号-句点',
		'記号-読点',
		'記号-空白',
		'記号-アルファベット',
		'記号-括弧開',
		'記号-括弧閉',
		'その他-間投',
		'フィラー',
		'非言語音',
		'語断片',
		'未知語',
#		'複合名詞',
#		'タグ'
	);
	return \@list;
}

1;