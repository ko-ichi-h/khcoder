# UCS-2LE:code point "\x{20541}" too high at C:/apps/Perl/site/lib/Tk/Widget.pm line 205. at tk_utf8.pl line 9

#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use utf8;

my $mw = MainWindow->new;

$mw->fontCreate('TKFN',
	-family => 'Unifont',
	-size   => 50,
);
$mw->optionAdd('*font','TKFN');


my $text = '😂';

$mw->Label(-text => $text)->pack;

MainLoop;
