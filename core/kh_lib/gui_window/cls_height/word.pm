package gui_window::cls_height::word;
use strict;
use base qw(gui_window::cls_height);

sub win_title{
	my $self = shift;
	return $self->gui_jt('抽出語のクラスター分析：併合水準','euc');
}

sub win_name{
	return 'w_word_cls_height';
}

1;