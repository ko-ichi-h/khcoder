package kh_at::docs;
use base qw(kh_at);
use strict;

sub _exec_test{
	my $self = shift;

	my $win = gui_window::morpho_crossout::csv->open;
	



	print "ok?\n";

	#unlink($self->file_out_tmp_base."_pc1.txt") or die;
	#unlink($self->file_out_tmp_base."_pc2.txt") or die;

	return $self;
}

sub test_name{
	return 'docs...';
}

1;