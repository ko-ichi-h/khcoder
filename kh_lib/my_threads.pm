package my_threads;

use strict;
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


sub worker_thread{
	print "ok\n";
    
    while (1) {
        sleep 0.25;
        #print "w ";
        last if $shared_die1;
        if ($shared_flag1){
             eval( $shared_text1 );
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
		sleep 0.25;
		last if $shared_flag1 == 0;
	}
	
	$shared_text1 = shift;
	$shared_flag1 = 1;
	return 1;
}

sub wait{
	while ($shared_flag1 == 1){
		print "Waiting for the worker thread...\n";
		sleep 0.25;
		last if $shared_flag1 == 0;
	}
	return 1;
}

1;