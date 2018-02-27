use Win32::SystemInfo;

my %mHash;
Win32::SystemInfo::MemoryStatus(%mHash,"MB");

foreach my $i (keys %mHash) {
	print "$i: $mHash{$i}\n";
}