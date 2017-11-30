package my_threads::multi;

use strict;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(&init &open_project &exec1 &exec2 &wait1 &wait2 &que_any1_enqueue);

use threads;
use threads::shared;
use Thread::Queue;
use Thread::Queue::Any;
use Benchmark;
use Time::HiRes qw(sleep);

use vars qw($que1 $que2 $cur1 $cur2);
$que1 = new Thread::Queue;
$que2 = new Thread::Queue;
share $cur1;
share $cur2;

use vars qw($que_any1);
$que_any1 = new Thread::Queue::Any;

# Worker Threadを2つ起動しておく
sub init{
	print "Starting worker threads...\n";
	my $thread1 = threads->new(\&worker_thread1);
	$thread1->detach();
	my $thread2 = threads->new(\&worker_thread2);
	$thread2->detach();
	return 1;
}

# Worker Thread用にMySQLにコネクトし直しておく
sub open_project{
	my $dbname = $::project_obj->dbname;
	my $cmd = 
		'undef $::project_obj;'."\n"
		.'$::project_obj->{dbh} = mysql_exec->connect_db("'.$dbname.'",1);'."\n"
		.'bless $::project_obj, "kh_project"'."\n";
	my_threads->exec1($cmd);
	my_threads->exec2($cmd);
}

sub worker_thread1{
	while ( my $cmd = $que1->dequeue() ) {
		#my $t0 = new Benchmark;
		#print "cmd: $cmd\n";
		eval( $cmd );
		if ($@){
			die("Error in the thread: $@\n");
		}
		#my $t1 = new Benchmark;
		#print "Worker: Done: \t",timestr(timediff($t1,$t0)),"\n";
	}
}

sub worker_thread2{
	while ( my $cmd = $que2->dequeue() ) {
		#my $t0 = new Benchmark;
		eval( $cmd );
		if ($@){
			die("Error in the thread: $@\n");
		}
		#my $t1 = new Benchmark;
		#print "Worker: Done: \t",timestr(timediff($t1,$t0)),"\n";
	}
}

sub exec1{
	my $class = shift;
	my $cmd   = shift;
	$que1->enqueue($cmd);
	return 1;
}

sub exec2{
	my $class = shift;
	my $cmd   = shift;
	$que2->enqueue($cmd);
	return 1;
}


sub wait1{
	my $t0 = new Benchmark;
	$cur1 = 1;
	$que1->enqueue('$cur1 = 0;');

	#print "Worker1: Waiting...\n";
	while ($cur1){
		sleep 0.1;
	}
	my $t1 = new Benchmark;
	print "Worker1: Done: ", timestr(timediff($t1,$t0)), "\n";
	return 1;
}

sub wait2{
	my $t0 = new Benchmark;
	$cur2 = 1;
	$que2->enqueue('$cur2 = 0;');

	#print "Worker2: Waiting...\n";
	while ($cur2){
		sleep 0.1;
	}
	my $t1 = new Benchmark;
	print "Worker2: Done: ", timestr(timediff($t1,$t0)), "\n";
	return 1;
}

sub que_any1_enqueue{
	my $class = shift;
	my $d     = shift;
	
	$que_any1->enqueue($d);
	return 1;
}

1;