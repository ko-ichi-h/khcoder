package my_threads::single;

use strict;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(&init &open_project &exec1 &exec2 &wait1 &wait2);

sub init{
	print "Using un-threaded functions...\n" unless $::config_obj->web_if;
	return 1;
}

sub open_project{
	return 1;
}

sub exec1{
	my $class = shift;
	my $cmd   = shift;
	eval( $cmd );
	if ($@){
		die("Error in the thread (s): $@\n");
	}
	return 1;
}

sub exec2{
	my $class = shift;
	my $cmd   = shift;
	eval( $cmd );
	if ($@){
		die("Error in the thread (s): $@\n");
	}
	return 1;
}

sub wait1{
	return 1;
}

sub wait2{
	return 1;
}

1;