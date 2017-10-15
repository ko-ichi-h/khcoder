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
	
	print "03. Chasen...\n" if $debug;
	kh_morpho->run;

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

	mysql_exec->drop_table("hukugo_te");
	mysql_exec->do("
		CREATE TABLE hukugo_te (
			name varchar(255),
			num double
		)
	",1);

	my $target = $::project_obj->file_HukugoListTE;
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
		'スコア',
		$format_c
	);

	use Lingua::JA::Regular::Unicode qw(alnum_z2h);
	my $row = 1;
	foreach (@noun_list) {
		next if $is_alone{$_->[0]};  # 単名詞
		
		my $tmp = alnum_z2h($_->[0]);
		next if $tmp =~ /^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+分)*(\d+秒)*$/o;   # 日付・時刻
		next if $tmp =~ /^\d+$/o;    # 数値のみ

		$worksheet->write_string(
			$row,
			0,
			$_->[0],
			$format_c
		);
		$worksheet->write_number(
			$row,
			1,
			$_->[1],
			$format_n
		);
		++$row;
		
		my $quoted = mysql_exec->quote($_->[0]);
		mysql_exec->do("
			INSERT INTO hukugo_te (name, num)
			VALUES ($quoted, $_->[1])
		");
	}

	$worksheet->freeze_panes(1, 0);
	$workbook->close;

	my $t1 = new Benchmark;
	print timestr(timediff($t1,$t0)),"\n" if $debug;

	return 1;
}


1;