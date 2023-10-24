# 複合名詞のリストを作製するためのロジック

package mysql_nounphrases;

use strict;
use utf8;
use Benchmark;

use kh_jchar;
use mysql_exec;
use gui_errormsg;

my $debug = 1;

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
	$sql .= "FROM   noun_phrases\n";
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
		FROM noun_phrases
		ORDER BY num DESC, ".$::project_obj->mysql_sort('name')."
		LIMIT 500
	",1)->hundle;
	
	my @r = ();
	while (my $i = $h->fetch){
		push @r, [$i->[0], $i->[1]];
	}
	return \@r;
}

sub detect{
	if (
		(
			   ( $::config_obj->c_or_j eq 'stanford' )
			|| ( $::config_obj->c_or_j eq 'freeling' )
		)
		&& ( $::project_obj->morpho_analyzer_lang eq 'en' )
	){
		&_detect_ptb;
	}
	elsif (
		   ($::config_obj->c_or_j eq 'chasen')
		|| ($::config_obj->c_or_j eq 'mecab')
	){
		&_detect_ipadic;
	}
}

sub _detect_ipadic{
	# run morpho
	my $t0 = new Benchmark;
	print "01. Marking...\n" if $debug;
	my $source = $::config_obj->os_path( $::project_obj->file_target);
	my $dist   = $::config_obj->os_path( $::project_obj->file_m_target);
	unlink($dist);

	my $icode = kh_jchar->check_code2($source);
	my $ocode;
	if ($::config_obj->c_or_j eq 'mecab'){
		$ocode = 'utf8';
	} else {
		if ($::config_obj->os eq 'win32'){
			$ocode = 'cp932';
		} else {
			if (eval 'require Encode::EUCJPMS') {
				$ocode = 'eucJP-ms';
			} else {
				$ocode = 'euc-jp';
			}
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

	# noun phrase detection
	my $file_MorphoOut = $::config_obj->os_path( $::project_obj->file_MorphoOut );
	open (TAGGED,"<:encoding($ocode)", $file_MorphoOut) or
		gui_errormsg->open(
			type => 'file',
			thefile => $file_MorphoOut
		)
	;
	
	my %phrases = ();
	my $wc = 0;
	my $t  = '';
	while ( <TAGGED> ){
		chomp;
		my @c = split /\t/, $_;
		if (
			( substr($c[3],0,3) eq '名詞-' )
			|| ( $c[3] eq '未知語' )
			|| ( $c[3] eq '接頭詞-名詞接続' )
			|| ( $c[3] eq '記号-アルファベット' )
		){
			$t .= $c[0];
			++$wc;
		}
		else {
			if ($t) {
				if ($wc > 1) {
					++$phrases{$t};
				}
				$t = '';
				$wc = 0;
			}
		}
	}
	if ($t) {
		if ($wc > 1) {
			++$phrases{$t};
		}
	}

	# output
	&output(\%phrases);

	my $t1 = new Benchmark;
	print timestr(timediff($t1,$t0)),"\n" if $debug;
}


sub _detect_ptb{
	# run pos tagger
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
		$_ =~ s/\x0D\x0A|\x0D|\x0A/\n/g; # new-line codes
		chomp;
		print MARKED "$_\n";
	}
	close (SOURCE);
	close (MARKED);
	
	print "02. POS Tagger...\n" if $debug;
	kh_morpho->run;
	
	# noun phrase detection
	my $file_MorphoOut = $::config_obj->os_path( $::project_obj->file_MorphoOut );
	open (TAGGED,"<:encoding(utf8)", $file_MorphoOut) or
		gui_errormsg->open(
			type => 'file',
			thefile => $file_MorphoOut
		)
	;
	my %phrases = ();
	my $nn = 0;
	my $t  = '';
	my $wc = 0;
	while ( <TAGGED> ){
		chomp;
		my @c = split /\t/, $_;
		
		if ( substr($c[3],0,2) eq 'NN' ){
			$t .= ' ' if length($t);
			$t .= $c[0];
			$nn = 1;
			++$wc;
		}
		elsif ($c[3] eq 'JJ'){
			$t .= ' ' if length($t);
			$t .= $c[0];
			++$wc;
		}
		elsif ( ($c[0] =~ /^of$/io) && (length($t)) ){   # pick "of" when collecting
			$t .= " $c[0]";
			++$wc;
		}
		elsif ( ($c[3] eq 'POS') && (length($t)) ){      # pick 's when collecting
			$t .= " $c[0]";
			++$wc;
		}
		elsif ( ($c[3] eq 'VBN') && (length($t) == 0) ){ # pick VBN at the beginning
			$t .= $c[0];
			++$wc;
		}
		else {
			if ($t) {
				if ($t =~ / of$/io) {           # delete the last " of"
					substr($t, -3, 3) = '';
					--$wc;
				}
				if (($nn == 1) && ($wc > 1)) {  # noun exists & more than ONE word
					$t = lc($t);
					++$phrases{$t};
				}
				$t = '';
				$nn = 0;
				$wc = 0;
			}
		}
	}
	if ($t) {
		if ($t =~ / of$/io) {
			substr($t, -3, 3) = '';
			--$wc;
		}
		if (($nn == 1) && ($wc > 1)) {
			$t = lc($t);
			++$phrases{$t};
		}
	}

	# output
	&output(\%phrases);

	my $t1 = new Benchmark;
	print timestr(timediff($t1,$t0)),"\n" if $debug;
}

sub output{
	my $phrases = shift;
	
	my $target = $::project_obj->file_NounPhrases;
	use Excel::Writer::XLSX;
	my $workbook  = Excel::Writer::XLSX->new($target);
	my $worksheet = $workbook->add_worksheet('Sheet1',1);
	$worksheet->hide_gridlines(1);
	
	my $format_n = $workbook->add_format(         # numbers
		num_format => '0',
		size       => 11,
		#font       => $font,
		align      => 'right',
	);
	my $format_c = $workbook->add_format(         # words
		#font       => $font,
		size       => 11,
		align      => 'left',
		num_format => '@'
	);

	$worksheet->write_string(                     # the first line
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

	mysql_exec->drop_table("noun_phrases");
	mysql_exec->do("
		CREATE TABLE noun_phrases (
			name varchar(255),
			num int
		)
	",1);

	my $row = 1;
	foreach my $i (sort { $phrases->{$b} <=> $phrases->{$a} } keys %{$phrases} ) {

		$worksheet->write_string(
			$row,
			0,
			$i,
			$format_c
		);
		$worksheet->write_number(
			$row,
			1,
			$phrases->{$i},
			$format_n
		);
		++$row;
		
		my $q = mysql_exec->quote($i);
		mysql_exec->do("
			INSERT INTO noun_phrases (name, num)
			VALUES ($q, $phrases->{$i})
		");
	}
	print "\n";

	$worksheet->freeze_panes(1, 0);
	$workbook->close;
}


1;