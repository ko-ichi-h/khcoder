package mysql_hukugo_te::ptb;
use base qw(mysql_hukugo_te);

use strict;

my $debug = 0;

sub _run_from_morpho{
	use TermExtract::BrillsTagger;

	# POS Tagger起動
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
		$_ =~ s/\x0D\x0A|\x0D|\x0A/\n/g; # 改行コード統一
		chomp;
		print MARKED "$_\n";
	}
	close (SOURCE);
	close (MARKED);
	
	print "02. POS Tagger...\n" if $debug;
	kh_morpho->run;

	# TermExtract用の入力ファイルを作成
	my $file_input = $::config_obj->file_temp;
	open my $fh, '>', $file_input
		or gui_errormsg->open(
			type    => 'file',
			thefile => $file_input,
		)
	;
	my %is_alone = ();
	open (CHASEN,$::project_obj->file_MorphoOut) or 
			gui_errormsg->open(
				type    => 'file',
				thefile => $::project_obj->file_MorphoOut
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
	my $data_out = 
		 kh_msg->get('gui_window::use_te_g->h_hukugo')
		.','
		.kh_msg->get('gui_window::use_te_g->h_score')
		."\n"
	;
	$data_out = Encode::encode('shift-jis',$data_out);
	
	"複合語,スコア\n";

	mysql_exec->drop_table("hukugo_te");
	mysql_exec->do("
		CREATE TABLE hukugo_te (
			name varchar(255),
			num double
		)
	",1);

	foreach (@noun_list) {
		next unless $_->[0] =~ / /; # 単名詞はパス

		my $q = mysql_exec->quote($_->[0]);
		#print "$q ";

		$data_out .= kh_csv->value_conv($_->[0]).",$_->[1]\n";
		mysql_exec->do("
			INSERT INTO hukugo_te (name, num)
			VALUES ($q, $_->[1])
		");
	}
	print "\n";


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