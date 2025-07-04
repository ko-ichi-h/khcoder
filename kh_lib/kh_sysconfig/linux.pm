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
	use kh_sysconfig::linux::mecab_k;
	use kh_sysconfig::linux::stemming;
	use kh_sysconfig::linux::stanford;
	use kh_sysconfig::linux::freeling;

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



sub ini_content{
	my $self = shift;
	$self = $self->refine_cj;

	my @outlist = (
		'private_dir',
		'chasenrc_path',
		'grammarcha_path',
		'mecab_unicode',
		'mecabrc_path',
		'stanf_jar_path',
		'stanf_tagger_path_en',
		'stanf_tagger_path_cn',
		'stanf_seg_path',
		'stanford_port',
		'stanford_ram',
		'han_dic_path',
		'freeling_dir',
		'freeling_port',
		'freeling_lang',
		'stanford_lang',
		'stemming_lang',
		'last_lang',
		'last_method',
		'c_or_j',
		'unify_words_with_same_lemma',
		'show_suggest_on_startup',
		'suggest_stands_with_main',
		'msg_lang',
		'msg_lang_set',
		'r_path',
		'r_plot_debug',
		'sqllog',
		'sql_username',
		'sql_password',
		'sql_host',
		'sql_port',
		'sql_type',
		'sql_socket',
		'multi_threads',
		'color_universal_design',
		'mail_if',
		'mail_smtp',
		'mail_from',
		'mail_to',
		'use_heap',
		'show_bars_wordlist',
		'all_in_one_pack',
		'font_main',
		'font_plot',
		'font_plot_cn',
		'font_plot_kr',
		'font_plot_ru',
		'font_pdf',
		'font_pdf_cn',
		'font_pdf_kr',
		'corresp_max_values',
		'newline_symbol',
		'cell_symbol',
		'color_DocView_info',
		'color_DocView_search',
		'color_DocView_force',
		'color_DocView_html',
		'color_DocView_CodeW',
		'color_ListHL_fore',
		'color_ListHL_back',
		'color_palette',
		'plot_size_words',
		'plot_size_codes',
		'plot_font_size',
		'DocView_WrapLength_on_Win9x',
		'DocSrch_CutLength',
		'app_html',
		'app_csv',
		'app_pdf',
	);

	my $content = '';

	foreach my $i (@outlist){
		my $value = $self->$i(undef,'1');
		$value = '' unless defined $value;
		$content .= "$i\t$value\n";
	}

	return $content;

}

sub ram{
	my $self = shift;
	return $self->{ram_r} if $self->{ram_r};

	if ($^O =~ /darwin/i){
		my $r = `system_profiler SPHardwareDataType | grep Memory`;
		my $r0 = 0;
		if ( $r =~ /([0-9]+)/ ){
			$r0 = $1;
		}
		if ($r =~ /GB/){
			$r0 = $r0 * 1024;
		}
		$self->{ram_r} = $r0;
		print "ram_r $r0\n";
	} else {
	  my $r = `free -m | grep Mem`;
	  $r =~ s/Mem:\s+([0-9]+)\s+.+/$1/;
	  $self->{ram_r} = $r;
	}

	return $self->{ram_r};
}

sub stanford_ram{
	my $self = shift;
	my $new  = shift;
	
	if (defined($new) && length($new)){
		$self->{stanford_ram} = $new;
	}
	
	$self->{stanford_ram} = "2g"  unless defined( $self->{stanford_ram} );
	
	return Encode::encode('ascii', $self->{stanford_ram});
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

sub font_plot_cn{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot_cn} = $new if defined($new) && length($new);
	unless ( length($self->{font_plot_cn}) ){
		if ( $^O =~ /darwin/){
			$self->{font_plot_cn} = 'STHeiti';
		} else {
			$self->{font_plot_cn} = 'Droid Sans Fallback';
		}
	}
	return $self->{font_plot_cn};
}

sub font_plot_kr{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot_kr} = $new         if defined($new) && length($new);
	unless ( length($self->{font_plot_kr}) ){
		if ( $^O =~ /darwin/){
			$self->{font_plot_kr} = 'AppleGothic';
		} else {
			$self->{font_plot_kr} = 'UnDotum';
		}
	}
	return $self->{font_plot_kr};
}

sub font_plot_ru{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot_ru} = $new         if defined($new) && length($new);
	unless ( length($self->{font_plot_ru}) ){
		if ( $^O =~ /darwin/){
			$self->{font_plot_ru} = 'Helvetica';
		} else {
			$self->{font_plot_ru} = 'Droid Sans';
		}
	}
	return $self->{font_plot_ru};
}


1;

__END__
