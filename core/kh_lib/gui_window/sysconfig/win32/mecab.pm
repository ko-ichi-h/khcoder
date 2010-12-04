package gui_window::sysconfig::win32::mecab;
use base qw(gui_window::sysconfig::win32);

sub gui_switch{
	my $self = shift;
	$self->entry1->configure(-state => 'disable');
	$self->btn1->configure(-state => 'disable');
	$self->lb1->configure(-state => 'disable');
	
	$self->entry2->configure(-state => 'normal');
	$self->btn2->configure(-state => 'normal');
	$self->lb2->configure(-state => 'normal');
}

sub open_msg{
	return 'MeCab.exeを開いてください';
}
sub entry{
	my $self = shift;
	return $self->entry2;
}

1;

__END__
