# Copyright (c) 1995-2003 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package Tk::Clipboard;
use strict;

no warnings 'redefine';

use vars qw($VERSION);
$VERSION = sprintf '4.%03d', q$Revision: 1.3 $ =~ /\D(\d+)\s*$/;

use AutoLoader qw(AUTOLOAD);
use Tk qw(catch);

sub clipEvents
{
 return qw[Copy Cut Paste];
}

sub ClassInit
{
 my ($class,$mw) = @_;
 foreach my $op ($class->clipEvents)
  {
   $mw->Tk::bind($class,"<<$op>>","clipboard$op");
  }
 return $class;
}

sub clipboardSet
{
 my $w = shift;
 $w->clipboardClear;
 $w->clipboardAppend(@_);
}

sub clipboardCopy
{
 my $w = shift;
 my $val = $w->getSelected;
 if (defined $val)
  {
   $w->clipboardSet('--',$val);
  }
 return $val;
}

sub clipboardCut
{
 my $w = shift;
 my $val = $w->clipboardCopy;
 if (defined $val)
  {
   $w->deleteSelected;
  }
 return $val;
}

sub clipboardGet
{
 my $w = shift;
 
 my $chk = $w->SelectionGet('-selection','CLIPBOARD',@_);

 if ( ref($chk) eq 'ARRAY' ){
   # print "array\n";
   foreach my $i (@{$chk}){
     unless ( utf8::is_utf8($i) ){
       $i = Encode::decode('utf8', $i);
     }
   }
 }

 return $chk;
}

sub clipboardPaste
{
 my $w = shift;
 local $@;
 catch
  {
## Different from Tcl/Tk version:
#    if ($w->windowingsystem eq 'x11')
#     {
#      catch
#       {
#        $w->deleteSelected;
#       };
#     }
   $w->insert("insert", $w->clipboardGet);
   $w->SeeInsert if $w->can('SeeInsert');
  };
}

sub clipboardOperations
{
 my @class = ();
 my $mw    = shift;
 if (ref $mw)
  {
   $mw = $mw->DelegateFor('bind');
  }
 else
  {
   push(@class,$mw);
   $mw = shift;
  }
 while (@_)
  {
   my $op = shift;
   $mw->Tk::bind(@class,"<<$op>>","clipboard$op");
  }
}

# These methods work for Entry and Text
# and can be overridden where they don't work

sub deleteSelected
{
 my $w = shift;
 catch { $w->delete('sel.first','sel.last') };
}


1;
__END__

sub getSelected
{
 my $w   = shift;
 my $val = Tk::catch { $w->get('sel.first','sel.last') };
 return $val;
}


