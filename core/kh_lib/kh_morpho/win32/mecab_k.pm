package kh_morpho::win32::mecab_k;
use base qw( kh_morpho::win32 );

use strict;
use utf8;

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

# encoding はすべてUTF-8に！ # kr

sub _run_morpho{
	my $self = shift;	
	my $path = $self->config->mecab_path;
	$path =~ s/\\/\//g;
	$path = $::config_obj->os_path($path);

	# kr
	my $dic_path = $self->config->han_dic_path;
	$dic_path =~ s/\\/\//g;
	$dic_path = $::config_obj->os_path($dic_path);
	
	# 初期化
	unless (-e $path){
		gui_errormsg->open(
			msg => kh_msg->get('error_config'),
			type => 'msg'
		);
		exit;
	}
	
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
	
	my $pos = rindex($path,"/bin/");
	$self->{dir} = substr($path,0,$pos);
	my $chasenrc = $self->{dir}."/etc/mecabrc";
	$self->{cmdline} = "mecab -Ochasen -r \"$chasenrc\" -d \"$dic_path\" -o \"$self->{output_temp}\" \"$self->{target_temp}\""; # kr
	#print "morpho: $self->{cmdline}\n";
	
	# 処理開始
	open (TRGT, "<:encoding(UTF-8)", $self->target) or
		gui_errormsg->open(
			thefile => $self->target,
			type => 'file'
		);
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

	# ここまでの処理前データをファイルへ書き出し out: $self->{target_temp}
	$self->_mecab_store($t) if length($t);
	$self->_mecab_store_out;

	return 1 unless -s $self->{target_temp} > 0;
	unlink $self->{output_temp} if -e $self->{output_temp};
	
	#print "path: ".$::config_obj->os_path( $self->config->mecab_path )."\n";
	#print "cmd: $self->{cmdline}\n";
	#print "dir: $self->{dir}\n";
	
	# MeCabによる処理 in: $self->{target_temp}, out: $self->{output_temp}
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
	
	my $cut_eos;
	if ( $self->{stlast} =~ /\n\Z/o){
		$cut_eos = 0;
	} else {
		$cut_eos = 1;
	}
	
	# MeCabの処理結果を収集 in: $self->{output_temp} out: $self->output
	# ↓ここでMecabの出力を修正↓
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

	open (OTPT,">>:encoding(UTF-8)",$self->output) or 
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);

	print OTPT "$t\t$t\t$t\tTAG\t\t\n";

	close (OTPT);
}

# MeCabで処理する前のデータを蓄積
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

# MeCabで処理する前のデータをファイルに書き出し
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
		);

	print TMPO $self->{store};
	close (TMPO);

	$self->{store} = '';
	return $self;
}

sub exec_error_mes{
	return kh_msg->get('error');
}


1;
