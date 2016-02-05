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

	# kr
	my $dic_path = $self->config->han_dic_path;
	$dic_path =~ s/\\/\//g;
	$dic_path = $::config_obj->os_path($dic_path);

	# 初期化
	$self->{store} = '';
	
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
	
	my $rcpath = '';
	$rcpath = ' -r '.$::config_obj->mecabrc_path if length($::config_obj->mecabrc_path);
	
	$self->{cmdline} = "mecab $rcpath -Ochasen -d \"$dic_path\" -o \"$self->{output_temp}\" \"$self->{target_temp}\""; # kr
	
	if ($::config_obj->all_in_one_pack){
		$self->{cmdline} = "DYLD_FALLBACK_LIBRARY_PATH=\"$::ENV{DYLD_FALLBACK_LIBRARY_PATH}\" $self->{cmdline}";
	}
	
	print "morpho: $self->{cmdline}\n";
	
	# 処理開始
	open (TRGT, "<:encoding(UTF-8)", $self->target) or 
		gui_errormsg->open(
			thefile => $self->target,
			type => 'file'
		);
	while ( <TRGT> ){
		my $t   = $_;
		#$t =~ s/ /　/g; # kr
		
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
			
			$self->_mecab_run($pre);
			$self->_mecab_outer($cnt);
			
			#print "[[$pre << $cnt >> $t]]\n";
		}
		$self->_mecab_store($t);
	}
	close (TRGT);
	$self->_mecab_run();
	return(1);
}

sub _mecab_run{
	my $self = shift;
	my $t    = shift;

	$self->_mecab_store($t) if length($t);
	$self->_mecab_store_out;

	return 1 unless -s $self->{target_temp} > 0;
	unlink $self->{output_temp} if -e $self->{output_temp};

	# MeCabにわたすファイル内容のチェック
	open my $fh_chk, '<', $self->{target_temp} or
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		)
	;
	#my $read_chk = '';
	my $has_lf = 0;
	while (<$fh_chk>){
		#$read_chk .= $_;
		if ($_ =~ /.*\n$/){
			$has_lf = 1;
		} else {
			$has_lf = 0;
		}
	}
	close $fh_chk;
	
	# 最後に改行文字をつけておく
	if ( $has_lf == 0 ){
		open my $fh_add, '>>', $self->{target_temp} or
			gui_errormsg->open(
				thefile => $self->{target_temp},
				type => 'file'
			)
		;
		print $fh_add "\n";
		close $fh_add;
		
		#$read_chk = Jcode->new($read_chk)->utf8;
		#print "Added LF for MeCab: $read_chk\n";
	}

	# MeCabの実行
	system "$self->{cmdline}";
	
	unless (-e $self->{output_temp}){
		$self->Exec_Error("No output file");
	}

	# 結果の取り出し
	my $cut_eos;
	if ( $self->{stlast} =~ /\n\Z/o){
		$cut_eos = 0;
	} else {
		$cut_eos = 1;
	}
	
	open (OTEMP, "<:encoding(UTF-8)", $self->{output_temp}) or
		gui_errormsg->open(
			thefile => $self->{output_temp},
			type => 'file'
		);
	open (OTPT,">>:encoding(UTF-8)",$self->output) or
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);
	
	my $last_line = '';

	# 文区切りの「。」を挿入 # kr
	while( <OTEMP> ){
		$_ =~ s/\x0D\x0A|\x0D|\x0A/\n/g; # 改行コード統一
		# 表層や基本形が出力されていない場合への対応
		if ($last_line =~ /^\t([^\t]+)\t\t(.+)/ ) {
			$last_line = "$1\t$1\t$1\t$2";
			chomp $last_line;
			$last_line .= "\n";
		}
		# 半角スペースへの対応
		if ($last_line =~ /([^\t]+)\t ([^\t]+)\t([^\t]+)\t(.+)/ ) {
			my ($t1, $t2, $t3, $t4) = ($1, $2, $3, $4);
			if ($t1 =~ /^ (.+)$/) {
			  $t1 = $1;
			}
			if ($t3 =~ /^ (.+)$/) {
			  $t3 = $1;
			}
			$last_line = "$t1\t$t2\t$t3\t$t4";
			chomp $last_line;
			$last_line .= "\n";
			print OTPT " \t \t \t半角スペース\t\t\n";
		}
		
		if ( length($last_line) > 0 ){
			if ( index($last_line,'Symbol-ピリオド') > -1){
				print OTPT $last_line;
				print OTPT "。\t。\t。\t文区切り\t\t\n";
			} else {
				print OTPT $last_line;
			}
		}
		$last_line = $_;
	}
		# 最後に余分な「EOS」が付くのを削除
	if ($last_line =~ /^EOS\n/o && $cut_eos){
	
	} else {
		print OTPT $last_line; 
	}
	
	close (OTEMP);
	close (OTPT);
	
	unlink $self->{output_temp} or
		gui_errormsg->open(
			thefile => $self->{output_temp},
			type => 'file'
		);

	unlink $self->{target_temp} or 
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		);

	# unlink 確認
	use Time::HiRes;
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

	$self->{store} = '';
}

sub _mecab_outer{
	my $self = shift;
	my $t    = shift;
	my $name = 'TAG';

	open (OTPT,">>:encoding(UTF-8)",$self->output) or 
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);

	print OTPT "$t\t$t\t$t\t$name\t\t\n";

	close (OTPT);
}

sub _mecab_store{
	my $self = shift;
	my $t    = shift;
	
	return 1 unless length($t) > 0;
	
	$self->{store} .= $t;
	$self->{stlast} = $t;
	
	if ( length($self->{store}) > 1048576 ){
		$self->_mecab_store_out;
	}

	return $self;
}


sub _mecab_store_out{
	my $self = shift;

	return 1 unless length($self->{store}) > 0;

	$self->{store} =~ s/[\x{AC00}-\x{D7A3}]/convert_main($&)/ge; # kr

	my $arg;
	if (-e $self->{target_temp}) {
		$arg = ">>:encoding(UTF-8)";
	} else {
		$arg = ">:encoding(UTF-8)";
	}

	open (TMPO, $arg, $self->{target_temp}) or
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		)
	;

	print TMPO $self->{store};
	close (TMPO);

	$self->{store} = '';
	return $self;
}

sub exec_error_mes{
	return kh_msg->get('error');
}


1;
