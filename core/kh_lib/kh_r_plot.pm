package kh_r_plot;
use strict;

my $if_font = 0;

sub new{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	return undef unless $::config_obj->R;
	
	# ファイル名
	my $icode = Jcode::getcode($::project_obj->dir_CoderData);
	my $dir   = Jcode->new($::project_obj->dir_CoderData, $icode)->euc;
	$dir =~ tr/\\/\//;
	$dir = Jcode->new($dir,'euc')->$icode unless $icode eq 'ascii';
	$self->{path} = $dir.$self->{name};
	unlink($self->{path}) if -e $self->{path};
	
	# コマンドの文字コード
	$self->{command_f} = Jcode->new($self->{command_f})->sjis
		if $::config_obj->os eq 'win32';
	$self->{command_a} = Jcode->new($self->{command_a})->sjis
		if $::config_obj->os eq 'win32' and length($self->{command_a});
	my $command = '';
	
	if (length($self->{command_a})){
		$command = $self->{command_a};
		#print "com_a: $command\n";
	} else {
		$command = $self->{command_f};
	}
	
	# Linux用フォント設定
	if ( ($::config_obj->os ne 'win32') and ($if_font == 0) ){
		system('xset fp rehash');
		
		# R 2.7以降の場合はこのコマンドではだめかも？
		$::config_obj->R->send(
			 'options(X11fonts = c('
			.'"-*-gothic-%s-%s-normal--%d-*-*-*-*-*-*-*",'
			.'"-adobe-symbol-*-*-*-*-%d-*-*-*-*-*-*-*"))'
		);
		
		$if_font = 1;
	}

	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$self->{path} = $::config_obj->R_device(
		$self->{path},
		$self->{width},
		$self->{height},
	);
	$::config_obj->R->send($command);
	$self->{r_msg} = $::config_obj->R->read;
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	# 結果のチェック
	if (
		not (-e $self->{path})
		or ( $self->{r_msg} =~ /error/i )
		or ( index($self->{r_msg},'エラー') > -1 )
		or ( index($self->{r_msg},Jcode->new('エラー','euc')->sjis) > -1 )
	) {
		gui_errormsg->open(
			type   => 'msg',
			window  => \$::main_gui->mw,
			msg    => "推定または描画に失敗しました\n\n".$self->{r_msg}
		);
		return 0;
	}
	
	
	return $self;
}

sub r_msg{
	my $self = shift;
	return $self->{r_msg};
}

sub path{
	my $self = shift;
	return $self->{path};
}

sub save{
	my $self = shift;
	my $path = shift;
	
	my $icode = Jcode::getcode($path);
	$path = Jcode->new($path, $icode)->euc;
	$path =~ tr/\\/\//;
	$path = Jcode->new($path,'euc')->$icode unless $icode eq 'ascii';
	
	if ($path =~ /\.r$/i){
		$self->_save_r($path);
	}
	elsif ($path =~ /\.png$/i){
		$self->_save_png($path);
	}
	elsif ($path =~ /\.eps$/i){
		$self->_save_eps($path);
	}
	elsif ($path =~ /\.pdf$/i){
		$self->_save_pdf($path);
	}
	elsif ($path =~ /\.emf$/i){
		$self->_save_emf($path);
	}
	else {
		warn "The file type is not supported yet:\n$path\n";
	}
}

sub _save_emf{
	my $self = shift;
	my $path = shift;
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send(
		 "win.metafile(filename=\"$path\", width = 7, height = 7 )"
	);
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_pdf{
	my $self = shift;
	my $path = shift;
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send(
		 "pdf(file=\"$path\", height = 7, width = 7,"
		."family=\"Japan1GothicBBB\")"
	);
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}


sub _save_eps{
	my $self = shift;
	my $path = shift;
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send(
		 "postscript(\"$path\", horizontal = FALSE, onefile = FALSE,"
		."paper = \"special\", height = 7, width = 7,"
		."family=\"Japan1GothicBBB\" )"
	);
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_png{
	my $self = shift;
	my $path = shift;
	
	$self->{width}  = 480 unless $self->{width};
	$self->{height} = 480 unless $self->{height};
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$::config_obj->R->send(
		 "png(\"$path\", width=$self->{width},"
		."height=$self->{height}, unit=\"px\")"
	);
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return 1;
}

sub _save_r{
	my $self = shift;
	my $path = shift;
	
	open (OUTF,">$path") or 
		gui_errormsg->open(
			type    => 'file',
			thefile => $path,
		);
	print OUTF $self->{command_f},"\n";
	close (OUTF);
	
	return 1;
}

sub command_f{
	my $self = shift;
	return $self->{command_f};
}

1;