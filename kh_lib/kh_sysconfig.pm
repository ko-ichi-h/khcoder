package kh_sysconfig;
use strict;

use kh_sysconfig::win32;
use kh_sysconfig::linux;

sub readin{
	my $class = shift;
	$class .= '::'.&os;
	my $self;
	$self->{ini_file} = shift;
	$self->{cwd} = shift;

	# 設定ファイルが揃っているか確認
	if (
		   ! -e "$self->{ini_file}"
		|| ! -e "./config/hinshi_chasen"
	){
		# 揃っていない場合は設定を初期化
		print "Resetting parameters...\n";
		mkdir "config";
		open (CON,">$self->{ini_file}") or 
			gui_errormsg->open(
				type    => 'file',
				thefile => "m: $self->{ini_file}"
			);
		close (CON);
		use File::Copy;
		copy("./.default/hinshi_chasen","./config/hinshi_chasen") or die;
	}


	# iniファイル
	open (CINI,"$self->{ini_file}") or
		gui_errormsg->open(
			type    => 'file',
			thefile => "$self->{ini_file}"
		);
	while (<CINI>){
		chomp;
		my @temp = split /\t/, $_;
		$self->{$temp[0]} = $temp[1];
	}
	close (CINI);

	# その他
	$self->{history_file} = $self->{cwd}.'/config/projects';
	$self->{history_trush_file} = $self->{cwd}.'/config/projects_trush';


	bless $self, $class;

	$self = $self->_readin;


	return $self;
}
#--------------------#
#   形態素解析関係   #

sub refine_cj{
	my $self = shift;
	bless $self, 'kh_sysconfig::win32::'.$self->c_or_j;
	return $self;
}

sub use_hukugo{
	my $self = shift;
	my $new = shift;
	if (length($new) > 0){
		$self->{use_hukugo} = $new;
	}
	return $self->{use_hukugo};
}

sub c_or_j{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{c_or_j} = $new;
	}

	if (length($self->{c_or_j}) > 0) {
		return $self->{c_or_j};
	} else {
		return 'chasen';
	}
}

sub use_sonota{
	my $self = shift;
	my $new = shift;
	if ( length($new) > 0 ){
		$self->{use_sonota} = $new;
	}

	if ( $self->{use_sonota} ){
		return $self->{use_sonota};
	} else {
		return 0;
	}
}


#-------------#
#   GUI関係   #

sub DocSrch_CutLength{
	my $self = shift;
	if (defined($self->{DocSrch_CutLength})){
		return $self->{DocSrch_CutLength};
	} else {
		return '66';
	}
}

sub DocView_WrapLength_on_Win9x{
	my $self = shift;
	if (defined($self->{DocView_WrapLength_on_Win9x})){
		return $self->{DocView_WrapLength_on_Win9x};
	} else {
		return '80';
	}
}

sub color_DocView_info{
	my $self = shift;
	my $i    = $self->{color_DocView_info};
	unless ( defined($i) ){
		$i = "blue";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		return @h;
	}
}

sub color_DocView_search{
	my $self = shift;
	my $i    = $self->{color_DocView_search};
	unless ( defined($i) ){
		$i = "on_yellow";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		return @h;
	}
}

sub color_DocView_force{
	my $self = shift;
	my $i    = $self->{color_DocView_force};
	unless ( defined($i) ){
		$i = "on_cyan";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		return @h;
	}
}

sub color_DocView_html{
	my $self = shift;
	my $i    = $self->{color_DocView_html};
	unless ( defined($i) ){
		$i = "red";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		return @h;
	}
}

sub color_DocView_CodeW{
	my $self = shift;
	my $i    = $self->{color_DocView_CodeW};
	unless ( defined($i) ){
		$i = "blue,underline";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		return @h;
	}
}

sub win_gmtry{
	my $self = shift;
	my $win_name = shift;
	my $geometry = shift;
	if (defined($geometry)){
		$self->{$win_name} = $geometry;
	} else {
		return $self->{$win_name};
	}
}




#------------#
#   その他   #

sub history_file{
	my $self = shift;
	return $self->{history_file};
}

sub history_trush_file{
	my $self = shift;
	return $self->{history_trush_file};
}

sub cwd{
	my $self = shift;
	my $c = $self->{cwd};
	$c = $self->os_path($c);
	return $c;
}


sub icon_image_file{
	return Tk->findINC('ghome.gif');
}

sub logo_image_file{
	my $self = shift;
	return Tk->findINC('kh_logo.bmp');
}


sub os{
	if ($^O eq 'MSWin32') {
		return 'win32';
	} else {
		return 'linux';
	}
}


1;
