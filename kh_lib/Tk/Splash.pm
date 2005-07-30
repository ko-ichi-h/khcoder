# -*- perl -*-

#
# $Id: Splash.pm,v 1.2 2005-07-30 21:27:17 ko-ichi Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1999 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
# Modified by Higuchi, K. 2001 09/13 01:35 (JST), Line 29 is added.

package Tk::Splash;
use Tk;
use strict;
use vars qw($VERSION @ISA);

$VERSION = 0.03;

@ISA = qw(Tk::Widget);

sub Show {
    my($pkg, $image_file, $image_width, $image_height, $title) = @_;
    $title = $0 if !defined $title;
    my $splash_screen = {};
    $splash_screen = new MainWindow;
    $splash_screen->overrideredirect(1); # add by Higuchi, K.
    $splash_screen->title($title);
    my $splashphoto = $splash_screen->Photo(-file => $image_file);
    my $sw = $splash_screen->screenwidth;
    my $sh = $splash_screen->screenheight;
    $image_width  = $splashphoto->width unless defined $image_width;
    $image_height = $splashphoto->height unless defined $image_height;
    $splash_screen->geometry("+" . int($sw/2 - $image_width/2) .
			     "+" . int($sh/2 - $image_height/2));
    my $l = $splash_screen->Label(-image => $splashphoto)->pack
      (-fill => 'both', -expand => 1);
    $splash_screen->update;
    $splash_screen->{"Exists"} = 1;
    bless $splash_screen, $pkg;
}

sub Raise {
    my $w = shift;
    if ($w->{"Exists"}) {
	Tk::catch { Tk::raise($w) };
    }
}

sub Destroy {
    my $w = shift;
    if ($w->{"Exists"}) {
	#Tk::catch { Tk::destroy($w) };
	Tk::destroy($w);
    }
}

1;

=head1 NAME

Tk::Splash - create a splash screen in a compatible way

=head1 SYNOPSIS

    BEGIN {
        require Tk::Splash;
        $splash = Tk::Splash->Show($image, $width, $height, $title);
    }
    ...
    use Tk;
    ...
    $splash->Destroy;
    MainLoop;

=head1 DESCRIPTION

This module is another way to create a splash screen. It is slower
than B<Tk::FastSplash>, but tries to be compatible by using standard
Tk methods for creation.

The arguments to the B<Show> are the same as in
L<Tk::FastSplash|Tk::FastSplash>. C<$width> and C<$height> are purely
optional and only here for compatibility with B<Tk::FastSplash>. For
further documentation, see L<Tk::FastSplash>.

=head1 NOTES

Since displaying the splash screen is done during compile time, the
splash screen will also occur if the script is started using perl's C<-c>
(check) switch.

=head1 AUTHOR

Slaven Rezic

=head1 SEE ALSO

L<Tk::FastSplash>

=cut

__END__
