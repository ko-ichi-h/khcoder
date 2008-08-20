package kh_r_plot;
use strict;

sub new{
	my $class = shift;
	my %args = @_;
	my $self = \%args;
	bless $self, $class;
	
	return undef unless $::config_obj->R;
	
	# フォルダ名
	my $icode = Jcode::getcode($::project_obj->dir_CoderData);
	my $dir   = Jcode->new($::project_obj->dir_CoderData, $icode)->euc;
	$dir =~ tr/\\/\//;
	$dir = Jcode->new($dir,'euc')->$icode unless $icode eq 'ascii';
	$self->{path} = $dir.$self->{name};
	
	# プロット作成
	$::config_obj->R->output_chk(0);
	$::config_obj->R->lock;
	$self->{path} = $::config_obj->R_device($self->{path});
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	$::config_obj->R->unlock;
	$::config_obj->R->output_chk(1);
	
	return $self;
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
	
	if ($path =~ /\.r$/){
		$self->_save_r($path);
	}
	else {
		warn "The file type is not supported yet:\n$path\n";
	}
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


1;