package kh_at::project_new;
use base qw(kh_at);
use strict;

sub _exec_test{
	my $self = shift;
	
	# Windowを開く
	gui_window::project_new->open;
	my $win_obj = $::main_gui->get('w_new_pro');
	$self->{win_obj} = $win_obj;

	# テスト処理実行
	$win_obj->{e1}->insert(0,gui_window->gui_jchar($self->file_testdata));
	$win_obj->{e2}->insert(0,gui_window->gui_jchar('自動テスト用Project'));
	
	$win_obj->{ok_btn}->invoke;
	
	return $self;
}



1;