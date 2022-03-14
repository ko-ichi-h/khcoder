# Insert "***not translated***" if the message is missing

use strict;
use YAML qw(LoadFile DumpFile);

local $YAML::Indent  = 4;

# Load standard messages: Japanese & English
my $msg_en = LoadFile('../config/msg.en') or die;
my $msg_jp = LoadFile('../config/msg.jp') or die;

# Files to check
my @chk= (
	'msg.cn',
	'msg.es',
	'msg.kr',
	'msg.fr',
);


foreach my $j (@chk){

	# load
	my $msg_ch = LoadFile('../config/'.$j) or die;
	
	# edit
	foreach my $i (sort keys %{$msg_en}){
		foreach my $h (sort keys %{$msg_en->{$i}}){
			my $ch = $msg_ch->{$i}{$h};
			
			if ( defined($ch) == 0 || $ch eq '***not translated***' ){
				print "missing: $i".'->'."$h, $msg_en->{$i}{$h}\n";
				$msg_ch->{$i}{$h} = '***not translated*** '.$msg_en->{$i}{$h}.' // '.$msg_jp->{$i}{$h};
			}
		}
	}
	
	# dump
	DumpFile('../config/'.$j, $msg_ch);
	
	# formatting
	my $t;
	open (my $fh, '<:utf8', '../config/'.$j) or die;
	while ( <$fh> ){
		if ($_ =~ /^    (\S+): (.+)\n/ ){
			my $n = 30 - (4 + 1);
			$n -= length($1);
			$n = 1 if $n < 1 ;
			$t .= "    $1:".' ' x $n."$2\n";
		} else {
			$t .= $_;
		}
	}
	close ($fh);
	
	open (my $fho, '>:utf8', '../config/'.$j) or die;
	print $fho $t;
	close ($fho);
	
	# check
	my $msg_ch = LoadFile('../config/'.$j) or die;
}