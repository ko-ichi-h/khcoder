package kh_morpho::win32::stanford;

use base qw(kh_morpho::win32);
use kh_morpho::win32::stanford::en;
use kh_morpho::win32::stanford::de;

use strict;
use Net::Telnet ();

use Encode;
use utf8;

my $output_code;
if ($::config_obj->os eq 'win32'){
	$output_code = find_encoding('cp932');
} else {
	$output_code = find_encoding('euc-jp');
}
my $sjis = find_encoding('cp932');


sub _run_morpho{
	require Lingua::Sentence;
	require Text::Unidecode;

	my $self = shift;	
	my $class = "kh_morpho::win32::stanford::".$::config_obj->stanford_lang;
	bless $self, $class;

	# Stanford POS Taggerのサーバーを起動
	require Win32::SearchPath;
	my $java_path = Win32::SearchPath::SearchPath('java');
	$java_path = $sjis->decode($java_path)
		unless utf8::is_utf8( $java_path );

	unless (-e $java_path && length($java_path)){
		gui_errormsg->open(
			msg => kh_msg->get('no_java'),
			type => 'msg'
		);
		exit;
	}

	my $p1 = $sjis->decode($::config_obj->stanf_jar_path)
		unless utf8::is_utf8( $::config_obj->stanf_jar_path );
	my $p2 = $sjis->decode($::config_obj->stanf_tagger_path)
		unless utf8::is_utf8( $::config_obj->stanf_tagger_path );
	
	unless (
		    -e $::config_obj->stanf_jar_path
		&& -e $::config_obj->stanf_tagger_path
	){
		gui_errormsg->open(
			msg => kh_msg->get('error_confg'),
			type => 'msg'
		);
		exit;
	}
	
	my $cmd_line  =
		 'java  -mx300m  -cp "'
		.$p1
		.'" edu.stanford.nlp.tagger.maxent.MaxentTaggerServer -outputFormat xml -outputFormatOptions lemmatize -port 2020 -model "'
		.$p2
		.'"'
	;
	
	#print "cmd: $cmd_line\n";
	
	require Win32::Process;
	my $process;
	Win32::Process::Create(
		$process,
		$sjis->encode($java_path),
		$sjis->encode($cmd_line),
		0,
		Win32::Process->CREATE_NO_WINDOW,
		$::config_obj->cwd,
	) || $self->Exec_Error("Wi32::Process can not start");
	
	print "Starting server, pid: ", $process->GetProcessID(), ", Connecting.";

	# Stanford POS Taggerのクライアントを準備
	$self->{client} = undef;
	while (not $self->{client}){
		$self->{client} = new Net::Telnet(
			Host => 'localhost',
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
	while ( <TRGT> ){
		chomp;
		my $t   = decode("latin1",$_);
		
		# 見出し行
		if ($t =~ /^(<h[1-5]>)(.+)(<\/h[1-5]>)$/io){
			print $fh_out $output_code->encode("$1\t$1\t$1\tTAG\n");
			$self->_tokenize_stem($2, $fh_out);
			print $fh_out $output_code->encode("$3\t$3\t$3\tTAG\n");
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
		print $fh_out $output_code->encode("EOS\n");
	}
	close (TRGT);
	close ($fh_out);

	print " ok.\n";
	$process->Kill(1);

	return 1;
}

sub _tag{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;

	$t =~ tr/ /_/;
	$t = Text::Unidecode::unidecode($t);
	
	print $fh $output_code->encode(
			"$t\t$t\t$t\tTAG\n"
	);

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
		$self->_tokenize_stem($i, $fh);
		print $fh $output_code->encode("。\t。\t。\tALL\tSP\n");
	}

	return 1;
}


sub _tokenize_stem{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;
	
	# POS Taggerへ
	my $n = 0;
	while ( not $self->{client}->open ){
		++$n;
		sleep 1;
		print " .";
		die("Cannot connect to the Server!") if $n > 10;
	}
	$self->{client}->print( $t );
	my @lines = $self->{client}->getlines;
	$self->{client}->close;
	
	# 結果の書き出し
	$n = 0;
	foreach my $i (@lines){
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
			my $line = Text::Unidecode::unidecode(
				"$hyoso\t$hyoso\t$base\t$pos\t\t$pos\n"
			);
			
			# Unidecodeによって空白になってしまった場合に対応
			if ($line =~ /^\t/o){
				$line = '???'.$line;
			}
			$line =~ s/\t\tALL/\t\?\?\?\tALL/o;
			
			print $fh $output_code->encode($line);
			++$n;
		}
	}
	
	if ($n == 0 && $t =~ /\S/o){
		gui_errormsg->open(
			msg => "t: $t\nFatal: Something wrong with the POS Tagger!\n",
			type => 'msg'
		);
		exit;
	}
	
	return 1;
}


sub exec_error_mes{
	return kh_msg->get('error');
}


1;
