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
	
	my $self;
	$self->{stopwords}  = \@stop;
	$self->{markwords}  = \@mark;
	$self->{hinshilist} = \@hinshi;
	$self->{usethis}    = \%selection;
	bless $self, $class;
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
		if (eval (@{$self->words_st})){
			foreach my $i (@{$self->words_st}){
				mysql_exec->
					do("UPDATE genkei SET nouse=1 WHERE name=\'$i\'",1);
			}
		}
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
	my $source = $::project_obj->file_target;
	my $dist   = $::project_obj->file_m_target;

#	unless (eval (@{$self->words_mk})){
#		unlink($dist) or die if -e $dist;
#		use File::Copy;
#		copy("$source","$dist") or die;
#		return undef;
#	}

	my @keywords;
	@keywords = @{$self->words_mk} if eval @{$self->words_mk};

	my %priority; my $n = 0;
	foreach my $i (@keywords){
		$priority{$i} = $n;
		++$n;
	}

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

		my $text = Jcode->new($_,$icode)->h2z->euc;
		$text =~ s/ /　/go;
		$text =~ s/\\/￥/go;
		$text =~ s/'/’/go;
		$text =~ s/"/”/go;
		while (1){
			my %temp = (); my $f = 0;                      # 位置を取得
			foreach my $i (@keywords){
				if (index($text,$i) > -1){
					my $pos = index($text,$i);
					my $str = substr($text,0,$pos);
					unless ($str =~ /\x8F$/ or $str =~ tr/\x8E\xA1-\xFE// % 2){
						$temp{$i} = $pos;
						++$f;
					}
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
	if ($::config_obj->os eq 'win32'){
		kh_jchar->to_sjis($dist);
	}
}

#--------------#
#   アクセサ   #
#--------------#
sub words_mk{
	my $self = shift;
	my $val  = shift;
	if (defined($val)){
		$self->{markwords} = $val;
	}
	return $self->{markwords};
}

sub words_st{
	my $self = shift;
	my $val  = shift;
	if (defined($val)){
		$self->{stopwords} = $val;
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
