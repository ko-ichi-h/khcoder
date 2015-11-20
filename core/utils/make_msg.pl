use strict;
use Encode;
use utf8;

my $file_in = "lang3.txt";
my $file_out = "msg.kr";

my $t;

open(my $fh, '<:encoding(utf8)', $file_in) or die;
while (<$fh>) {
    chomp;
    my @line = split /\t/, $_;
    $t->{$line[0]}{$line[1]} = $line[2];
}
close ($fh);

use YAML;

open(my $fh_out, '>:encoding(utf8)', $file_out) or die;
print $fh_out Dump($t);
close ($fh_out);
