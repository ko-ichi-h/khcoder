package my_threads;

use strict;
use Config;

BEGIN{
	if ( $Config{useithreads} ){
		require my_threads::multi;
		import  my_threads::multi;
	} else {
		require my_threads::single;
		import  my_threads::single;
	}
}

*exec = \&exec1;
*wait = \&wait1;

1;