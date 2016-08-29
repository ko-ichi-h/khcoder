# UCS-2LE:code point "\x{20541}" too high at C:/apps/Perl/site/lib/Tk/Widget.pm line 205. at tk_utf8.pl line 9

#!/usr/bin/perl
use strict;
use warnings;
use Tk;

my $mw = MainWindow->new;
my $text = "\x{1F642}";

$mw->Label(-text => $text)->pack;

MainLoop;
