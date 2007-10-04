package kh_datacheck;
use strict;

my %errors;
$errors{error_m1} = '長すぎる見出し行があります（自動修正不可）';
$errors{error_c1} = '文字化けを含む行があります';
$errors{error_c2} = '望ましくない半角記号が含まれている行があります';
$errors{error_n1a} = '長すぎる行があります';
$errors{error_n1b} = '長すぎる上に、スペース・句点等が適当な位置に含まれていない行があります（自動修正不可）';

sub run{
	my $class = shift;
	my $self;
	$self->{file_source} = $::project_obj->file_target;
	$self->{file_temp}   = 'temp.txt';
	while (-e $self->{file_temp}){
		$self->{file_temp} .= '.tmp';
	}
	bless $self, $class;

	# 文字コードのチェック
	my $icode = kh_jchar->check_code($self->{file_source});
	unless (
		   $icode eq 'sjis'
		|| $icode eq 'euc'
		|| $icode eq 'jis'
	) {
		gui_errormsg->open(
			type => 'msg',
			msg  => "分析対象ファイルの文字コード判別に失敗しました。\nプロジェクト編集画面で文字コードを指定して下さい。\nプロジェクト編集画面を開くには、メニューから「プロジェクト」→「開く」→「編集」をクリックします。"
		);
		return 0;
	}

	# 内容チェックの実行
	open (SOURCE,"$self->{file_source}") or
		gui_errormsg->open(
			type => 'file',
			thefile => $self->{file_source}
		);
	open (EDITED,">$self->{file_temp}") or 
		gui_errormsg->open(
			type => 'file',
			thefile => $self->{file_temp}
		);
	binmode(SOURCE);

	my $n = 1;
	while (<SOURCE>){
		s/\x0D\x0A|\x0D|\x0A/\n/g;
		chomp;
		
		my $ci = Jcode->new($_,$icode)->euc;
		
		my $co = '';
		my ($t_c1, $t_c2, $t_n1a, $t_n1b);
		
		if ($ci =~ /^(<H[1-5]>)(.*)(<\/H[1-5]>)$/i){
			if (length($ci) > 8000){
				$self->{error_m1}{flag} = 1;
				push @{$self->{error_m1}{array}}, [$n, $ci];
			}
			( $co, $t_c1, $t_c2, $t_n1a, $t_n1b ) = &my_cleaner::exec($2);
			$co = $1.$co.$3;
		} else {
			( $co, $t_c1, $t_c2, $t_n1a, $t_n1b ) = &my_cleaner::exec($ci);
			if ($t_n1a and not $t_n1b){
				$self->{error_n1a}{flag} = 1;
				push @{$self->{error_n1a}{array}}, [$n, $ci];
			}
			if ($t_n1b){
				$self->{error_n1b}{flag} = 1;
				push @{$self->{error_n1b}{array}}, [$n, $ci];
			}
		}
		if ($t_c1){
			$self->{error_c1}{flag} = 1;
			push @{$self->{error_c1}{array}}, [$n, $ci];
		}
		if ($t_c2){
			$self->{error_c2}{flag} = 1;
			push @{$self->{error_c2}{array}}, [$n, $ci];
		}
		++$n;
		print EDITED Jcode->new($co,'euc')->$icode, "\n";
	}
	close (EDITED);
	close (SOURCE);

	# レポート（概要）の作成
	my $if_errors = 0;
	my $msg = '';
	foreach my $i ('error_m1','error_n1b','error_c1','error_c2','error_n1a'){
		if ($self->{$i}{flag}){
			my $num = @{$self->{$i}{array}};
			$msg .= "　・$errors{$i}： $num"."行\n";
		}
	}
	if ($msg){
		$msg = "分析対象ファイル内に以下の問題点が発見されました（要約）。\n".$msg;
		$self->{repo_sum} = $msg;
	} else {
		$msg = "分析対象ファイル内に既知の問題点は発見されませんでした。\n前処理を安全に実行できると考えられます。";
		gui_errormsg->open(
			type => 'msg',
			msg  => $msg,
			icon => 'info',
		);
		unlink($self->{file_temp});
		return 1;
	}
	
	# レポート（詳細）の作成
	$msg = "分析対象ファイル内に以下の問題点が発見されました（詳細）。\n";
	foreach my $i ('error_m1','error_n1b','error_c1','error_c2','error_n1a'){
		if ($self->{$i}{flag}){
			my $num = @{$self->{$i}{array}};
			$msg .= "■$errors{$i}： $num"."行\n";
			
			foreach my $h (@{$self->{$i}{array}}){
				$msg .= "l. $h->[0]\t"; # 行番号
				if (length($h->[1]) > 60 ){
					my $n = 60;
					while (
						   substr($h->[1],0,$n) =~ /\x8F$/
						or substr($h->[1],0,$n) =~ tr/\x8E\xA1-\xFE// % 2
					) {
						--$n;
					}
					$msg .= substr($h->[1],0,$n)."...\n";
				} else {
					$msg .= "$h->[1]\n";
				}
			}
		}
	}
	$self->{repo_full} = $msg;
	
	
	print Jcode->new("$msg",'euc')->sjis;
	print "Let's start GUI...\n";
}



