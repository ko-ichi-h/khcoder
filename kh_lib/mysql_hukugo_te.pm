# 複合名詞のリストを作製するためのロジック

package mysql_hukugo_te;

use strict;
use Benchmark;

use kh_jchar;
use mysql_exec;
use gui_errormsg;

sub run_from_morpho{
	my $class = shift;
	#my $target = shift;

	# 形態素解析
	
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
		print MARKED "$text\n";
	}
	close (SOURCE);
	close (MARKED);
	kh_jchar->to_sjis($dist) if $::config_obj->os eq 'win32';
	
	kh_morpho->run;

	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_euc($::project_obj->file_MorphoOut);
			my $ta2 = new Benchmark;
	}

	# フィルタリング用に単名詞のリストを作成
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
	use TermExtract::Chasen;
	my $te_obj = new TermExtract::Chasen;
	my @noun_list = $te_obj->get_imp_word($::project_obj->file_MorphoOut);

	# 出力
	my $target_csv = $::project_obj->file_HukugoListTE;
	open (OUT,">$target_csv") or
		gui_errormsg->open(
			type => 'file',
			thefile => $target_csv
		);;
	print OUT "キーワード,重要度\n";

	mysql_exec->drop_table("hukugo_te");
	mysql_exec->do("
		CREATE TABLE hukugo_te (
			name varchar(255),
			num double
		)
	",1);

	foreach (@noun_list) {
		next if $is_alone{$_->[0]};  # 単名詞
		next if $_->[0] =~ /^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+分)*(\d+秒)*$/; # 日付・時刻
		my $tmp = Jcode->new($_->[0], 'euc')->tr('０-９','0-9'); # 数値のみ
		next if $tmp =~ /^\d+$/;

		print OUT
			kh_csv->value_conv($_->[0]),
			",$_->[1]\n"
		;
		mysql_exec->do("
			INSERT INTO hukugo_te (name, num)
			VALUES (\"$_->[0]\", $_->[1])
		");
	}
	close (OUT);
	kh_jchar->to_sjis("$target_csv") if $::config_obj->os eq 'win32';
	
	return 1;
}


1;