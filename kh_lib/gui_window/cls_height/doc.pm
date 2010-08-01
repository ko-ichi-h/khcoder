package gui_window::cls_height::doc;
use strict;
use base qw(gui_window::cls_height);


sub win_title{
	my $self = shift;
	return $self->gui_jt('文書のクラスター分析：併合水準','euc');
}

sub win_name{
	return 'w_doc_cls_height';
}

1;