package mysql_hukugo_te::ptb;
use base qw(mysql_hukugo_te);

use strict;
use utf8;

my $debug = 0;

sub _run_from_morpho{
	use TermExtract::BrillsTagger;

	# POS Tagger起動
	my $t0 = new Benchmark;
	print "01. Marking...\n" if $debug;
	my $source = $::config_obj->os_path( $::project_obj->file_target);
	my $dist   = $::config_obj->os_path( $::project_obj->file_m_target);
	unlink($dist);
	my $icode = kh_jchar->check_code_en($source);
	open (MARKED,'>:encoding(utf8)', $dist) or 
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
		$_ =~ s/\x0D\x0A|\x0D|\x0A/\n/g; # 改行コード統一
		chomp;
		print MARKED "$_\n";
	}
	close (SOURCE);
	close (MARKED);
	
	print "02. POS Tagger...\n" if $debug;
	kh_morpho->run;

	# TermExtract用の入力ファイルを作成
	my $file_input = $::config_obj->os_path( $::config_obj->file_temp );
	open my $fh, '>:encoding(utf8)', $file_input
		or gui_errormsg->open(
			type    => 'file',
			thefile => $file_input,
		)
	;
	my %is_alone = ();
	my $file_MorphoOut = $::config_obj->os_path( $::project_obj->file_MorphoOut );
	open (CHASEN,'<:encoding(utf8)',$file_MorphoOut) or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $file_MorphoOut
			);
	my $cu = '';
	while (<CHASEN>){
		chomp;
		my @cu = split /\t/, $_;
		if ($cu[0] eq '。' || $cu[0] eq 'EOS'){
			if (length($cu)){
				print $fh "$cu\n";
				$cu = '';
			}
		} else {
			$cu .= ' ' if length($cu);
			$cu .= lc $cu[0];
			$cu .= "/$cu[3]";
		}
	}
	print $fh $cu if length($cu);
	close (CHASEN);
	close ($fh);

	# TermExtractの実行
	use TermExtract::BrillsTagger;
	my $data = new TermExtract::BrillsTagger;
	my @noun_list = $data->get_imp_word($file_input);
	#unlink($file_input);

	# 出力
	print "06. Output...\n" if $debug;

	my $target = $::project_obj->file_HukugoListTE;
	use Excel::Writer::XLSX;
	my $workbook  = Excel::Writer::XLSX->new($target);
	my $worksheet = $workbook->add_worksheet('Sheet1',1);
	$worksheet->hide_gridlines(1);

		my $font = '';
	if ($] > 5.008){
		$font = 'ＭＳ Ｐゴシック';
	} else {
		$font = 'MS PGothic';
	}
	#$workbook->{_formats}->[15]->set_properties( # cannot do this with Excel::Writer::XLSX
	#	font       => $font,
	#	size       => 11,
	#	valign     => 'vcenter',
	#	align      => 'center',
	#);
	my $format_n = $workbook->add_format(         # 数値
		num_format => '0',
		size       => 11,
		font       => $font,
		align      => 'right',
	);
	my $format_c = $workbook->add_format(         # 文字列
		font       => $font,
		size       => 11,
		align      => 'left',
		num_format => '@'
	);

	# the first line
	$worksheet->write_string(
		0,
		0,
		kh_msg->get('gui_window::use_te_g->h_hukugo'),
		$format_c
	);
	$worksheet->write_string(
		0,
		1,
		kh_msg->get('gui_window::use_te_g->h_score'),
		$format_c
	);

	mysql_exec->drop_table("hukugo_te");
	mysql_exec->do("
		CREATE TABLE hukugo_te (
			name varchar(255),
			num double
		)
	",1);

	my $row = 1;
	foreach (@noun_list) {
		next unless $_->[0] =~ / /; # 単名詞はパス

		#$data_out .= kh_csv->value_conv($_->[0]).",$_->[1]\n";
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
		
		my $q = mysql_exec->quote($_->[0]);
		mysql_exec->do("
			INSERT INTO hukugo_te (name, num)
			VALUES ($q, $_->[1])
		");
	}
	print "\n";

	$worksheet->freeze_panes(1, 0);
	$workbook->close;

	my $t1 = new Benchmark;
	print timestr(timediff($t1,$t0)),"\n" if $debug;

	return 1;
}


1;