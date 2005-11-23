package kh_at;
use strict;

use kh_at::project_new;

sub exec_test{
	my $self;
	$self->{win_obj} = '';
	my $class = shift;
	bless $self, $class;
	$self->_exec_test;
	return 1;
}

sub check_output{
	print "Nothing to check!\n";
	return 1;
}

#--------------------------------#
#   テスト用プロジェクトの操作   #

sub close_test_project{
	$::main_gui->{menu}->mc_close_project;
}

sub open_test_project{
	gui_window::project_open->open;
	my $win_opn = $::main_gui->get('w_open_pro');
	my $n = @{$win_opn->projects->list} - 1;
	$win_opn->{g_list}->selectionClear(0);
	$win_opn->{g_list}->selectionSet($n);
	$win_opn->_open;
}

sub delete_test_project{
	gui_window::project_open->open;
	my $win_opn = $::main_gui->get('w_open_pro');
	my $n = @{$win_opn->projects->list} - 1;
	$win_opn->{g_list}->selectionClear(0);
	$win_opn->{g_list}->selectionSet($n);
	$win_opn->delete;
	$win_opn->close;
}

#--------------#
#   アクセサ   #

sub file_testdata{
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/data_input/kokoro2.txt';
	return $file;
}


1;