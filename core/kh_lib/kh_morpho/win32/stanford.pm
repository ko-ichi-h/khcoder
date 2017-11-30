package kh_morpho::win32::stanford;

use base qw(kh_morpho::win32);
use kh_morpho::win32::stanford::en;
use kh_morpho::win32::stanford::de;
use kh_morpho::win32::stanford::cn;

use strict;
use Net::Telnet ();

use Encode;
use utf8;

my $output_code = find_encoding('utf8');

#my $fh_db;

sub _run_morpho{
	require Lingua::Sentence;
	#require Text::Unidecode;

	my $self = shift;
	my $class = "kh_morpho::win32::stanford::".$::project_obj->morpho_analyzer_lang;
	bless $self, $class;

	my $icode = kh_jchar->check_code_en($self->target,1);
	$self->{icode} = $icode;

	# 中国語の場合には文・単語のセグメンテーションを事前に行なう
	$self->segment($icode);

	# Stanford POS Taggerのサーバーを起動
	require Win32::SearchPath;
	my $java_path = Win32::SearchPath::SearchPath('java');

	unless (-e $java_path && length($java_path)){
		gui_errormsg->open(
			msg => kh_msg->get('no_java'),
			type => 'msg'
		);
		exit;
	}

	my $p1 = $::config_obj->os_path( $::config_obj->stanf_jar_path );
	my $p2 = $::config_obj->os_path( $::config_obj->stanf_tagger_path );
	
	unless (
		   -e $p1
		&& -e $p2
	){
		gui_errormsg->open(
			msg => kh_msg->get('error_confg'),
			type => 'msg'
		);
		exit;
	}
	
	my $cmd_line  =
		 'java -mx300m  -cp "'
		.$p1
		.'" edu.stanford.nlp.tagger.maxent.MaxentTaggerServer -outputFormat xml -outputFormatOptions lemmatize -port 2020 -model "'
		.$p2
		.'"'
	;
	
	#print "\ncmd: $cmd_line\n";
	
	require Win32::Process;
	my $process;
	Win32::Process::Create(
		$process,
		$java_path,
		$cmd_line,
		0,
		Win32::Process->CREATE_NO_WINDOW,
		$::config_obj->cwd,
	) || $self->Exec_Error("Wi32::Process can not start");
	
	print "Starting server, pid: ", $process->GetProcessID(), ", Connecting.";

	# Stanford POS Taggerのクライアントを準備
	$self->{client} = undef;
	while (not $self->{client}){
		$self->{client} = new Net::Telnet(
			Host => '127.0.0.1',
			Port => 2020,
			Errmode => 'return',
		);
		sleep 1;
		print ".";
	}
	while ( not $self->{client}->open ){
		sleep 1;
		print ".";
	}
	print " ok. Tagging...";
	$self->{client}->close;
	#$self->{client}->errmode('die');

	# ファイルオープン
	if (-e $self->output){
		unlink $self->output or 
			gui_errormsg->open(
				thefile => $self->output,
				type => 'file'
			);
	}

	open (TRGT, "<:encoding($icode)", $self->target) or 
		gui_errormsg->open(
			thefile => $self->target,
			type => 'file'
		);
	
	open (my $fh_out,'>:encoding(utf8)',$self->output) or 
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);

	#open ($fh_db,'>:encoding(utf8)',$::project_obj->file_TempTXT) or 
	#	gui_errormsg->open(
	#		thefile => $self->output,
	#		type => 'file'
	#	);

	# Perlapp用にLingua::Sentenceのデータを解凍
	if(defined(&PerlApp::extract_bound_file)){
		PerlApp::extract_bound_file(
			'auto/share/dist/Lingua-Sentence/nonbreaking_prefix.ca',
		);
		PerlApp::extract_bound_file(
			'auto/share/dist/Lingua-Sentence/nonbreaking_prefix.de',
		);
		PerlApp::extract_bound_file(
			'auto/share/dist/Lingua-Sentence/nonbreaking_prefix.el',
		);
		PerlApp::extract_bound_file(
			'auto/share/dist/Lingua-Sentence/nonbreaking_prefix.en',
		);
		PerlApp::extract_bound_file(
			'auto/share/dist/Lingua-Sentence/nonbreaking_prefix.es',
		);
		PerlApp::extract_bound_file(
			'auto/share/dist/Lingua-Sentence/nonbreaking_prefix.fr',
		);
		PerlApp::extract_bound_file(
			'auto/share/dist/Lingua-Sentence/nonbreaking_prefix.it',
		);
		PerlApp::extract_bound_file(
			'auto/share/dist/Lingua-Sentence/nonbreaking_prefix.nl',
		);
		PerlApp::extract_bound_file(
			'auto/share/dist/Lingua-Sentence/nonbreaking_prefix.pt',
		);
	}

	$self->init;

	# 処理開始
	$self->{unrecognized_char} = 0;
	while ( <TRGT> ){
		chomp;
		my $t = $_;

		# データのクリーニング
		unless (length($t)){
			next;
		}
		$t =~ s/\\/\/_/go;
		$t =~ s/[[:cntrl:]]/ /go;
		
		# 見出し行
		if ($t =~ /^(<h[1-5]>)(.+)(<\/h[1-5]>)$/io){
			print $fh_out "$1\t$1\t$1\tTAG\t\tTAG\n";
			$self->_tokenize_stem($2, $fh_out);
			print $fh_out "$3\t$3\t$3\tTAG\t\tTAG\n";
			print $fh_out "EOS\n";
		} else {
			$self->_sentence($t, $fh_out);
		}
	}
	close (TRGT);
	close ($fh_out);

	#close ($fh_db);

	print " ok.\n";
	$process->Kill(1);

	return 1;
}

