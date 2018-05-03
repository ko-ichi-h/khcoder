# KH Coder‚Ì‰æ–Ê‚Ì“ú‰p‘ÎÆ•\ilang.txtj‚ðì‚é

use strict;
use YAML qw(LoadFile);

my $msg_jp = LoadFile('../config/msg.jp') or die;
my $msg_en = LoadFile('../config/msg.en') or die;

open (my $fh, '>:encoding(UTF-8)', 'lang.txt') or die;

foreach my $i (sort keys %{$msg_en}){
	foreach my $h (sort keys %{$msg_en->{$i}}){
		my $en = $msg_en->{$i}{$h};
		my $jp = $msg_jp->{$i}{$h};
		
		$en =~ s/\n|\t/ /g;
		$jp =~ s/\n|\t/ /g;
		
		print $fh "$jp\t$en\t$i\t$h\n";
	}
}