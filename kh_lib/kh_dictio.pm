use utf8;

package kh_dictio;
use strict;
use mysql_exec;

#--------------------#
#   設定の読み込み   #
#--------------------#

sub readin{
	my $class = shift;
	my @stop;
	my @mark;
	my @hinshi;
	my %selection;

	my $self;

	my $st = mysql_exec->select('SELECT name FROM dstop',1)->hundle;
	while (my $i = $st->fetch){
		push @stop, $i->[0];
	}
	$st = mysql_exec->select('SELECT name FROM dmark',1)->hundle;
	while (my $i = $st->fetch){
		push @mark, $i->[0];
	}
	$st = mysql_exec->select('SELECT name, ifuse FROM hselection ORDER BY khhinshi_id')->hundle;
	while (my $i = $st->fetch){
		push @hinshi, $i->[0];
		$selection{$i->[0]} = $i->[1];
	}
	
	# 強制抽出・ファイル
	$st = mysql_exec->select('
		SELECT status
		FROM status
		WHERE name="words_mk_file"
	')->hundle;
	if (my $chk = $st->fetch){
		 $self->{words_mk_file_chk} = $chk->[0]
	} else {
		 $self->{words_mk_file_chk} = 0;
	}

	if ( $self->{words_mk_file_chk} ){
		my $file = mysql_exec->select('
			SELECT status
			FROM status_char
			WHERE name="words_mk_file"
		')->hundle->fetch;
		$file = $file->[0] if $file;
		
		$file = $::config_obj->os_path($file);
		#print "read: $file\n";
		$self->{words_mk_file} = $file;
	}

	# 使用しない語・ファイル
	$st = mysql_exec->select('
		SELECT status
		FROM status
		WHERE name="words_st_file"
	')->hundle;
	if (my $chk = $st->fetch){
		 $self->{words_st_file_chk} = $chk->[0]
	} else {
		 $self->{words_st_file_chk} = 0;
	}

	if ( $self->{words_st_file_chk} ){
		my $file = mysql_exec->select('
			SELECT status
			FROM status_char
			WHERE name="words_st_file"
		')->hundle->fetch;
		$file = $file->[0] if $file;
		$file = $::config_obj->os_path($file);
		$self->{words_st_file} = $file;
	}

	$self->{stopwords}     = \@stop;
	$self->{markwords}     = \@mark;
	$self->{stopwords_act} = \@stop;
	$self->{markwords_act} = \@mark;
	$self->{hinshilist}    = \@hinshi;
	$self->{usethis}       = \%selection;
	bless $self, $class;
	$self->read_file_mk;
	$self->read_file_st;
	return $self;
}

sub read_file_mk{
	my $self = shift;

	if ( $self->{words_mk_file_chk} ){
		unless (-e $self->{words_mk_file} ){
			gui_errormsg->open(
				type => 'msg',
				msg => 'cannot open file: '.$self->{words_mk_file}
			);
			return 0 ;
		}
		
		my $icode;
		if ($::project_obj->morpho_analyzer_lang eq 'jp') {
			$icode = kh_jchar->check_code2($self->{words_mk_file});
		} else {
			$icode = kh_jchar->check_code_en($self->{words_mk_file});
		}
		
		my @words;
		use File::BOM;
		File::BOM::open_bom (my $fh, $self->{words_mk_file}, ":encoding($icode)" );
		while (<$fh>){
			s/\x0D|\x0A//g;
			next unless length($_);
			push @words, $_;
		}
		close ($fh);
		$self->{markwords_act}  = \@words;
	}

	return $self;
}

sub read_file_st{
	my $self = shift;

	if ( $self->{words_st_file_chk} ){
		unless (-e $self->{words_st_file} ){
			gui_errormsg->open(
				type => 'msg',
				msg => 'cannot open file: '.$self->{words_st_file_chk}
			);
			return 0 ;
		}
		
		my $icode;
		if ($::project_obj->morpho_analyzer_lang eq 'jp') {
			$icode = kh_jchar->check_code2($self->{words_st_file});
		} else {
			$icode = kh_jchar->check_code_en($self->{words_st_file});
		}

		my @words;
		use File::BOM;
		File::BOM::open_bom (my $fh, $self->{words_st_file}, ":encoding($icode)" );
		while (<$fh>){
			s/\x0D|\x0A//g;
			next unless length($_);
			push @words, $_;
		}
		close ($fh);
		$self->{stopwords_act}  = \@words;
	}

	return $self;
}

#----------------#
#   設定を保存   #
#----------------#
sub save{
	my $self = shift;
	
	# 強制抽出
	mysql_exec->do('DROP TABLE dmark',1);
	mysql_exec->do('CREATE TABLE dmark(name varchar(255))',1);
	if (eval (@{$self->words_mk})){
		my $sql1 = 'INSERT INTO dmark (name) VALUES ';
		foreach my $i (@{$self->words_mk}){
			$i = mysql_exec->quote($i);
			$sql1 .= "($i),";
		}
		chop $sql1;
		mysql_exec->do($sql1,1);
	}
	
	# 強制抽出・ファイル
	mysql_exec->do("
		DELETE FROM status
		WHERE name = \"words_mk_file\"
	",1);
	mysql_exec->do("
		INSERT INTO status (name, status)
		VALUES (\"words_mk_file\", $self->{words_mk_file_chk})
	",1);
	
	if ( $self->{words_mk_file_chk} ){
		my $file = $self->{words_mk_file};
		$file = $::config_obj->uni_path($file);
		$file = mysql_exec->quote($file);

		mysql_exec->do("
			DELETE FROM status_char
			WHERE name = \"words_mk_file\"
		",1);
		mysql_exec->do("
			INSERT INTO status_char (name, status)
			VALUES (\"words_mk_file\", $file)
		",1);
	}
	
	# 使用しない語
	mysql_exec->do('DROP TABLE dstop',1);
	mysql_exec->do('CREATE TABLE dstop(name varchar(255))',1);
	if (eval (@{$self->words_st})){
		my $sql1 = 'INSERT INTO dstop (name) VALUES ';
		foreach my $i (@{$self->words_st}){
			my $t = mysql_exec->quote($i);
			$sql1 .= "($t),";
		}
		chop $sql1;
		mysql_exec->do($sql1,1);
	}
	
	if ( mysql_exec->table_exists("genkei") ){
		mysql_exec->do('UPDATE genkei SET nouse=0',1);
		if (eval (@{$self->{stopwords_act}})){
			foreach my $i (@{$self->{stopwords_act}}){
				#print "no use: $i\n";
				my $i_k = mysql_exec->quote("<$i>");
				$i = mysql_exec->quote($i);
				mysql_exec->
					do("UPDATE genkei SET nouse=1 WHERE name=$i",1);
				mysql_exec->
					do("UPDATE genkei SET nouse=1 WHERE name=$i_k",1);
			}
		}
		# 韓国語データの場合は半角スペースを無視する設定に
		if ($::project_obj->morpho_analyzer_lang eq 'kr') {
			mysql_exec->do(
				"update genkei set nouse = 1 where name = ' '",
				1
			);
		}
	}

	# 使用しない語・ファイル
	mysql_exec->do("
		DELETE FROM status
		WHERE name = \"words_st_file\"
	",1);
	mysql_exec->do("
		INSERT INTO status (name, status)
		VALUES (\"words_st_file\", $self->{words_st_file_chk})
	",1);

	if ( $self->{words_st_file_chk} ){
		my $file = $self->{words_st_file};
		$file = $::config_obj->uni_path($file);
		$file = mysql_exec->quote($file);

		mysql_exec->do("
			DELETE FROM status_char
			WHERE name = \"words_st_file\"
		",1);
		mysql_exec->do("
			INSERT INTO status_char (name, status)
			VALUES (\"words_st_file\", $file)
		",1);
	}

	# 品詞選択
	if (eval (@{$self->hinshi_list})){
		foreach my $i (@{$self->hinshi_list}){
			my $sql = 
				 "UPDATE hselection SET ifuse="
				.$self->ifuse_this($i)
				." WHERE name='$i'";
			mysql_exec->do($sql,1);
		}
	}

	# 複合名詞
	# print "hukugo: ".$self->ifuse_this('複合名詞')."\n";
	# $::config_obj->use_hukugo($self->ifuse_this('複合名詞'));
	# $::config_obj->save;

}

#------------------------#
#   データのマーキング   #
#------------------------#

sub mark{
	my $self = shift;
	my $source = $::config_obj->os_path( $::project_obj->file_target );
	my $dist   = $::project_obj->file_m_target;

#	unless (eval (@{$self->words_mk})){
#		unlink($dist) or die if -e $dist;
#		use File::Copy;
#		copy("$source","$dist") or die;
#		return undef;
#	}

	my @keywords;
	@keywords = @{$self->{markwords_act}} if eval @{$self->{markwords_act}};

	my %priority; my $n = 0;
	foreach my $i (@keywords){
		$priority{$i} = $n;
		++$n;
	}

	# 文字コードのチェック
	my $icode;
	my $ocode;

	# Japanese: chasen or mecab with non-unicode dic
	if (
		     $::config_obj->c_or_j eq 'chasen'
		|| ( $::config_obj->c_or_j eq 'mecab' &! $::config_obj->mecab_unicode )
	){
		$icode = kh_jchar->check_code2($source);
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
	# Japanese: mecab with unicode dic
	elsif ( $::config_obj->c_or_j eq 'mecab' && $::config_obj->mecab_unicode ) {
		$icode = kh_jchar->check_code2($source);
		$ocode = 'utf8';
	}
	# non-Japanese
	else {
		$icode = kh_jchar->check_code_en($source);
		$ocode = 'utf8';
	}

	open (MARKED,">:encoding($ocode)", $dist) or 
		gui_errormsg->open(
			type => 'file',
			thefile => $dist
		);

	use File::BOM;
	File::BOM::open_bom (SOURCE, $source, ":encoding($icode)" );

	use Lingua::JA::Regular::Unicode qw(katakana_h2z);
	#my %loc = (
	#	'jp' => 'cp932',
	#	'en' => 'cp1252',
	#	'cn' => 'cp936',
	#	'de' => 'cp1252',
	#	'es' => 'cp1252',
	#	'fr' => 'cp1252',
	#	'it' => 'cp1252',
	#	'nl' => 'cp1252',
	#	'pt' => 'cp1252',
	#	'kr' => 'cp949',
	#	'ca' => 'cp1252',
	#	'ru' => 'cp1251',
	#	'sl' => 'cp1251',
	#);
	my $lang = $::project_obj->morpho_analyzer_lang;
	#$lang = $loc{$lang};

	use Unicode::Normalize qw(compose);
	my $n_nfd = 0;
	while (<SOURCE>){
		$_ =~ s/\x0D\x0A|\x0D|\x0A/\n/g; # 改行コード統一
		chomp;
		
		next unless length($_); # skip empty lines

		my $text = $_;

		# morpho_analyzer
		if ( $lang eq 'jp' ){
			$text = katakana_h2z($text);
			$text =~ s/ /　/go;
			$text =~ s/\t/　/go;
			$text =~ s/\\/￥/go;
			$text =~ s/'/’/go;
			$text =~ s/"/”/go;
		}
		elsif ($lang eq 'cn'){
			$text = $_;
			$text =~ s/\t/ /go;
			$text =~ s/\\/ /go;
		} else {
			$text = $_;
			$text =~ s/\t/ /go;
			$text =~ s/\\/ /go;
			$text =~ s/。/./go;
		}
		
		# NFD to NFC
		unless ($text eq compose($text) ){
			$text = compose($text);
			++$n_nfd;
		}
		
		# Delete characters outside of BMP (Basic Multilingual Plane)
		$text = Encode::encode('UCS-2LE', $text, Encode::FB_DEFAULT);
		$text = Encode::decode('UCS-2LE', $text);
		$text =~ s/\x{fffd}/?/g;
		
		# Evade already marked part (for marking keywords for "force pickup")
		while ( index($text, '<') > -1) {
			my $pos_start = index($text, '<');
			my $pos_end   = index($text, '>', $pos_start);
			if ($pos_end < 0) {
				last;
			}

			my $pre = substr($text,0,$pos_start);
			my $cnt = substr(
				$text,
				$pos_start,
				$pos_end - $pos_start + 1
			);
			print MARKED mark_text($pre,\@keywords,\%priority);
			print MARKED $cnt;
			substr($text,0,$pos_end + 1) = '';
		}
		print MARKED mark_text($text,\@keywords,\%priority), "\n";

	}
	close (SOURCE);
	close (MARKED);
	print "NFD lines found: $n_nfd\n" if $n_nfd;
	
	return 1;
}

# Mark keywords for "force pickup"
sub mark_text{
	my $text_to_mark = shift;
	my $keywords = shift;
	my $priority = shift;
	
	my $out = '';
	
	while (1){
		my %temp = (); my $f = 0;                     # Find keywords
		foreach my $i (@{$keywords}){
			if (index(lc $text_to_mark, lc $i) > -1){
				$temp{$i} = index(lc $text_to_mark, lc $i, -1);
				++$f;
			}
		}
		unless ($f){                                  # Done if none
			last;
		}
		
		my @candidates = (); my $c;                   # Examin marking candidates
		for my $i (sort {$temp{$a} <=> $temp{$b}} keys %temp){
			# the 1st candidate
			if (not $c){
				$c = undef;
				$c->{start} = $temp{$i};
				$c->{end}   = $temp{$i} + length($i);
				$c->{text}  = $i;
				push @candidates, $c;
			}
			# 2nd and so on...
			elsif ($c->{end} > $temp{$i}){                       # overlapping effect range
				if ($priority->{$i} < $priority->{$c->{text}}) { # higher priority
					# new candidate
					push @candidates, $c;
					$c = undef;
					$c->{start} = $temp{$i};
					$c->{end}   = $temp{$i} + length($i);
					$c->{text}  = $i;
				}
			}
			else {
				last;
			}
		}

		while (1) {                                   # Revive candidates if they are ahead
			my @revived_candidates = ();              # of the effect range of the current
			my $n = 0;                                # primary candidate ($c)
			foreach my $i (@candidates){
				if ( $i->{end} <= $c->{start} ) {
					push @revived_candidates, $i;
					++$n;
				}
			}
			unless ($n){
				last;
			}
			$c = (
				sort { $priority->{$a->{text}} <=> $priority->{$b->{text}} }
				@revived_candidates
			)[0];
		}

		my $t = substr($text_to_mark,0,$c->{start});             # Perform Marking
		substr($text_to_mark,0,$c->{end}) = '';
		$out .= "$t<$c->{text}>";
	}
	$out .= "$text_to_mark";
	return $out;
}

#--------------#
#   アクセサ   #
#--------------#
sub words_mk{
	my $self = shift;
	my $val  = shift;
	if (defined($val)){
		$self->{markwords} = $val;
		$self->{markwords_act} = $val unless $self->{words_mk_file_chk};
	}
	return $self->{markwords};
}

sub words_mk_file{
	my $self = shift;
	my $val  = shift;
	if (defined($val)){
		$self->{words_mk_file} = $val;
		$self->read_file_mk;
	}
	return $self->{words_mk_file};
}

sub words_mk_file_chk{
	my $self = shift;
	my $val  = shift;
	if (defined($val)){
		$self->{words_mk_file_chk} = $val;
	}
	return $self->{words_mk_file_chk};
}

sub words_st_file{
	my $self = shift;
	my $val  = shift;
	if (defined($val)){
		$self->{words_st_file} = $val;
		$self->read_file_st;
	}
	return $self->{words_st_file};
}

sub words_st_file_chk{
	my $self = shift;
	my $val  = shift;
	if (defined($val)){
		$self->{words_st_file_chk} = $val;
	}
	return $self->{words_st_file_chk};
}

sub words_st{
	my $self = shift;
	my $val  = shift;
	if (defined($val)){
		$self->{stopwords}     = $val;
		$self->{stopwords_act} = $val unless $self->{words_st_file_chk};
	}
	return $self->{stopwords};
}
sub hinshi_list{
	my $self = shift;
	return $self->{hinshilist};
}
sub ifuse_this{
	my $self = shift;
	my $var = shift;
	my $val = shift;
	if (defined($val)){
		$self->{usethis}{$var} = $val;
	}
	return $self->{usethis}{$var};
}
1;
