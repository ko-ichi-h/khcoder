package kh_morpho::linux::mecab;
use strict;
use utf8;
use base qw( kh_morpho::linux );

#---------------------#
#   MeCabの実行関係   #
#---------------------#

sub _run_morpho{
	my $self = shift;	
	
	# init
	$self->{target_temp} = $self->target.'.tmp';
	$self->{output_temp} = $self->output.'.tmp';
	unlink $self->{target_temp} if -e $self->{target_temp};
	unlink $self->{output_temp} if -e $self->{output_temp};
	
	if (-e $self->output){
		unlink $self->output or 
			gui_errormsg->open(
				thefile => $self->output,
				type => 'file'
			);
	}
	
	# pre-processing for MeCab (OS independent)
	my $icode = kh_jchar->check_code2($self->target);
	open(my $fhti, "<:encoding($icode)", $self->target)
		or gui_errormsg->open(
			thefile => $self->target,
			type => 'file'
		)
	;
	open(my $fhto, ">:encoding($icode)", $self->{target_temp})
		or gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		)
	;
	
	while ( <$fhti> ){
		chomp;
		my $l = '';
		my $t = $_;
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
			$l .= "$pre\n" if length($pre);
			$l .= "$cnt\t*\n";
			substr($t,0,index($t,'>') + 1) = '';
		}
		$l .= "$t\n" if length($t);
		print $fhto "$l\n";
	}
	
	close ($fhti);
	close ($fhto);
	
	# Run MeCab (UNIX like)
	my $rcpath = '';
	$rcpath = ' -r "'.$::config_obj->mecabrc_path.'"' if length($::config_obj->mecabrc_path);
	
	my $mecab_exe = 'mecab';
	if ($::config_obj->all_in_one_pack) {
		$mecab_exe = './deps/mecab/bin/mecab';
	}
	
	$self->{cmdline} = "$mecab_exe -p $rcpath -Ochasen -o \"$self->{output_temp}\" \"$self->{target_temp}\"";
	
	if ($::config_obj->all_in_one_pack){
		$self->{cmdline} = "DYLD_FALLBACK_LIBRARY_PATH=\"$::ENV{DYLD_FALLBACK_LIBRARY_PATH}\" $self->{cmdline}";
	}
	print "command line: $self->{cmdline}\n";
	
		system "$self->{cmdline}";
	
	unless (-e $self->{output_temp}){
		$self->Exec_Error("No output file");
	}
	
	# post-processing for MeCab (OS independent)
	open(my $fhoi, "<:encoding($icode)", $self->{output_temp})
		or gui_errormsg->open(
			thefile => $self->{output_temp},
			type => 'file'
		)
	;
	open(my $fhoo, ">:encoding($icode)", $self->output)
		or gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		)
	;

	while (<$fhoi>) {
		if ($_ =~ /^<(.+?)>\t/o) {
			print $fhoo "<$1>\t<$1>\t<$1>\tタグ\t\t\n";
		} else {
			print $fhoo $_;
		}
	}

	close ($fhoi);
	close ($fhoo);

	return(1);
}

sub exec_error_mes{
	return kh_msg->get('error');
}


1;
