use DBI;
use DBD::mysql;

my $db = DBI->connect(
	"DBI:mysql:database=mysql;127.0.0.1;port=3306;mysql_local_infile=1",
	user_name,
	password,
	{mysql_enable_utf8 => 1}
);

my $h = $db->prepare("show variables like \"%character%\"");
$h->execute;

while( $i = $h->fetch ){
	print "$i->[0]\t$i->[1]\n";
}
