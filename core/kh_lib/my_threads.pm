package my_threads;

use strict;
use Benchmark;
use threads;
use threads::shared;
use Time::HiRes qw(sleep);

my $thread1;
my $shared_text1: shared = "";
my $shared_flag1: shared = 0;

sub init{
	print "starting worker threads...";
	$thread1 = threads->new(\&worker_thread);
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
    
    while (1) {
        sleep 0.1;
        # print "w ";
        # last if $shared_die1;
        if ($shared_flag1){
            my $t0 = new Benchmark;
            eval( $shared_text1 );
            my $t1 = new Benchmark;
            print "Worker:\t",timestr(timediff($t1,$t0)),"\n";
             if (length($@)){
             	die("Error in eval block of Worker thread:\n$@\n");
             }
             $shared_text1 = "";
             $shared_flag1 = 0;
        }
    }

}

sub exec{
	my $class     = shift;
	
	while ($shared_flag1 == 1){
		print "Waiting for the worker thread...\n";
		sleep 0.1;
		last if $shared_flag1 == 0;
	}
	
	$shared_text1 = shift;
	$shared_flag1 = 1;
	return 1;
}

sub wait{
	print "Worker: Waiting...\n";
	while ($shared_flag1 == 1){
		sleep 0.1;
		last if $shared_flag1 == 0;
	}
	print "Worker: Done.\n";
	return 1;
}

1;