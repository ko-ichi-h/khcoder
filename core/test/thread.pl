use Parallel::ForkManager;
$pm = new Parallel::ForkManager(5);
for (my $i = 0; $i <= 2; ++$i){
	$pm->start and next;
	if ($i){
		&print_a;
	} else {
		&print_b;
	}
	$pm->finish;
}



sub print_a{
	for (my $n = 0; $n <= 10; ++$n){
		print "a";
		sleep 1;
	}
}

sub print_b{
	for (my $n = 0; $n <= 10; ++$n){
		print "b";
		sleep 2;
	}
}