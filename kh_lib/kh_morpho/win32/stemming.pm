package kh_morpho::win32::stemming;
use strict;
use base qw( kh_morpho::win32 );

#---------------------#
#   MeCabの実行関係   #
#---------------------#

sub _run_morpho{
	my $self = shift;	

	if (-e $self->output){
		unlink $self->output or 
			gui_errormsg->open(
				thefile => $self->output,
				type => 'file'
			);
	}

	open (TRGT,$self->target) or 
		gui_errormsg->open(
			thefile => $self->target,
			type => 'file'
		);
	
	open (my $fh_out,'>',$self->output) or 
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);

	use Lingua::EN::Tagger;
	
	# Perlapp用にTaggerのデータを解凍
	unless (-e $Lingua::EN::Tagger::word_path){
		my $cwd = $::config_obj->cwd;
		$cwd = Jcode->new($cwd,'sjis')->euc;
		$cwd =~ tr/\\/\//;
		$cwd = Jcode->new($cwd,'euc')->sjis.'/';
		
		$Lingua::EN::Tagger::word_path
			= $cwd
			.PerlApp::extract_bound_file('Lingua/EN/Tagger/pos_words.hash');
		$Lingua::EN::Tagger::word_path =~ tr/config\\/config\//;
		$Lingua::EN::Tagger::tag_path
			= $cwd
			.PerlApp::extract_bound_file('Lingua/EN/Tagger/pos_tags.hash');
		$Lingua::EN::Tagger::tag_path =~ tr/config\\/config\//;
		$Lingua::EN::Tagger::lexpath
			= substr(
				$Lingua::EN::Tagger::word_path,
				0,
				length($Lingua::EN::Tagger::word_path) - 15
			);
		$Lingua::EN::Tagger::lexpath =~ tr/config\\/config\//;
		
		PerlApp::extract_bound_file('Lingua/EN/Tagger/tags.yml');
		PerlApp::extract_bound_file('Lingua/EN/Tagger/unknown.yml');
		PerlApp::extract_bound_file('Lingua/EN/Tagger/words.yml');
	}
	
	print "1: $Lingua::EN::Tagger::word_path\n";
	print "2: $Lingua::EN::Tagger::tag_path\n";
	print "3: $Lingua::EN::Tagger::lexpath\n";

	$self->{tagger} = new Lingua::EN::Tagger;
	print "ok 0\n";
	

	# 処理開始
	while ( <TRGT> ){
		chomp;
		my $t   = $_;
		#$t =~ tr/(?:\x81\x40)/ /; # SJISの全角スペースを半角に変換（Win32）
		
		# 見出し行
		if ($t =~ /^(<h[1-5]>)(.+)(<\/h[1-5]>)$/io){
			print $fh_out "$1\t$1\t$1\tタグ\n";
			$self->_tokenize_stem($2, $fh_out);
			print $fh_out "$3\t$3\t$3\tタグ\n";
		} else {
			while ( index($t,'<') > -1){
				my $pre = substr($t,0,index($t,'<'));
				my $cnt = substr(
					$t,
					index($t,'<'),
					index($t,'>') - index($t,'<') + 1
				);
				unless ( index($t,'>') > -1 ){
					gui_errormsg->open(
						msg => '山カッコ（<>）による正しくないマーキングがありました。',
						type => 'msg'
					);
					exit;
				}
				substr($t,0,index($t,'>') + 1) = '';
				
				$self->_sentence($pre, $fh_out);
				$self->_tag($cnt, $fh_out);
				
				#print "[[$pre << $cnt >> $t]]\n";
			}
			$self->_sentence($t, $fh_out);
		}
		print $fh_out "EOS\n";
	}
	close (TRGT);
	close ($fh_out);

	# 出力ファイルをSJISに変換（Win32）
	kh_jchar->to_sjis($self->output);


	return 1;
}

sub _tag{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;

	$t =~ tr/ /_/;
	print $fh "$t\t$t\t$t\tタグ\n";

}

sub _sentence{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;

	use Lingua::EN::Sentence qw(get_sentences);
	my $sentences = get_sentences($t);
	foreach my $i (@{$sentences}) {
		$self->_tokenize_stem($i, $fh);
		print $fh "。\t。\t。\tALL\tSP\n";
	}

	return 1;
}


sub _tokenize_stem{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;
	
	## Tokenize
	##my $tb = $t;
	#use ptb_tokenizer_en;
	#$t = ptb_tokenizer_en::Run($t);
	##my @words = split / /, $t;
	
	# POS Tagging
	$t =~ s/[Cc]annot/can not/go;
	my $t = $self->{tagger}->add_tags($t);
	
	my @words_raw = split / /, $t;
	my @words_hyoso;
	my @words_pos;
	foreach my $i (@words_raw){
		if ($i =~ /^<(.+)>(.+)<\/\1>$/o){
			push @words_pos,   $1;
			push @words_hyoso, $2;
		} else {
			warn("error in tagger? $i\n");
		}
	}
	
	# Stemming
	use Lingua::Stem::En;
	my $words_stem = Lingua::Stem::En::stem(
		{
			-words => \@words_hyoso,
			-locale => 'en',
		}
	);
	
	# Stemming結果のチェック
	my $n1 = @words_hyoso;
	my $n2 = @{$words_stem};
	unless ($n1 == $n2){
		print "t: $t\n";
		gui_errormsg->open(
			msg  => "Something wrong: porter stemmer's output",
			type => 'msg',
		);
		exit;
	}
	
	# Print
	my $n = 0;
	foreach my $i (@words_hyoso){
		unless (length($words_stem->[$n])){
			$words_stem->[$n] = $i;
		}
		print $fh "$i\t$i\t$words_stem->[$n]\tALL\t\t$words_pos[$n]\n";
		++$n;
	}
	
	return 1;
}

sub exec_error_mes{
	return "KH Coder Error!!\nPorter Stemmerによる処理に失敗しました。";
}


1;
