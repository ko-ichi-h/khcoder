package kh_sysconfig::linux;
use base qw(kh_sysconfig);
use strict;

#----------------------------#
#   設定の読み込みルーチン   #
#----------------------------#

sub _readin{
	use Jcode;
	use kh_sysconfig::linux::chasen;
	use kh_sysconfig::linux::juman;

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

		my @outlist = (
			'chasenrc_path',
			'grammarcha_path',
#			'juman_path',
			'c_or_j',
			'use_sonota',
			'color_DocView_info',
			'color_DocView_search',
			'color_DocView_force',
			'color_DocView_html',
			'color_DocView_CodeW',
			'DocView_WrapLength_on_Win9x',
			'DocSrch_CutLength',
			'app_html',
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
		return 'gnome-moz-remote --newwin \'%s\'';
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
		return '/usr/local/starsuite6.0/program/scalc %s &';
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

#------------#
#   その他   #


sub os_path{
	my $self = shift;
	my $c = shift;

	$c = Jcode->new("$c")->euc;
	$c =~ tr/\\/\//;

	return $c;
}


1;

__END__
