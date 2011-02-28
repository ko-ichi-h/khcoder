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

my $que1 = new Thread::Queue;
my $cur1 :shared = '';

my $que2 = new Thread::Queue;
my $cur2 :shared = '';

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
		$cur1 = 1;
		#my $t0 = new Benchmark;
		eval( $cmd );
		if ($@){
			die("Error in the thread: $@\n");
		}
		
		#my $t1 = new Benchmark;
		#print "Worker: Done: \t",timestr(timediff($t1,$t0)),"\n";
		$cur1 = 0;
	}
}

sub worker_thread2{
	while ( my $cmd = $que2->dequeue() ) {
		$cur2 = 1;
		#my $t0 = new Benchmark;
		eval( $cmd );
		if ($@){
			die("Error in the thread: $@\n");
		}
		#my $t1 = new Benchmark;
		#print "Worker: Done: \t",timestr(timediff($t1,$t0)),"\n";
		$cur2 = 0;
	}
}

sub exec1{
	$cur1 = 1;
	my $class = shift;
	my $cmd   = shift;
	$que1->enqueue($cmd);
	return 1;
}

sub exec2{
	$cur2 = 1;
	my $class = shift;
	my $cmd   = shift;
	$que2->enqueue($cmd);
	return 1;
}


sub wait1{
	print "Worker1: Waiting...\n";
	my $t0 = new Benchmark;
	while ($que1->pending > 0 || $cur1 ){
		sleep 0.1;
		last if $que1->pending == 0 && $cur1 == 0;
	}
	my $t1 = new Benchmark;
	print "Worker1: Wainting: Done: ", timestr(timediff($t1,$t0)), "\n";
	return 1;
}

sub wait2{
	print "Worker2: Waiting...\n";
	my $t0 = new Benchmark;
	while ($que2->pending > 0 || $cur2 ){
		sleep 0.1;
		last if $que2->pending == 0 && $cur2 == 0;
	}
	my $t1 = new Benchmark;
	print "Worker2: Wainting: Done: ", timestr(timediff($t1,$t0)), "\n";
	return 1;
}

sub que_any1_enqueue{
	my $class = shift;
	my $d     = shift;
	
	$que_any1->enqueue($d);
	return 1;
}

1;