package kh_sysconfig::win32;
use base qw(kh_sysconfig);
use strict;

#----------------------------#
#   設定の読み込みルーチン   #
#----------------------------#

sub _readin{
	use Jcode;
	use kh_sysconfig::win32::chasen;
	use kh_sysconfig::win32::juman;

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
		my @outlist = (
			'chasen_path',
			'juman_path',
			'c_or_j',
			'use_sonota',
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
			print INI "$i\t".$self->$i('','1')."\n";
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
	} else {
		return 0;
	}
}



#--------------------------------#
#   以下は設定値を返すルーチン   #
#--------------------------------#


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

sub juman_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{juman_path} = $new;
	}
	return $self->{juman_path};
}

#-------------#
#   GUI関係   #

sub underline_conv{
	my $self = shift;
	my $n    = shift;
	return $n;
}

sub mw_entry_length{
	return 20;
}

#------------#
#   その他   #


sub os_path{
	my $self = shift;
	my $c = shift;

	$c = Jcode->new("$c")->euc;
	$c =~ tr/\//\\/;
	$c = Jcode->new("$c")->sjis;

	return $c;
}


1;

__END__
