use strict;
use Cwd;

# Edit configurations of KH Coder
my $file_setup = cwd.'/config/coder.ini';
my %config =();

open (my $fh, '<', $file_setup) or die("could not read file: $file_setup\n");
while (<$fh>){
	chomp;
	my @temp = split /\t/, $_;
	$config{$temp[0]} = $temp[1] if length($temp[0]);
}
close ($fh);

$config{chasenrc_path}     = cwd.'/deps/ipadic-2.7.0/chasenrc';
$config{grammarcha_path}   = cwd.'/deps/ipadic-2.7.0/grammar.cha';
$config{stanf_jar_path}    = cwd.'/deps/stanford-postagger/stanford-postagger.jar';
$config{stanf_tagger_path} = cwd.'/deps/stanford-postagger/models/left3words-wsj-0-18.tagger';
$config{sql_username}      = 'root';
$config{sql_password}      = 'khc';
$config{sql_host}          = '127.0.0.1';
$config{sql_port}          = '3308';
$config{c_or_j}            = 'chasen';
$config{all_in_one_pack}   = 1;
$config{app_html}          = 'open %s &';
$config{app_csv}           = 'open %s &';
$config{app_pdf}           = 'open %s &';
$config{font_main}         = 'Hiragino Kaku Gothic ProN,-13';

open (my $fh, '>', $file_setup) or die("could not write file: $file_setup\n");
foreach my $i (keys %config){
	print $fh "$i\t$config{$i}\n";
}
close ($fh);

# Edit configurations of R
my $file_r = cwd.'/deps/R-3.1.0/Versions/3.1/Resources/bin/R';
my $r_home = cwd.'/deps/R-3.1.0/Resources';

my $r;
open (my $fh, '<', $file_r) or die("could not read file: $file_r\n");
{
	local $/ = undef;
	$r = <$fh>;
}
close ($fh);

$r =~ s/\nR_HOME_DIR=\/.+?\n/\nR_HOME_DIR=$r_home\n/;

open (my $fh, '>', $file_r) or die("could not write file: $file_r\n");
print $fh $r;
close ($fh);

# Edit configurations of MySQL

my $file_mysql = cwd.'/deps/mysql-5.6.17/khc.cnf';
my $mysal_b = cwd.'/deps/mysql-5.6.17';
my $mysal_d = cwd.'/deps/mysql-5.6.17/data';

my $cnf;
open (my $fh, '<', $file_mysql) or die("could not read file: $file_mysql\n");
{
	local $/ = undef;
	$cnf = <$fh>;
}
close ($fh);

$cnf =~ s/\nbasedir = .+?\n/\nbasedir = $mysal_b\n/;
$cnf =~ s/\ndatadir = .+?\n/\ndatadir = $mysal_d\n/;

open (my $fh, '>', $file_mysql) or die("could not write file: $file_mysql\n");
print $fh $cnf;
close ($fh);

print "You are ready to run kh_coder.app!\n";