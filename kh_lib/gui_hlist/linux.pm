package gui_hlist::linux;
use base qw(gui_hlist);
use strict;

sub _copy{
	gui_errormsg->open(
		msg => 'Linux上でのコピーは現在サポートしていません。',
		type => 'msg',
	);
}
1;