sub _tag{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;

	$t =~ tr/ /_/;
	#$t = Text::Unidecode::unidecode($t);
	
	print $fh "$t\t$t\t$t\tTAG\t\tTAG\n";

}

sub _sentence{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;
	
	unless (length($t)){
		#print "Empty!\n";
		return 1;
	}
	
	my @sentences = $self->{splitter}->split_array($t);
	
	foreach my $i (@sentences) {
		my $r = $self->_tokenize_stem($i, $fh);
		print $fh "。\t。\t。\tALL\tSP\n" if $r;
	}

	print $fh "EOS\n";
	return 1;
}


sub _tokenize_stem{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;
	
	my $r = 0;
	while ( index($t,'<') > -1){
		my $pre = substr($t,0,index($t,'<'));
		my $cnt = substr(
			$t,
			index($t,'<'),
			index($t,'>') - index($t,'<') + 1
		);
		unless ( index($t,'>') > -1 ){
			gui_errormsg->open(
				msg  => kh_msg->get('kh_morpho::mecab->illegal_bra'),
				type => 'msg'
			);
			exit;
		}
		substr($t,0,index($t,'>') + 1) = '';
		
		$r += $self->_run_tagger($pre, $fh);
		$self->_tag($cnt, $fh);
		
		#print "[[$pre]] [[$cnt]] [[$t]]\n";
	}
	$r += $self->_run_tagger($t, $fh);
	
	return $r;
}

sub _run_tagger{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;

	return 0 unless length($t);
	#print $fh_db "$t\n";

	# POS Taggerへ
	my $n = 0;
	while ( not $self->{client}->open ){
		++$n;
		sleep 1;
		print " .";
		die("Cannot connect to the Server!") if $n > 10;
	}
	
	$self->{client}->print( encode('utf8', $t) );
	my @lines = $self->{client}->getlines;
	$self->{client}->close;
	
	# 結果の書き出し
	$n = 0;
	foreach my $i (@lines){
		$i = decode('utf8', $i);
		
		#print $fh_db "$i\n";
		
		if ($i =~ /<word wid="[0-9]+" pos="(.*)" lemma="(.*)">(.*)<\/word>/){
			my $base  = $2;
			my $hyoso = $3;
			my $pos   = $1;

			# 基本形の前後に記号がついている場合は落とす
			if ($base =~ /^(\w+)\W+$/o){
				$base = $1;
			}
			elsif ($base =~ /^\W+(\w+)$/o){
				$base = $1;
			}
			
			# 出力する行を作成
			my $line = "$hyoso\t$hyoso\t$base\t$pos\t\t$pos\n";
			$line =~ s/\\/\/_/g;
			
			# 語が空白の場合はスキップ
			if ($line =~ /^\t/o){
				warn("dropped: $i\n");
				next;
			}
			$line =~ s/\t\tALL/\t\?\?\?\tALL/o;
			
			print $fh $line;
			++$n;
		}
		#else {
		#	warn("unexpected otput from Stanford-POS-Tagger!\n$i");
		#}
	}
	
	if ($n == 0 && $t =~ /\S/o){
		my $file = $::project_obj->file_dropped;
		
		unless ( $self->{unrecognized_char} ){
			gui_errormsg->open(
				msg =>
					 "Warning: Sentences that include unrecognized characters are dropped from the processing.\n"
					."Dropped sentences are recorded in this file:\n$file\n\n"
					."Click OK to continue.",
				type => 'msg'
			);
			$self->{unrecognized_char} = 1;
			unlink $file if -e $file;
		}
		
		warn("A sentence which includes unrecognized characters is dropped!\n");
		
		open(my $fh, '>>', $file)
			or gui_errormsg->open(
				thefile => $self->output,
				type => 'file'
			);
		;
		print $fh encode('utf8', $t)."\n";
		close $fh;
	}
	
	if ($n == 0) {
		return 0;
	}
	
	return 1;
}

sub segment{
	my $self = shift;
	return $self;
}

sub exec_error_mes{
	return kh_msg->get('error');
}


1;
