use Thread;

my $t = new Thread \&thread1;

for (my $i = 1; $i <= 1000; ++$i){
	print "n ";
}





sub thread1{
	for (my $i = 1; $i <= 1000; ++$i){
		print "1 ";
	}
}