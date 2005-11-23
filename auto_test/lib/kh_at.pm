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

#--------------#
#   アクセサ   #

sub file_testdata{
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/data_input/kokoro2.txt';
	return $file;
}


1;