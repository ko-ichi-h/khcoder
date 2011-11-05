package kh_morpho::linux::stanford;

use base qw(kh_morpho::linux);
use kh_morpho::linux::stanford::en;

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
	my $class = "kh_morpho::linux::stanford::".$::config_obj->stanford_lang;
	bless $self, $class;

	# Stanford POS Taggerのサーバーを起動
	my $p1 = $::config_obj->stanf_jar_path;
	my $p2 = $::config_obj->stanf_tagger_path;
	
	unless (-e $p1 && -e $p2){
		gui_errormsg->open(
			msg => kh_msg->get('error_confg'),
			type => 'msg'
		);
		exit;
	}
	
	my $cmd_line  =
		 'java  -mx300m  -cp "'
		.$::config_obj->stanf_jar_path
		.'" edu.stanford.nlp.tagger.maxent.MaxentTaggerServer -outputFormat xml -outputFormatOptions lemmatize -port 2020 -model "'
		.$::config_obj->stanf_tagger_path
		.'"';
	
	require Proc::Background;
	my $process = Proc::Background->new($cmd_line)
		|| $self->Exec_Error("Wi32::Process can not start");
	
	print "Starting server, pid: ", $process->pid(), ", Connecting.";

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
			print $fh_out $output_code->encode("$1\t$1\t$1\tタグ\n");
			$self->_tokenize_stem($2, $fh_out);
			print $fh_out $output_code->encode("$3\t$3\t$3\tタグ\n");
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
	$process->die;

	return 1;
}

sub _tag{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;

	$t =~ tr/ /_/;
	$t = Text::Unidecode::unidecode($t);
	
	print $fh $output_code->encode(
			"$t\t$t\t$t\tタグ\n"
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
	$self->{client}->print($t);
	my @lines = $self->{client}->getlines;
	$self->{client}->close;
	
	# 結果の書き出し
	$n = 0;
	foreach my $i (@lines){
		if ($i =~ /<word wid="[0-9]+" pos="(.*)" lemma="(.*)">(.*)<\/word>/){
			my $line = Text::Unidecode::unidecode(
				"$3\t$3\t$2\t$1\t\t$1\n"
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
