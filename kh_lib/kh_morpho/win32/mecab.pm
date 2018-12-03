package kh_morpho::win32::mecab;
use base qw( kh_morpho::win32 );

use strict;
use utf8;

#---------------------#
#   MeCabの実行関係   #
#---------------------#

sub _run_morpho{
	my $self = shift;	
	my $path = $self->config->mecab_path;
	$path =~ s/\\/\//g;
	$path = $::config_obj->os_path($path);
	
	# init
	unless (-e $path){
		gui_errormsg->open(
			msg => kh_msg->get('error_config'),
			type => 'msg'
		);
		exit;
	}

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
	
	# Run MeCab (Win32)
	my $pos = rindex($path,"/bin/");
	$self->{dir} = substr($path,0,$pos);
	my $chasenrc = $self->{dir}."/etc/mecabrc";
	$self->{cmdline} = "mecab -Ochasen -p -r \"$chasenrc\" -o \"$self->{output_temp}\" \"$self->{target_temp}\"";
	#print "cmdline: $self->{cmdline}\n";
	
	require Win32::Process;
	my $ChasenObj;
	Win32::Process::Create(
		$ChasenObj,
		$::config_obj->os_path( $self->config->mecab_path ),
		$self->{cmdline},
		0,
		Win32::Process->CREATE_NO_WINDOW,
		$self->{dir}.'/bin',
	) || $self->Exec_Error("Wi32::Process can not start");
	$ChasenObj->Wait( Win32::Process->INFINITE )
		|| $self->Exec_Error("Wi32::Process can not wait");
	
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
	open(my $fhoo, ">:encoding(utf8)", $self->output)
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
