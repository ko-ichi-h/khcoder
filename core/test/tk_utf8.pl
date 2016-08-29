# UCS-2LE:code point "\x{20541}" too high at C:/apps/Perl/site/lib/Tk/Widget.pm line 205. at tk_utf8.pl line 9

use strict;use warnings;
use utf8;
use Tk;

my $mw = MainWindow->new;
my $text = "𠕁"; #A Chinese character

eval{
    $mw->Label(-text => $text)->pack;
};
warn $@ if $@;

MainLoop;