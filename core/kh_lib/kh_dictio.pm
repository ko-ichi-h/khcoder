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
		return 0 unless -e $self->{words_mk_file};
		
		my $icode;
		if ($::project_obj->morpho_analyzer_lang eq 'jp') {
			$icode = kh_jchar->check_code2($self->{words_mk_file});
		} else {
			$icode = kh_jchar->check_code_en($self->{words_mk_file});
		}
		
		my @words;
		open (SOURCE, "<:encoding($icode)", $self->{words_mk_file}) or
			gui_errormsg->open(
				type => 'file',
				thefile => $self->{words_mk_file}
			)
		;
		while (<SOURCE>){
			s/\x0D\x0A|\x0D|\x0A/\n/g;
			chomp;
			next unless length($_);
			push @words, $_;
		}
		$self->{markwords_act}  = \@words;
	}

	return $self;
}

sub read_file_st{
	my $self = shift;

	if ( $self->{words_st_file_chk} ){
		return 0 unless -e $self->{words_st_file};
		
		my $icode;
		if ($::project_obj->morpho_analyzer_lang eq 'jp') {
			$icode = kh_jchar->check_code2($self->{words_st_file});
		} else {
			$icode = kh_jchar->check_code_en($self->{words_st_file});
		}

		my @words;
		open (SOURCE, "<:encoding($icode)", $self->{words_st_file}) or
			gui_errormsg->open(
				type => 'file',
				thefile => $self->{words_st_file}
			)
		;
		while (<SOURCE>){
			s/\x0D\x0A|\x0D|\x0A/\n/g;
			chomp;
			next unless length($_);
			push @words, $_;
		}
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
			$i =~ s/'/\\'/go;
			$sql1 .= "('$i'),";
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
			$i =~ s/'/\\'/go;
			$sql1 .= "('$i'),";
		}
		chop $sql1;
		mysql_exec->do($sql1,1);
	}
	
	if ( mysql_exec->table_exists("genkei") ){
		mysql_exec->do('UPDATE genkei SET nouse=0',1);
		if (eval (@{$self->{stopwords_act}})){
			foreach my $i (@{$self->{stopwords_act}}){
				mysql_exec->
					do("UPDATE genkei SET nouse=1 WHERE name=\'$i\'",1);
				mysql_exec->
					do("UPDATE genkei SET nouse=1 WHERE name=\'<$i>\'",1);
				#print "no use: $i\n";
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
	my $source = $::config_obj->os_path( $::project_obj->file_target   );
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


	if (
		   $::config_obj->c_or_j eq 'chasen'
		|| $::config_obj->c_or_j eq 'mecab'
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
	} else {
		$icode = kh_jchar->check_code_en($source);
		$ocode = 'utf8';
	}

	open (MARKED,">:encoding($ocode)", $dist) or 
		gui_errormsg->open(
			type => 'file',
			thefile => $dist
		);
	open (SOURCE, "<:encoding($icode)", $source) or
		gui_errormsg->open(
			type => 'file',
			thefile => $source
		);

	use Lingua::JA::Regular::Unicode qw(katakana_h2z);
	while (<SOURCE>){
		$_ =~ s/\x0D\x0A|\x0D|\x0A/\n/g; # 改行コード統一
		chomp;

		my $text = $_;

		# morpho_analyzer
		if (
			   $::config_obj->c_or_j eq 'chasen'
			|| $::config_obj->c_or_j eq 'mecab'
		){
			$text = katakana_h2z($text);
			$text =~ s/ /　/go;
			$text =~ s/\t/　/go;
			$text =~ s/\\/￥/go;
			$text =~ s/'/’/go;
			$text =~ s/"/”/go;
		} else {
			$text = $_;
			$text =~ s/\t/ /go;
			$text =~ s/\\/ /go;
		}
		
		while (1){
			my %temp = (); my $f = 0;                      # 位置を取得
			foreach my $i (@keywords){
				# 当該の行内に文字列$iが存在すれば位置をチェック
				if (index(lc $text, lc $i) > -1){
					$temp{$i} = index(lc $text, lc $i, -1);
					++$f;
				}
			}
			unless ($f){                                   # 存在しなければ中止
				last;
			}
			
			my %firstplaces = (); my $n = -1;              # 先頭チェック
			for my $i (sort {$temp{$a} <=> $temp{$b}} keys %temp){
				if ($n < 0){
					$n = $temp{$i};
				}
				elsif ($n != $temp{$i}){
					last;
				}
				$firstplaces{$i} = $priority{$i};
			}
			for my $i (                                    # 優先度チェック
				sort { $firstplaces{$a} <=> $firstplaces{$b} }
				keys %firstplaces
			){
				my $len = length ($i);                     # マーキング
				$len += $n;
				my $t = substr($text,0,$n);
				substr($text,0,$len) = '';
				print MARKED "$t<$i>";
				last;
			}
		}
		print MARKED "$text\n";
	}
	close (SOURCE);
	close (MARKED);
	
	return 1;
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
