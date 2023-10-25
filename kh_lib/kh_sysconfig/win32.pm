use utf8;
use Encode qw/encode decode/;

package kh_sysconfig::win32;
use base qw(kh_sysconfig);
use strict;

#----------------------------#
#   設定の読み込みルーチン   #
#----------------------------#

sub _readin{
	use Jcode;
	use kh_sysconfig::win32::chasen;
	use kh_sysconfig::win32::mecab;
	use kh_sysconfig::win32::mecab_k;
	use kh_sysconfig::win32::stemming;
	use kh_sysconfig::win32::stanford;
	use kh_sysconfig::win32::freeling;

	my $self = shift;

	# Chasenの設定
	if (-e $self->{chasen_path}){
		my $pos = rindex($self->{chasen_path},'\\');
		$self->{grammercha} = substr($self->{chasen_path},0,$pos);
		$self->{chasenrc} = "$self->{grammercha}".'\\dic\chasenrc';
		$self->{grammercha} .= '\dic\grammar.cha';
		
		my $flag = 0;
		my $msg = '(連結品詞';
		if (-e $self->{chasenrc}){
			open (CRC, '<:encoding(cp932)', $self->{chasenrc}) or
				gui_errormsg->open(
					type    => 'file',
					thefile => "$self->{chasenrc}"
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

	my @outlist = (
		'private_dir',
		'chasen_path',
		'mecab_path',
		'mecab_unicode',
		'java_path',
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
		'msg_lang',
		'msg_lang_set',
		'r_path',
		'r_plot_debug',
		'devEMF',
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
	);
	

	my $content = '';

	foreach my $i (@outlist){
		my $value = $self->$i( undef,'1');
		$value = '' unless defined($value);
		
		unless ( utf8::is_utf8($value) ){
			$value = Encode::decode('utf8', Jcode->new($value)->utf8);
			# 基本的にすべてdecodeされている前提
			# 日本語・ASCII以外がdecodeされていなければ文字化け！
		}
		$content .= "$i\t".$value."\n";
	}

	return $content;
}

sub ram{
	my $self = shift;
	
	return 0 unless $::config_obj->R;
	
	return $self->{ram_r} if $self->{ram_r};
	
	$::config_obj->R->send('
		ram <- memory.limit()
		print( paste0("khcoder", ram, "khcoder") )
	');
	my $t = $::config_obj->R->read;
	
	if ($t =~ /khcoder(.+)khcoder/) {
		$self->{ram_r} = $1;
	}
	return $self->{ram_r};
}

#--------------------#
#   形態素解析関係   #

sub java_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{java_path} = $new;
	}
	return $self->{java_path};
}

sub chasen_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{chasen_path} = $new;
	}
	return $self->{chasen_path};
}

sub mecab_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{mecab_path} = $new;
	}
	return $self->{mecab_path};
}

#-------------#
#   GUI関係   #

sub mw_entry_length{
	require Win32;
	
	my $m = ( Win32::GetOSVersion() )[1];
	if ($m >= 6 && $::config_obj->msg_lang eq 'jp'){
		return 27;
	} else {
		return 22;
	}
}

sub font_main{
	my $self = shift;
	my $new  = shift;
	$self->{font_main} = $new         if defined($new) && length($new);
	$self->{font_main} = 'MS UI Gothic,10'  unless length($self->{font_main});
	return $self->{font_main};
}

sub font_plot{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot} = $new         if defined($new) && length($new);
	$self->{font_plot} = 'Meiryo UI'  unless length($self->{font_plot});
	return $self->{font_plot};
}

sub font_plot_cn{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot_cn} = $new         if defined($new) && length($new);
	$self->{font_plot_cn} = 'SimHei'  unless length($self->{font_plot_cn});
	return $self->{font_plot_cn};
}

sub font_plot_kr{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot_kr} = $new         if defined($new) && length($new);
	$self->{font_plot_kr} = 'Malgun Gothic' unless length($self->{font_plot_kr});
	return $self->{font_plot_kr};
}

sub font_plot_ru{
	my $self = shift;
	my $new  = shift;
	$self->{font_plot_ru} = $new         if defined($new) && length($new);
	$self->{font_plot_ru} = 'Meiryo UI' unless length($self->{font_plot_ru});
	return $self->{font_plot_ru};
}

1;

__END__
