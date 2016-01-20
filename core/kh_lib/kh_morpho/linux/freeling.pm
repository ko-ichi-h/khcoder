package kh_morpho::linux::freeling;
use base kh_morpho::linux;

use strict;
use Encode;
use utf8;

use Time::HiRes;

my $output_code = find_encoding('utf8');

sub _run_morpho{
	my $self = shift;
	bless $self, 'kh_morpho::linux::freeling';

	my $icode = kh_jchar->check_code_en($self->target,1);
	$self->{icode} = $icode;

	# Set ENV variable
	my $freeling_dir = $::config_obj->freeling_dir;          
	$freeling_dir = $::config_obj->os_path($freeling_dir);
	$::ENV{FREELINGSHARE} = $freeling_dir;
	
	# get ready to run FreeLing
	$self->{target_temp} = $self->target.'.tmp';
	$self->{output_temp} = $self->output.'.tmp';
	unlink $self->{target_temp} if -e $self->{target_temp};
	unlink $self->{output_temp} if -e $self->{output_temp};
	
	my $cmd_line =                                           # command line
		"analyzer --nodate --noquant --flush -f $freeling_dir/config/"
		.$::project_obj->morpho_analyzer_lang
		.'.cfg --server --port 50005'
		#."< \"$self->{target_temp}\" >\"$self->{output_temp}\"";
	;
	
	if ($::config_obj->all_in_one_pack){
		$cmd_line = "DYLD_FALLBACK_LIBRARY_PATH=\"$::ENV{DYLD_FALLBACK_LIBRARY_PATH}\" $cmd_line";
	}
	print "cmd-line: $cmd_line\n";
	
	require Proc::Killall;
	Proc::Killall::killall('KILL', 'freeling');
	
	require Proc::Background;
	my $process = Proc::Background->new($cmd_line)
		|| $self->Exec_Error("Process could not start");
	
	$cmd_line =                                           # command line
		"analyzer_client 50005 "
		."< \"$self->{target_temp}\" >\"$self->{output_temp}\"";
	;
	$self->{cmd_line}      = $cmd_line;

	# Wait for the server to starts
	my $file_temp = $::config_obj->file_temp;
	open(my $fh_tmp, '>', $file_temp) or
		gui_errormsg->open(
			thefile => $self->target,
			type => 'file'
		)
	;
	print $fh_tmp 'test';
	close $fh_tmp;
	
	for (my $n = 0; $n <= 120; ++$n){
		print "Trying ($n/120): ";
		my $return = `analyzer_client 50005 < $file_temp`;
		#print "Return: \"$return\"";
		if (
			length($return) > 5
			#and not $return =~ /Library not loaded/
		) {
			last;
		}
		Time::HiRes::sleep (0.5);
		if ($n == 120) {
			die("Could not start FreeLing server process!\n");
		}
	}
	unlink($file_temp);

	# Open files
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

	# When run with Perlapp, extract Lingua::Sentence files
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
		PerlApp::extract_bound_file(
			'auto/share/dist/Lingua-Sentence/nonbreaking_prefix.ru',
		);
	}

	require Lingua::Sentence;
	my $lang = $::project_obj->morpho_analyzer_lang;
	if ($lang eq 'ru') {
		$lang = 'Russian';
	}
	
	$self->{splitter} = Lingua::Sentence->new(
		$::project_obj->morpho_analyzer_lang
	);

	# 処理開始
	$self->{unrecognized_char} = 0;
	while ( <TRGT> ){
		my $t   = $_;
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
			
			$self->_fl_run($pre);
			$self->_fl_outer($cnt);
			
			#print "[[$pre << $cnt >> $t]]\n";
		}
		$self->_fl_store($t);
	}
	close (TRGT);
	$self->_fl_run();

	$process->die;
	Proc::Killall::killall('TERM', 'freeling');

	return 1;
}

sub _fl_outer{
	my $self = shift;
	my $t    = shift;

	open (OTPT,">>:encoding(utf8)",$self->output) or 
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);

	print OTPT "$t\t$t\t$t\tTAG\t\t\n";

	close (OTPT);
}

# Store the data for FreeLing
sub _fl_store{
	my $self = shift;
	my $t    = shift;
	
	return 1 unless length($t) > 0;
	
	$self->{store} .= $t;
	$self->{stlast} = $t;
	
	if ( length($self->{store}) > 1048576 ){
		$self->_fl_store_out;
	}

	return $self;
}

# Write data for FreeLing to a file
sub _fl_store_out{
	my $self = shift;

	return 1 unless defined($self->{store});
	return 1 unless length($self->{store}) > 0;

	my $icode = 'utf8';
	
	my $arg;
	if (-e $self->{target_temp}) {
		$arg = ">>:encoding($icode)";
	} else {
		$arg = ">:encoding($icode)";
	}
	
	open (TMPO, $arg, $self->{target_temp}) or
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		);

	$self->{store} =~ s/\n/\n>\n/g;    # add paragraph delimiter

	my $t = '';                        # add sentence delimiter
	foreach my $i (split /\n/, $self->{store}){
		if ($i eq '>') {
			$t .= ">\n";
		} else {
			my @sentences = $self->{splitter}->split_array($i);
			foreach my $h (@sentences){
				next unless length($h);
				$t .= "$h\n<\n";
			}
		}
	}
	
	print TMPO $t;
	close (TMPO);

	$self->{store} = '';
	return $self;
}


sub _fl_run{
	my $self = shift;
	my $t    = shift;

	$self->_fl_store($t) if length($t);
	$self->_fl_store_out;

	return 0 unless -e $self->{target_temp};

	# run freeling
	system( $self->{cmd_line} );
	
	unless (-e $self->{output_temp}){
		$self->Exec_Error("No output file");
	}
	
	# read and format the output of freeling
	my $out = '';
	my $lines = 0;
	open (OTEMP, "<:encoding(utf8)", $self->{output_temp}) or
		gui_errormsg->open(
			thefile => $self->{output_temp},
			type => 'file'
		);
	while( <OTEMP> ){
		chomp;

		next unless length($_);
		my @line = split / /, $_;
		
		if ($line[0] eq '>') {              # paragraph delimiter
			$out .= "EOS\n";
			next;
		}
		
		if ($line[0] eq '<') {              # sentence delimiter
			$out .= "。\t。\t。\tALL\tSP\n";
			next;
		}
		
		$out .= "$line[0]\t$line[0]\t$line[1]\t$line[2]\t\t$line[2]\n";
		++$lines;
	}
	close (OTEMP);
	
	# write the output to result file
	open (my $fh,'>>:encoding(utf8)',$self->output) or 
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);
	print $fh $out;
	close ($fh);
	
	# error check
	if ($lines == 0 && $t =~ /\S/o){
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
	
	# unlink files
	unlink $self->{output_temp} or
		gui_errormsg->open(
			thefile => $self->{output_temp}."\n$!",
			type => 'file'
		);
	unlink $self->{target_temp} or
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		);
		
	# check file status
	for ( my $n = 0; $n < 20; ++$n ){
		if ( not ( -e $self->{output_temp} ) and not ( -e $self->{target_temp} ) ){
			if ($n > 0) {
				print "unlink: it was necessary to wait $n loop(s)\n";
			}
			last;
		}
		if ($n == 19) {
			gui_errormsg->open(
				thefile => $self->{target_temp},
				type => 'file'
			);
		}
		Time::HiRes::sleep (0.5);
	}
	
	
	if ($lines == 0) {
		return 0;
	}
	
	return 1;
}

sub exec_error_mes{
	return 'Could not run FreeLing!';
}


1;
