use DBI;
use DBD::CSV;

my $dbh = DBI->connect("DBI:CSV:f_dir=./config");
my $sql2 = "SELECT * FROM hinshi_chasen";

my $h = $dbh->prepare($sql2);
$h->execute;

while (my $d = $h->fetch){
	print "$d->[0],$d->[1],$d->[2]\n";
}