package my_threads;

use strict;
use Benchmark;
use threads;
use threads::shared;
use Thread::Queue;
use Thread::Queue::Any;
use Time::HiRes qw(sleep);

my $que1 = new Thread::Queue;
my $cur1 :shared = '';

my $que2 = new Thread::Queue;
my $cur2 :shared = '';

use vars qw($que_any1 %IDs);
$que_any1 = new Thread::Queue;
share(%IDs);

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
		.'$::project_obj->{dbh} = mysql_exec->connect_db("'.$dbname.'");'."\n"
		.'bless $::project_obj, "kh_project"'."\n";
	my_threads->exec1($cmd);
	my_threads->exec2($cmd);
}

sub worker_thread1{
	while ( $cur1 = $que1->dequeue() ) {
		#my $t0 = new Benchmark;
		eval( $cur1 );
		if ($@){
			die("Error in the thread: $@\n");
		}
		
		#my $t1 = new Benchmark;
		#print "Worker: Done: \t",timestr(timediff($t1,$t0)),"\n";
		$cur1 = '';
	}
}

sub worker_thread2{
	while ( $cur2 = $que2->dequeue() ) {
		#my $t0 = new Benchmark;
		eval( $cur2 );
		if ($@){
			die("Error in the thread: $@\n");
		}
		#my $t1 = new Benchmark;
		#print "Worker: Done: \t",timestr(timediff($t1,$t0)),"\n";
		$cur2 = '';
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
	print "Worker1: Waiting...\n";
	my $t0 = new Benchmark;
	while ($que1->pending > 0 || length($cur1) > 0 ){
		sleep 0.1;
		last if $que1->pending == 0 && length($cur1) == 0;
	}
	my $t1 = new Benchmark;
	print "Worker1: Wainting: Done: ", timestr(timediff($t1,$t0)), "\n";
	return 1;
}

sub wait2{
	print "Worker2: Waiting...\n";
	my $t0 = new Benchmark;
	while ($que2->pending > 0 || length($cur2) > 0 ){
		sleep 0.1;
		last if $que2->pending == 0 && length($cur2) == 0;
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

*exec = \&exec1;
*wait = \&wait1;

1;