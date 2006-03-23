package kh_at;

use strict;
use Text::Diff;
use kh_at::project_new;
use kh_at::pretreatment;
use kh_at::words;

sub exec_test{
	my $class = shift;
	my $self;
	$self->{file_base} = shift;
	bless $self, $class;
	
	$self->_exec_test;
	$self->_write_result;
	$self->_check_output;
	
	return 1;
}

sub _check_output{
	my $self = shift;
	print $self->test_name." ";
	
	my $diff = diff(
		$self->file_test_output,
		$self->file_test_ref,
		{ STYLE => 'Context' }
	);
	
	if ($diff){
		print "NG\n";
		my $file = $self->file_test_output.'_diff.txt';
		open(OUT,">$file") or die;
		print OUT $diff;
		close (OUT);
	} else {
		print "OK\n";
	}
	
	return 1;
}

sub _write_result{
	my $self = shift;
	my $out_file = $self->file_test_output;
	
	$self->{result} =~ s/\r//go;
	
	open (OUTF,">$out_file") or die;
	print OUTF $self->{result};
	close (OUTF);
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

sub file_test_output{
	my $self = shift;
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/'.$self->{file_base}.'.txt';
	return $file;
}

sub file_test_ref{
	my $self = shift;
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/data_ref/'.$self->{file_base}.'.txt';
	return $file;
}

1;