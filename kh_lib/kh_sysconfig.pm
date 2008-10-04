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
	bless $self, $class;

	# cwdのチェック
	if ( $] > 5.008 ) {
		if ( utf8::is_utf8($self->{cwd}) ){
			warn "Error: Unexpected UTF8 Flag!";
		}
	}
	#print "kh_sysconfig: $self->{cwd}\n";
	

	# 設定ファイルが揃っているか確認
	if (
		   ! -e "$self->{ini_file}"
		|| ! -e "./config/hinshi_chasen"
	){
		# 揃っていない場合は設定を初期化
		$self->reset_parm;
	}

	# iniファイル
	#print "kh_sysconfig: $self->{ini_file}\n";
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

	$self = $self->_readin;

	return $self;
}
#--------------------#
#   形態素解析関係   #

sub refine_cj{
	my $self = shift;
	bless $self, 'kh_sysconfig::'.$self->os.'::'.$self->c_or_j;
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

# Window位置とサイズのリセット
sub ClearGeometries{
	my $self = shift;
	foreach my $i (keys %{$self}){
		undef $self->{$i} if $i =~ /^w_/;
	}
	return $self;
}

sub DocSrch_CutLength{
	my $self = shift;
	if (defined($self->{DocSrch_CutLength})){
		return $self->{DocSrch_CutLength};
	} else {
		return '85';
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
		$i = "#008000,white,0";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		$h[2] = 0 unless defined($h[2]) && length($h[2]);
		return @h;
	}
}

sub color_DocView_search{
	my $self = shift;
	my $i    = $self->{color_DocView_search};
	unless ( defined($i) ){
		$i = "black,yellow,0";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		$h[2] = 0 unless defined($h[2]) && length($h[2]);
		return @h;
	}
}

sub color_DocView_force{
	my $self = shift;
	my $i    = $self->{color_DocView_force};
	unless ( defined($i) ){
		$i = "black,cyan,0";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		$h[2] = 0 unless defined($h[2]) && length($h[2]);
		return @h;
	}
}

sub color_DocView_html{
	my $self = shift;
	my $i    = $self->{color_DocView_html};
	unless ( defined($i) ){
		$i = "red,white,0";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		$h[2] = 0 unless defined($h[2]) && length($h[2]);
		return @h;
	}
}

sub color_DocView_CodeW{
	my $self = shift;
	my $i    = $self->{color_DocView_CodeW};
	unless ( defined($i) ){
		$i = "blue,white,1";
	}
	if ($_[1]){
		return $i;
	} else {
		my @h = split /,/, $i;
		$h[2] = 0 unless length($h[2]);
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

#---------------#
#   MySQL関連   #
#---------------#

sub sql_username{
	my $self = shift;
	my $new  = shift;
	
	if (defined($new) && length($new)){
		$self->{sql_username} = $new;
	}
	return $self->{sql_username};
}

sub sql_password{
	my $self = shift;
	my $new  = shift;
	
	if (defined($new) && length($new)){
		$self->{sql_password} = $new;
	}
	return $self->{sql_password};
}

sub sql_port{
	my $self = shift;
	my $new  = shift;
	
	if (defined($new) && length($new)){
		$self->{sql_port} = $new;
	}
	return $self->{sql_port};
}

sub sql_host{
	my $self = shift;
	my $new  = shift;
	
	if (defined($new) && length($new)){
		$self->{sql_host} = $new;
	}
	if ( defined($self->{sql_host}) ){
		return $self->{sql_host};
	} else {
		return 'localhost';
	}
}

sub sqllog{
	my $self = shift;
	my $new = shift;
	
	if ( defined($new) && length($new) ){
		$self->{sqllog} = $new;
	}

	return $self->{sqllog};
}

sub sqllog_file{
	my $self = shift;
	return "./config/sql.log";
}

#------------#
#   その他   #

sub all_in_one_pack{
	my $self = shift;
	return $self->{all_in_one_pack};
}

sub kaigyo_kigou{
	my $self = shift;
	my $new  = shift;
	
	# 新しい値を指定された場合
	if (defined($new)){
		$self->{kaigyo_kigou} = $new;
	}
	
	# デフォルト値
	unless ($self->{kaigyo_kigou}){
		return '（↓）';
	}
	
	return $self->{kaigyo_kigou};
}

sub R{
	my $self = shift;
	return $self->{R};
}

sub r_plot_debug{
	my $self = shift;
	my $new = shift;
	if ( defined($new) ){
		$self->{r_plot_debug} = $new;
	}
	
	if ( length($self->{r_plot_debug}) ){
		return $self->{r_plot_debug};
	} else {
		return 0;
	}
}

sub r_path{
	my $self = shift;
	my $new = shift;
	if ( length($new) && -e $new ){
		$self->{r_path} = $new;
	}
	return $self->{r_path};
}

sub r_dir{
	my $self = shift;
	if ( -e $self->{r_path} ) {
		if ( $self->{r_path} =~ /\A(.+)Rterm\.exe/i){
			my $v = $1;
			chop $v;
			chop $v;
			chop $v;
			chop $v;
			chop $v;
			return $v;
		}
	}
}

sub in_preprocessing{
	my $self = shift;
	my $new = shift;
	if ( length($new) ){
		$self->{in_preprocessing} = $new;
	}
	return $self->{in_preprocessing};
}

sub use_heap {
	my $self = shift;
	my $new = shift;
	
	if ( defined($new) && length($new) ){                     # 新しい値の指定
		$self->{use_heap} = $new;
	}
	unless (defined($self->{use_heap})){     # デフォルト値
		$self->{use_heap} = 1;
	}
	return $self->{use_heap};
}

sub mail_if{
	my $self = shift;
	my $new = shift;
	if ( defined($new) && length($new) ){
		$self->{mail_if} = $new;
	}
	return $self->{mail_if};
}

sub mail_smtp{
	my $self = shift;
	my $new = shift;
	if ( defined($new) ){
		$self->{mail_smtp} = $new;
	}
	return $self->{mail_smtp};
}

sub mail_from{
	my $self = shift;
	my $new = shift;
	if ( defined($new) ){
		$self->{mail_from} = $new;
	}
	return $self->{mail_from};
}

sub mail_to{
	my $self = shift;
	my $new = shift;
	if ( defined($new) ){
		$self->{mail_to} = $new;
	}
	return $self->{mail_to};
}

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
