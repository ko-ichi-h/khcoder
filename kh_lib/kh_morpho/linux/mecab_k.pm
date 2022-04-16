package kh_morpho::linux::mecab_k;
use strict;
use utf8;
use base qw( kh_morpho::linux );

# kr
my @initial = ("ᄀ", "ᄁ", "ᄂ", "ᄃ", "ᄄ", "ᄅ", "ᄆ", "ᄇ", "ᄈ", "ᄉ", "ᄊ", "ᄋ",
			"ᄌ", "ᄍ", "ᄎ", "ᄏ", "ᄐ", "ᄑ", "ᄒ");
my @medial = ("ᅡ", "ᅢ", "ᅣ", "ᅤ", "ᅥ", "ᅦ", "ᅧ", "ᅨ", "ᅩ", "ᅪ", "ᅫ", "ᅬ",
		   "ᅭ", "ᅮ", "ᅯ", "ᅰ", "ᅱ", "ᅲ", "ᅳ", "ᅴ", "ᅵ", "");
my @final = ("", "ᆨ", "ᆩ", "ᆪ", "ᆫ", "ᆬ", "ᆭ", "ᆮ", "ᆯ", "ᆰ", "ᆱ", "ᆲ",
		  "ᆳ", "ᆴ", "ᆵ", "ᆶ", "ᆷ", "ᆸ", "ᆹ", "ᆺ", "ᆻ", "ᆼ", "ᆽ", "ᆾ",
		  "ᆿ", "ᇀ", "ᇁ", "ᇂ");

sub convert_main {
  my $char = shift(@_);
  my $int = int(unpack("U*", $char));
  $int = $int - 44032;
  my $init_ind = int($int/588);
  my $final_ind = $int % 28;
  my $med_ind = int(($int - ($init_ind * 588) - $final_ind) / 28);
  my $r = $initial[$init_ind] . $medial[$med_ind] . $final[$final_ind];
  return $r;
}

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
			if (length($pre)) {
				# delete the last space to avoid errors of MeCab
				my $spflg = 0;
				while ( substr( $pre, -1, 1 ) eq ' ' ) {
					$spflg = 1;
					substr( $pre, -1, 1 ) = '';
				}
				$pre =~ s/[\x{AC00}-\x{D7A3}]/convert_main($&)/ge;
				$l .= "$pre\n";
				$l .= "<<space>>\t*\n" if $spflg;
			}
			$l .= "$cnt\t*\n";
			substr($t,0,index($t,'>') + 1) = '';
		}
		if (length($t)) {
			# delete the last space to avoid errors of MeCab
			while ( substr( $t, -1, 1 ) eq ' ' ) {
				substr( $t, -1, 1 ) = '';
			}
			$t =~ s/[\x{AC00}-\x{D7A3}]/convert_main($&)/ge;
			$l .= "$t\n"
		}
		print $fhto "$l\n";
	}
	
	close ($fhti);
	close ($fhto);
	
	
	# Run MeCab
	my $dic_path = $self->config->han_dic_path;
	$dic_path =~ s/\\/\//g;
	$dic_path = $::config_obj->os_path($dic_path);
	
	my $rcpath = '';
	$rcpath = ' -r "'.$::config_obj->mecabrc_path.'"' if length($::config_obj->mecabrc_path);
	
	my $mecab_exe = 'mecab';
	if ($::config_obj->all_in_one_pack) {
		$mecab_exe = './deps/mecab/bin/mecab';
	}
	
	$self->{cmdline} = "$mecab_exe $rcpath -d \"$dic_path\" -p -Ochasen -o \"$self->{output_temp}\" \"$self->{target_temp}\""; # kr
	
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
		$_ =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
		chomp;
		
		# complement lacking elements
		if ($_ =~ /^\t([^\t]+)\t\t(.+)/ ) {
			$_ = "$1\t$1\t$1\t$2";
		}

		# patchim
		if ($_ =~ /.+?\t([ᆨᆩᆪᆫᆬᆭᆮᆯᆰᆱᆲᆳᆴᆵᆶᆷᆸᆹᆺᆻᆼᆽᆾᆿᇀᇁᇂ])/) {
			substr($_, 0 ,1) = $1;
		}

		# insert white spaces deleted in pre-processing
		if (index($_, '<<space>>') == 0 ) {
			$_ = " \t \t \t半角スペース\t\t";
		}

		# other white spaces
		if ($_ =~ /([^\t]+)\t ([^\t]+)\t([^\t]+)\t(.+)/ ) {
			my ($t1, $t2, $t3, $t4) = ($1, $2, $3, $4);
			if ($t1 =~ /^ (.+)$/) {
			  $t1 = $1;
			}
			if ($t3 =~ /^ (.+)$/) {
			  $t3 = $1;
			}
			$_ = "$t1\t$t2\t$t3\t$t4";
			chomp $_;
			$_ = " \t \t \t半角スペース\t\t\n$_";
		}

		# add sentence delimiter
		if ( index($_,'Symbol-ピリオド') > -1){
			$_ = "$_\n。\t。\t。\t文区切り\t\t";
		}

		# change POS name to "TAG" and final output
		if ($_ =~ /^<(.+?)>\t/o) {
			print $fhoo "<$1>\t<$1>\t<$1>\tTAG\t\t\n";
		} else {
			print $fhoo "$_\n";
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
