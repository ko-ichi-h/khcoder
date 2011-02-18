package my_threads;

use strict;
use Benchmark;
use threads;
use threads::shared;
use Thread::Queue;
use Time::HiRes qw(sleep);

my $que = new Thread::Queue;
my $cur :shared = '';

sub init{
	print "starting worker threads...";
	my $thread1 = threads->new(\&worker_thread);
	$thread1->detach();
	return 1;
}

# Worker Thread用にMySQLにコネクトし直しておく
sub open_project{
	my $dbname = $::project_obj->dbname;
	my $cmd = 
		'undef $::project_obj;'."\n"
		.'$::project_obj->{dbh} = mysql_exec->connect_db("'.$dbname.'");'."\n"
		.'bless $::project_obj, "kh_project"'."\n";
	my_threads->exec($cmd);
}

sub worker_thread{
	print "ok\n";
	while ( $cur = $que->dequeue() ) {
		#my $t0 = new Benchmark;
		eval( $cur );
		#my $t1 = new Benchmark;
		#print "Worker: Done: \t",timestr(timediff($t1,$t0)),"\n";
		$cur = '';
	}
}

sub exec{
	my $class = shift;
	my $cmd   = shift;
	$que->enqueue($cmd);
	return 1;
}

sub wait{
	print "Worker: Waiting...\n";
	my $t0 = new Benchmark;
	while ($que->pending > 0 || length($cur) > 0 ){
		sleep 0.1;
		last if $que->pending == 0 && length($cur) == 0;
	}
	my $t1 = new Benchmark;
	print "Worker: Wainting: Done: ", timestr(timediff($t1,$t0)), "\n";
	return 1;
}

1;