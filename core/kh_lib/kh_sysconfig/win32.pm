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

	my $self = shift;

	# Chasenの設定
	if (-e $self->{chasen_path}){
		my $pos = rindex($self->{chasen_path},'\\');
		$self->{grammercha} = substr($self->{chasen_path},0,$pos);
		$self->{chasenrc} = "$self->{grammercha}".'\\dic\chasenrc';
		$self->{grammercha} .= '\dic\grammar.cha';
		
		my $flag = 0; my $msg = '(連結品詞';
		Jcode::convert(\$msg,'sjis','euc');
		if (-e $self->{chasenrc}){
			open (CRC,"$self->{chasenrc}") or
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

	my @outlist = (
		'chasen_path',
		'mecab_path',
		'c_or_j',
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
		'all_in_one_pack',
		'font_main',
		'kaigyo_kigou',
		'color_DocView_info',
		'color_DocView_search',
		'color_DocView_force',
		'color_DocView_html',
		'color_DocView_CodeW',
		'DocView_WrapLength_on_Win9x',
		'DocSrch_CutLength',
	);
	
	my $f = $self->{ini_file};
	open (INI,">$f") or
		gui_errormsg->open(
			type    => 'file',
			thefile => ">$f"
		);
	foreach my $i (@outlist){
		my $value = $self->$i( undef,'1');
		$value = '' unless defined($value);
		print INI "$i\t".$value."\n";
	}
	foreach my $i (keys %{$self}){
		if ( index($i,'w_') == 0 ){
			my $value = $self->win_gmtry($i);
			$value = '' unless defined($value);
			print INI "$i\t".$value."\n";
		}
	}
	if ($self->{main_window}){
		print INI "main_window\t$self->{main_window}";
	}
	close (INI);
	return 1;

}

#--------------------#
#   形態素解析関係   #


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

sub underline_conv{
	my $self = shift;
	my $n    = shift;
	
	require Win32;
	
	if ($Tk::VERSION >= 804.029 && Win32::IsWinNT() ){
		$n = ( ($n - 1) / 2 ) + 1;
	}
	return $n;
}

sub mw_entry_length{
	return 21;
}

sub font_main{
	my $self = shift;
	my $new  = shift;
	$self->{font_main} = $new         if defined($new) && length($new);
	$self->{font_main} = 'MS UI Gothic,10'  unless length($self->{font_main});
	return $self->{font_main};
}

#------------#
#   その他   #


sub os_path{
	my $self  = shift;
	my $c     = shift;
	my $icode = shift;

	#print "kh_sysconfig::win32::os_path[1]:  $c\n";

	$c = Jcode->new("$c",$icode)->euc;
	$c =~ tr/\//\\/;
	$c = Jcode->new("$c",'euc')->sjis;
	
	#print "kh_sysconfig::win32::os_path[2]:  $c\n";
	
	return $c;
}

sub os_cod_path{
	my $self  = shift;
	my $c     = shift;
	my $icode = shift;

	#print "kh_sysconfig::win32::os_path[1]:  $c\n";

	$c = Jcode->new("$c",$icode)->euc;
	$c =~ tr/\//\\/;
	$c = Jcode->new("$c",'euc')->sjis;
	
	$c = Jcode->new("$c",$icode)->euc;
	$c =~ tr/\\/\//;
	$c = Jcode->new("$c",'euc')->sjis;
	
	#print "kh_sysconfig::win32::os_path[2]:  $c\n";
	
	return $c;
}


sub R_device{
	my $self  = shift;
	my $path  = shift;
	my $width = shift;
	my $height = shift;
	
	$path .= '.png';
	# unlink($path) if -e $path;
	
	$width  = 480 unless $width;
	$height = 480 unless $height;

	return 0 unless $::config_obj->R;
	
	$::config_obj->R->send(
		"png(\"$path\", width=$width, height=$height, unit=\"px\")"
	);
	return $path;
}


1;

__END__
