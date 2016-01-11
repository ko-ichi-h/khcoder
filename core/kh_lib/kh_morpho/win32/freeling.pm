package kh_morpho::win32::freeling;
use base kh_morpho::win32;

use strict;
use Encode;
use utf8;

my $output_code = find_encoding('utf8');

sub _run_morpho{
	my $self = shift;
	bless $self, 'kh_morpho::win32::freeling';

	my $icode = kh_jchar->check_code_en($self->target,1);
	$self->{icode} = $icode;

	
	# Set ENV variable
	my $freeling_dir = $::config_obj->freeling_dir;          
	$freeling_dir .= '\data';
	$freeling_dir =~ s/\//\\/g;
	$freeling_dir = $::config_obj->os_path($freeling_dir);
	$::ENV{FREELINGSHARE} = $freeling_dir;
	
	# get ready to run FreeLing
	$self->{target_temp} = $self->target.'.tmp';
	$self->{output_temp} = $self->output.'.tmp';
	unlink $self->{target_temp} if -e $self->{target_temp};
	unlink $self->{output_temp} if -e $self->{output_temp};
	
	my $freeling_path = $::config_obj->freeling_dir;         # path of *.exe
	$freeling_path .= '\bin\analyzer.exe';
	$freeling_path =~ s/\//\\/g;
	$freeling_path = $::config_obj->os_path($freeling_path);

	my $cmd_path;
	if (-e $ENV{'WINDIR'}.'\system32\cmd.exe'){
		$cmd_path = $ENV{'WINDIR'}.'\system32\cmd.exe';
		#print "cmd.exe: $cmd_path\n";
	} else {
		foreach my $i (split /;/, $ENV{'PATH'}){
			unless (
				   substr($i,length($i) - 1, 1) eq '\\'
				|| substr($i,length($i) - 1, 1) eq '/'
			) {
				$i .= '\\';
			}
			if (-e $i.'cmd.exe'){
				$cmd_path = $i.'cmd.exe';
				#print "cmd.exe: found at $cmd_path\n";
				last;
			}
		}
	}
	die("Error: could not find cmd.exe") unless -e $cmd_path;
	
	my $cmd_line =                                           # command line
		$cmd_path 
		#." /C set FREELINGSHARE=\"$freeling_dir\" & $freeling_path"
		." /C $freeling_path"
		." -f %FREELINGSHARE%\\config\\"
		.$::project_obj->morpho_analyzer_lang
		.'.cfg '
		."< \"$self->{target_temp}\" >\"$self->{output_temp}\"";
	;
	
	$self->{cmd_path}      = $cmd_path;
	$self->{cmd_line}      = $cmd_line;
	$self->{freeling_path} = $freeling_path;
	$self->{dir}           = $freeling_dir;


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

	require Lingua::Sentence;
	$self->{splitter} = Lingua::Sentence->new(
		$::project_obj->morpho_analyzer_lang
	);

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

	# write data to temp file
	open(my $tmpo, '>:encoding(utf8)', $self->{target_temp}) or
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		);
	print $tmpo $t;
	close $tmpo;
		
	# run freeling
	require Win32::Process;
	my $process;
	Win32::Process::Create(
		$process,
		$self->{cmd_path},
		$self->{cmd_line},
		0,
		#Win32::Process->CREATE_NO_WINDOW,
		Win32::Process->NORMAL_PRIORITY_CLASS,
		$self->{dir},
	) or $self->Exec_Error("Wi32::Process can not start");
	$process->Wait( Win32::Process->INFINITE )
		|| $self->Exec_Error("Wi32::Process can not wait");
	
	unless (-e $self->{output_temp}){
		$self->Exec_Error("No output file");
	}
	
	# read and format the output of freeling
	my $out = '';
	my $n = 0;
	open (OTEMP, "<:encoding(utf8)", $self->{output_temp}) or
		gui_errormsg->open(
			thefile => $self->{output_temp},
			type => 'file'
		);
	while( <OTEMP> ){
		chomp;
		next unless length($_);
		my @line = split / /, $_;
		$out .= "$line[0]\t$line[0]\t$line[1]\t$line[2]\t\t$line[2]\n";
		++$n;
	}
	
	# write the output to result file
	print $fh $out;
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
		
		open(my $fh, '>>:encoding(utf8)', $file)
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
