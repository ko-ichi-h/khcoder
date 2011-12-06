package kh_sysconfig::linux;
use base qw(kh_sysconfig);
use strict;

#----------------------------#
#   設定の読み込みルーチン   #
#----------------------------#

sub _readin{
	use Jcode;
	use kh_sysconfig::linux::chasen;
	use kh_sysconfig::linux::mecab;
	use kh_sysconfig::linux::stemming;
	use kh_sysconfig::linux::stanford;

	my $self = shift;


	# Chasenの設定
	if (-e $self->chasenrc_path){
		my $flag = 0; my $msg = '(連結品詞';
		if (-e $self->chasenrc_path){
			open (CRC,"$self->{chasenrc_path}") or
				gui_errormsg->open(
					type    => 'file',
					thefile => "$self->{chasenrc_path}"
				);
			while (<CRC>){
				chomp;
				if ($_ eq '; by KH Coder, start.'){
					$flag = 1;
					next;
				}
				elsif ($_ eq '; by KH Coder, end.'){
					$flag = 0;
					next;
				}

				unless ($flag){
					next;
				}
				if ($_ eq "$msg"){
					$self->{use_hukugo} = 1;
				}
			}
			close (CRC);
		}
		unless ($self->{use_hukugo}){
			$self->{use_hukugo} = 0;
		}
	}

	return $self;
}

#------------------#
#   設定値の保存   #
#------------------#

sub save{
	my $self = shift;

	$self = $self->refine_cj;
	if ($self->path_check){
		$self->config_morph;
	}

	$self->save_ini;
	
	return 1;
}

sub save_ini{
	my $self = shift;
	$self = $self->refine_cj;

	my @outlist = (
		'chasenrc_path',
		'grammarcha_path',
		'stanf_jar_path',
		'stanf_tagger_path',
		#'juman_path',
		'c_or_j',
		'stemming_lang',
		'stanford_lang',
		'msg_lang',
		'r_path',
		'r_plot_debug',
		'sqllog',
		'sql_username',
		'sql_password',
		'sql_host',
		'sql_port',
		'multi_threads',
		'mail_if',
		'mail_smtp',
		'mail_from',
		'mail_to',
		'use_heap',
		'font_main',
		'font_plot',
		'kaigyo_kigou',
		'color_DocView_info',
		'color_DocView_search',
		'color_DocView_force',
		'color_DocView_html',
		'color_DocView_CodeW',
		'color_ListHL_fore',
		'color_ListHL_fore',
		'DocView_WrapLength_on_Win9x',
		'DocSrch_CutLength',
		'app_html',
		'app_csv',
		'app_pdf',
	);

	my $f = $self->{ini_file};
	open (INI,">$f") or
		gui_errormsg->open(
			type    => 'file',
			thefile => ">$f"
		);
	foreach my $i (@outlist){
		print INI "$i\t".$self->$i(undef,'1')."\n";
	}
	foreach my $i (keys %{$self}){
		if ( index($i,'w_') == 0 ){
			print INI "$i\t".$self->win_gmtry($i)."\n";
		}
	}
	if ($self->{main_window}){
		print INI "main_window\t$self->{main_window}";
	}
	close (INI);
	return 1;

}

#--------------------------------#
#   以下は設定値を返すルーチン   #
#--------------------------------#

#--------------------#
#   形態素解析関係   #

sub chasenrc_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{chasenrc_path} = $new;
	}
	return $self->{chasenrc_path};
}

sub grammarcha_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{grammarcha_path} = $new;
	}
	return $self->{grammarcha_path};
}

#sub juman_path{
#	my $self = shift;
#	my $new = shift;
#	if ($new){
#		$self->{juman_path} = $new;
#	}
#	return $self->{juman_path};
#}


#--------------------------#
#   外部アプリケーション   #

sub app_html{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{app_html} = $new;
	}
	if ($self->{app_html}){
		return $self->{app_html};
	} else {
		return 'firefox \'%s\' &';
	}
}

sub app_pdf{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{app_pdf} = $new;
	}
	if ($self->{app_pdf}){
		return $self->{app_pdf};
	} else {
		return 'acroread %s &';
	}
}

sub app_csv{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{app_csv} = $new;
	}
	if ($self->{app_csv}){
		return $self->{app_csv};
	} else {
		return 'soffice -calc %s &';
	}
}

#-------------#
#   GUI関係   #

sub underline_conv{
	my $self = shift;
	my $n    = shift;
	$n = ( ($n - 1) / 2 ) + 1;
	return $n;
}

sub mw_entry_length{
	return 30;
}

sub font_main{
	my $self = shift;
	my $new  = shift;
	$self->{font_main} = $new         if length($new);
	$self->{font_main} = 'kochi gothic,10'  unless length($self->{font_main});
	return $self->{font_main};
}

sub font_plot{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot} = $new         if defined($new) && length($new);
	unless ( length($self->{font_plot}) ){
		if ( $^O =~ /darwin/){
			$self->{font_plot} = 'Hiragino Kaku Gothic Pro W3';
		} else {
			$self->{font_plot} = 'IPAPGothic';
		}
	}
	return $self->{font_plot};
}

#------------#
#   その他   #

sub os_path{
	my $self  = shift;
	my $c     = shift;
	my $icode = shift;

	if ($^O eq 'darwin'){ # Mac OS X
		
		$c = Jcode->new("$c",$icode)->euc;
		my $ascii = '[\x00-\x7F]';
		my $twoBytes = '[\x8E\xA1-\xFE][\xA1-\xFE]';
		my $threeBytes = '\x8F[\xA1-\xFE][\xA1-\xFE]';
		my $character_undef =
			'(?:[\xA9-\xAF\xF5-\xFE][\xA1-\xFE]|' # 9-15,85-94区
			  . '\x8E[\xE0-\xFE]|' # 半角カタカナ
			  . '\xA2[\xAF-\xB9\xC2-\xC9\xD1-\xDB\xEB-\xF1\xFA-\xFD]|' # 2区
			  . '\xA3[\XA1-\xAF\xBA-\xC0\xDB-\xE0\xFB-\xFE]|' # 3区
			  . '\xA4[\xF4-\xFE]|' # 4区
			  . '\xA5[\xF7-\xFE]|' # 5区
			  . '\xA6[\xB9-\xC0\xD9-\xFE]|' # 6区
			 . '\xA7[\xC2-\xD0\xF2-\xFE]|' # 7区
			  . '\xA8[\xC1-\xFE]|' # 8区
			  . '\xCF[\xD4-\xFE]|' # 47区
			  . '\xF4[\xA7-\xFE]|' # 84区
			  . '\x8F[\xA1-\xFE][\xA1-\xFE])'; # 3バイト文字

		foreach my $i ($c =~ /$ascii|$twoBytes|$threeBytes/og){
			if ($i =~ /$character_undef/){
				gui_errormsg->open(
					type   => 'msg',
					msg    => "未対応文字がファイル名またはフォルダ名に含まれています。\n現在のところ、EUCに変換できない文字には未対応です。"
				);
				return undef;
			}
		}

		$c = Jcode->new("$c",'euc')->utf8;
	} else {
		$c = Jcode->new("$c",$icode)->euc;
		$c =~ tr/\\/\//;
	}

	return $c;
}

*os_cod_path = \&os_path;

1;

__END__
