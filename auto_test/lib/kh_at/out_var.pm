package kh_at::out_var;
use base qw(kh_at);
use strict;

sub _exec_test{
	my $self = shift;
	
	# 外部変数の読み込み
	my $win = gui_window::outvar_read::csv->open;
	$win->{entry}->insert(0, $self->file_outvar );
	$win->{tani_obj}->{raw_opt} = 'dan';
	$win->{tani_obj}->mb_refresh;
	$win->_read;

	# 読み込み結果のチェック



	return $self;
}

sub test_name{
	return 'Read & Edit Variables...';
}


1;