require Encode;

my $alpha = "\x{3b1}";

Encode::encode(undef , $alpha);

print $alpha;