#--------------------------------------------------------------#
#   整形（文字化け部分削除・半角記号削除・折り返し）ルーチン   #

package my_cleaner;

BEGIN{
	use vars qw($ascii $twoBytes $threeBytes $ctrl $rep $character_undef);
	$ascii           = '[\x00-\x7F]';
	$twoBytes        = '[\x8E\xA1-\xFE][\xA1-\xFE]';
	$threeBytes      = '\x8F[\xA1-\xFE][\xA1-\xFE]';
	$ctrl            = '[[:cntrl:]]';                         # 制御文字
	$rep             = ' ';                                   # 置換先
	$character_undef = '(?:[\xA9-\xAF\xF5-\xFE][\xA1-\xFE]|'  # 9-15,85-94区
		. '\x8E[\xE0-\xFE]|'                                     # 半角カタカナ
		. '\xA2[\xAF-\xB9\xC2-\xC9\xD1-\xDB\xEB-\xF1\xFA-\xFD]|' # 2区
		. '\xA3[\XA1-\xAF\xBA-\xC0\xDB-\xE0\xFB-\xFE]|'          # 3区
		. '\xA4[\xF4-\xFE]|'                                     # 4区
		. '\xA5[\xF7-\xFE]|'                                     # 5区
		. '\xA6[\xB9-\xC0\xD9-\xFE]|'                            # 6区
		. '\xA7[\xC2-\xD0\xF2-\xFE]|'                            # 7区
		. '\xA8[\xC1-\xFE]|'                                     # 8区
		. '\xCF[\xD4-\xFE]|'                                     # 47区
		. '\xF4[\xA7-\xFE]|'                                     # 84区
		. '\x8F[\xA1-\xFE][\xA1-\xFE])';                         # 3バイト文字
}

sub exec{
	my $t = shift;
	
	my $flag_bake     = 0;
	my $flag_hankaku  = 0;
	my $flag_long     = 0;
	my $flag_longlong = 0;

	if (length($t) > 16000){
		$flag_long = 1;
	}
	if ($t =~ /'|\\|"|<|>|$ctrl|\|/){
		$flag_hankaku = 1;
	}

	#$t = Jcode->new($t,'sjis')->h2z->euc;
	
	# 半角記号の削除
	$t =~ s/'/ /g;
	$t =~ s/\\/ /g;
	$t =~ s/"/ /g;
	$t =~ s/\|/ /g;
	$t =~ s/</ /g;
	$t =~ s/>/ /g;
	$t =~ s/$ctrl/$rep/g;

	# 一文字ずつ処理
	my @chars = $t =~ /$ascii|$twoBytes|$threeBytes/og;

	my $n = 0;
	my $r = '';
	my $cu = '';
	foreach my $i (@chars){
		# 化けている文字はスキップ
		if (
			   ($i =~ /$character_undef/o)
			|| (
				   ($i =~ /$ascii/o)
				&! ($i =~ /[[:print:]]/o)
			)
		){
			$flag_bake = 1;
			next;
		}
		
		# 折り返し
		if (
			( $n > 200   )
			&& ( $flag_long )
			&& (
				   $i eq ' '
				|| $i eq '　'
				|| $i eq '。'
				|| $i eq '.'
				|| $i eq '-'
				|| $i eq '−'
				|| $i eq '―'
			)
		){
			$cu .= "$i\n";
			$r .= $cu;
			if (length($cu) > 16000){
				$flag_longlong = 1;
			}
			$cu = '';
			$n = -1;
		} else {
			$cu .= $i;
		}
		++$n;
	}
	if (length($cu) > 16000){
		$flag_longlong = 1;
	}
	$r .= "$cu";
	#$r = Jcode->new($r,'euc')->sjis;
	
	return ($r,$flag_bake,$flag_hankaku,$flag_long,$flag_longlong);
}



1;