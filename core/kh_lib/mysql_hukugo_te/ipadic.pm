package mysql_hukugo_te::ipadic;
use base qw(mysql_hukugo_te);

use strict;
use utf8;

my $debug = 0;

sub _run_from_morpho{
	#my $class = shift;
	#my $target = shift;

	# 形態素解析
	my $t0 = new Benchmark;
	print "01. Marking...\n" if $debug;
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
	while (<SOURCE>){
		chomp;
		my $text = $_;
		Encode::JP::H2Z::h2z(\$text);
		$text =~ s/ /　/go;
		$text =~ s/\\/￥/go;
		$text =~ s/'/’/go;
		$text =~ s/"/”/go;
		print MARKED "$text\n";
	}
	close (SOURCE);
	close (MARKED);
	
	#print "02. Converting Codes...\n" if $debug;
	#kh_jchar->to_sjis($dist) if $::config_obj->os eq 'win32';
	
	print "03. Chasen...\n" if $debug;
	kh_morpho->run;

	#if ($::config_obj->os eq 'win32'){
	#	kh_jchar->to_euc($::project_obj->file_MorphoOut);
	#}
	my $file_MorphoOut = $::config_obj->os_path($::project_obj->file_MorphoOut);

	# フィルタリング用に単名詞のリストを作成
	print "04. Making the Filter...\n" if $debug;
	my %is_alone = ();
	open (CHASEN, "<:encoding($ocode)", $file_MorphoOut) or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $file_MorphoOut
			);
	while (<CHASEN>){
		$is_alone{(split /\t/, $_)[0]} = 1;
	}
	close (CHASEN);

	# TermExtractの実行
	print "05. TermExtract...\n" if $debug;
	my $te_obj = new TermExtract::Chasen;
	my @noun_list = $te_obj->get_imp_word($file_MorphoOut);

	# 出力
	print "06. Output...\n" if $debug;
	my $data_out = 
		 kh_msg->get('gui_window::use_te_g->h_hukugo')
		.','
		.kh_msg->get('gui_window::use_te_g->h_score')
		."\n"
	;
	$data_out = Encode::encode('euc-jp',$data_out);


	mysql_exec->drop_table("hukugo_te");
	mysql_exec->do("
		CREATE TABLE hukugo_te (
			name varchar(255),
			num double
		)
	",1);

	foreach (@noun_list) {
		# 単名詞のスコアをprintしてチェック…
		#if ($is_alone{$_->[0]}){
		#	print Jcode->new("$_->[0], $_->[1]\n")->sjis
		#		if $_->[1] > 1;
		#}

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