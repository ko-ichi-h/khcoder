#!/usr/local/bin/perl -w
# -*- perl -*-

#
# $Id: FontDialog_kh.pm,v 1.1 2005-05-21 13:15:43 ko-ichi Exp $
# Author: Slaven Rezic
#
# Copyright (C) 1998,1999,2003,2004 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Tk::FontDialog;

use Tk 800; # new font function, Tk::ItemStyle

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(Tk::Toplevel);

Construct Tk::Widget 'FontDialog';

$VERSION = '0.09';

sub Populate {
    my($w, $args) = @_;

    require Tk::HList;
    require Tk::ItemStyle;

    $w->SUPER::Populate($args);
    $w->protocol('WM_DELETE_WINDOW' => ['Cancel', $w ]);

    $w->withdraw;

    if (exists $args->{-font}) {
	$w->optionAdd('*font' => delete $args->{-font});
    }
    my $dialog_font;
    my $font_name = $w->optionGet("font", "*");
    if (!defined $font_name) {
	my $l = $w->Label;
	$dialog_font = $w->fontCreate($w->fontActual($l->cget(-font)));
	$l->destroy;
    } else {
	$dialog_font = $w->fontCreate($w->fontActual($font_name));
    }
    if (exists $args->{-initfont}) {
	$w->{'curr_font'} = $w->fontCreate($w->fontActual
					   (delete $args->{-initfont}));
    } else {
	$w->{'curr_font'} = $dialog_font;
    }

    my $bold_font       = $w->fontCreate($w->fontActual($dialog_font),
					 -weight => 'bold');
    #my $italic_font     = $w->fontCreate($w->fontActual($dialog_font),
	#				 -slant => 'italic');
    #my $underline_font  = $w->fontCreate($w->fontActual($dialog_font),
	#				 -underline => 1);
    #my $overstrike_font = $w->fontCreate($w->fontActual($dialog_font),
	#				 -overstrike => 1);

    my $f1     = $w->Frame->pack(-expand => 1, -fill => 'both',
				 -padx => 2, -pady => 2);
    my $ffam   = $f1->Frame->pack(-expand => 1, -fill => 'both',
				  -side => 'left');
    my $fsize  = $f1->Frame->pack(-expand => 1, -fill => 'both',
				  -side => 'left');
    #my $fstyle = $f1->Frame->pack(-expand => 1, -fill => 'both',
	#			  -side => 'left');

    my(%family_res) = _get_label(delete $args->{'-familylabel'}
				 || '~Family:');
    $ffam->Label
      (@{$family_res{'args'}},
       -font => $bold_font,
      )->pack(-anchor => 'w');

    my $famlb = $ffam->Scrolled
      ('HList',
       -scrollbars => 'osoe',
       -selectmode => 'single',
       -bg => 'white',
       -browsecmd => sub {
	   my $family = $w->{'family_index'}[$_[0]];
	   $w->UpdateFont(-family => $family)
       },
      )->pack(-expand => 1, -fill => 'both', -anchor => 'w');
    $w->Advertise('family_list' => $famlb);

    my(%size_res) = _get_label(delete $args->{'-sizelabel'}
			       || '~Size:');
    $fsize->Label
      (@{$size_res{'args'}},
       -font => $bold_font,
      )->pack(-anchor => 'w');

    my $sizelb = $fsize->Scrolled
      ('HList',
       -scrollbars => 'oe',
       -width => 3,
       -bg => 'white',
       -selectmode => 'single',
       -browsecmd => sub { $w->UpdateFont(-size => $_[0]) },
      )->pack(-expand => 1, -fill => 'both', -anchor => 'w');
    $w->Advertise('size_list' => $sizelb);
    $sizelb->bind("<3>" => [ $w, '_custom_size' ]);

    my @fontsizes;
    if (exists $args->{-fontsizes}) {
	@fontsizes = @{ delete $args->{-fontsizes} };
    } else {
	@fontsizes = qw(0 2 3 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22
			23 24 25 26 27 28 29 30 33 34 36 40 44 48 50 56 64 72);
    }
    my $curr_size = $w->fontActual($w->{'curr_font'}, -size);
    foreach my $size (@fontsizes) {
	$sizelb->add($size, -text => $size);
	if ($size == $curr_size) {
	    $sizelb->selectionSet($size);
	    $sizelb->anchorSet($size);
	    $sizelb->see($size);
	}
    }

    #$fstyle->Label->pack; # dummy, placeholder
    #my $fstyle2 = $fstyle->Frame->pack(-expand => 1, -fill => 'both',
	#			       -side => 'left');

    #my(%weight_res) = _get_label(delete $args->{-weightlabel}
	#			 || '~Bold');
    #my $weight = $w->fontActual($w->{'curr_font'}, -weight);
    #my $wcb = $fstyle2->Checkbutton
    #  (-variable => \$weight,
    #   -font => $bold_font,
    #   -onvalue => 'bold',
    #   -offvalue => 'normal',
    #   @{$weight_res{'args'}},
    #   -command => sub { $w->UpdateFont(-weight => $weight) }
    #  )->pack(-anchor => 'w', -expand => 1);

    #my(%slant_res) = _get_label(delete $args->{-slantlabel}
	#			 || '~Italic');
    #my $slant = $w->fontActual($w->{'curr_font'}, -slant);
    #my $scb = $fstyle2->Checkbutton
    #  (-variable => \$slant,
    #   -font => $italic_font,
    #   -onvalue => 'italic',
    #   -offvalue => 'roman',
    #   @{$slant_res{'args'}},
    #   -command => sub { $w->UpdateFont(-slant => $slant) }
    #  )->pack(-anchor => 'w', -expand => 1);

    #my(%underline_res) = _get_label(delete $args->{-underlinelabel}
	#			    || '~Underline');
    #my $underline = $w->fontActual($w->{'curr_font'}, -underline);
    #my $ucb = $fstyle2->Checkbutton
    #  (-variable => \$underline,
    #   -font => $underline_font,
    #   -onvalue => 1,
    #   -offvalue => 0,
    #   @{$underline_res{'args'}},
    #   -command => sub { $w->UpdateFont(-underline => $underline) }
    #  )->pack(-anchor => 'w', -expand => 1);

    #my(%overstrike_res) = _get_label(delete $args->{-overstrikelabel}
	#			     || 'O~verstrike');
    #my $overstrike = $w->fontActual($w->{'curr_font'}, -overstrike);
    #my $ocb = $fstyle2->Checkbutton
    #  (-variable => \$overstrike,
    #   -font => $overstrike_font,
    #   -onvalue => 1,
    #   -offvalue => 0,
    #   @{$overstrike_res{'args'}},
    #   -command => sub { $w->UpdateFont(-overstrike => $overstrike) }
    #  )->pack(-anchor => 'w', -expand => 1);

    my $c = $w->Canvas
      (-height => 36,
       -bg => 'white',
       -relief => 'sunken',
       -bd => 2,
      )->pack(-expand => 1, -fill => 'both',
	      -padx => 3, -pady => 3);
    $w->Advertise('sample_canvas' => $c);

    my $bf = $w->Frame->pack(-fill => 'x', -padx => 3, -pady => 3);

    my(%ok_res) = _get_label(delete $args->{'-oklabel'}
			     || "~OK");
    my $okb = $bf->Button
      (@{$ok_res{'args'}},
       -fg => 'green4',
       -font => $bold_font,
       -command => ['Accept', $w ],
      )->grid(-column => 0, -row => 0, -rowspan => 2,
	      -sticky => 'ew', -padx => 5);

    my(%apply_res) = _get_label(delete $args->{'-applylabel'}
				|| "~Apply");
    my $applyb;
    # XXX evtl. in configure erledigen
    if ($args->{-applycmd}) {
	my $applycmd = delete $args->{-applycmd};
	$applyb = $bf->Button
	  (@{$apply_res{'args'}},
	   -fg => 'yellow4',
	   -font => $bold_font,
	   -command => sub { $applycmd->($w->ReturnFont($w->{'curr_font'})) },
	  )->grid(-column => 1, -row => 0, -rowspan => 2,
		  -sticky => 'ew', -padx => 5);
    }

    my(%cancel_res) = _get_label(delete $args->{'-cancellabel'}
				 || "~Cancel");
    my $cancelb = $bf->Button
      (@{$cancel_res{'args'}},
       -fg => 'red',
       -font => $bold_font,
       -command => ['Cancel', $w ],
      )->grid(-column => 2, -row => 0, -rowspan => 2,
	      -sticky => 'ew', -padx => 5);
    $bf->grid('columnconfigure', 3, -weight => 1.0);

    my(%altsample_res) = _get_label(delete $args->{'-altsamplelabel'}
				    || "A~lt sample");
    my $altcb = $bf->Checkbutton
      (@{$altsample_res{'args'}},
       -variable => \$w->{'alt_sample'},
       -command => sub { $w->UpdateFont; },
      )->grid(-column => 4, -row => 0,
	      -sticky => 'w', -padx => 5);

    my(%nicefonts_res, $nicecb);
    if (!exists $args->{'-nicefontsbutton'} || $args->{'-nicefontsbutton'}) {
	%nicefonts_res = _get_label(delete $args->{'-nicefontslabel'}
				    || "~Nicefonts");
	$nicecb = $bf->Checkbutton
	  (@{$nicefonts_res{'args'}},
	   -variable => \$w->{Configure}{-nicefont},
	   -command => sub { $w->InsertFamilies; },
	  )->grid(-column => 4, -row => 1,
		  -sticky => 'w', -padx => 5);
    }
    delete $args->{'-nicefontsbutton'};

    my(%fixedfonts_res, $fixedcb);
    if (!exists $args->{'-fixedfontsbutton'} || $args->{'-fixedfontsbutton'}) {
	%fixedfonts_res = _get_label(delete $args->{'-fixedfontslabel'}
				     || "Fi~xed Only");
	$fixedcb = $bf->Checkbutton
	  (@{$fixedfonts_res{'args'}},
	   -variable => \$w->{Configure}{-fixedfont},
	   -command => sub { $w->InsertFamilies; },
	  )->grid(-column => 5, -row => 0,
		  -sticky => 'w', -padx => 5);
    }
    delete $args->{'-fixedfontsbutton'};

    $w->grid('columnconfigure', 0, -minsize => 4);
    $w->grid('columnconfigure', 4, -minsize => 4);
    $w->grid('rowconfigure',    0, -minsize => 4);
    $w->grid('rowconfigure',    8, -minsize => 4);

    $w->bind("<$family_res{'key'}>" => sub { $famlb->focus }) 
      if $family_res{'key'};
    $w->bind("<$size_res{'key'}>"   => sub { $sizelb->focus })
      if $size_res{'key'};

    #$w->bind("<$weight_res{'key'}>"     => sub { $wcb->invoke })
    #  if $weight_res{'key'};
    #$w->bind("<$slant_res{'key'}>"      => sub { $scb->invoke })
    #  if $slant_res{'key'};
    #$w->bind("<$underline_res{'key'}>"  => sub { $ucb->invoke })
    #  if $underline_res{'key'};
    #$w->bind("<$overstrike_res{'key'}>" => sub { $ocb->invoke })
    #  if $overstrike_res{'key'};

    $w->bind("<$ok_res{'key'}>"      => sub { $okb->invoke })
      if $ok_res{'key'};
    $w->bind("<Return>" => sub { $okb->invoke });
    $w->bind("<$apply_res{'key'}>"   => sub { $applyb->invoke })
      if $applyb && $apply_res{'key'};
    $w->bind("<$cancel_res{'key'}>"  => sub { $cancelb->invoke })
      if $cancel_res{'key'};
    $w->bind("<Escape>" => sub { $cancelb->invoke });
    $w->bind("<$altsample_res{'key'}>" => sub { $altcb->invoke })
      if $altsample_res{'key'};
    $w->bind("<$nicefonts_res{'key'}>" => sub { $nicecb->invoke })
      if $nicefonts_res{'key'};
    $w->bind("<$fixedfonts_res{'key'}>" => sub { $fixedcb->invoke })
      if $fixedfonts_res{'key'};

    # XXX -subbg: ugly workaround...
    $w->ConfigSpecs
      (-subbg           => [ 'PASSIVE', 'subBackground', 'SubBackground',
                             'white'],
       -nicefont        => [ 'PASSIVE', undef, undef, 0],
       -fixedfont       => [ 'PASSIVE', undef, undef, 0],
       -sampletext      => [ 'PASSIVE', undef, undef, 
		             'The Quick Brown Fox Jumps Over The Lazy Dog.'],
       -title           => [ 'METHOD', undef, undef, 'Choose font'],
       -customsizetitle => [ 'PASSIVE', undef, undef, 'Choose font size'],
       DEFAULT   => [ 'family_list' ],
      );

    $w->Delegates(DEFAULT => 'family_list');

    # according to the manpage, the fonts are only destroyed if the
    # last reference to them is also destroyed
    # XXX disable for now
#    $w->fontDelete($dialog_font, 
#		   $bold_font, $italic_font,
#		   $underline_font, $overstrike_font);

    $w;
}

sub UpdateFont {
    my($w, %args) = @_;
    $w->fontConfigure($w->{'curr_font'}, %args) if scalar %args;
    my $c = $w->Subwidget('sample_canvas');
    $c->delete('font');
# XXX see below
#    $w->Busy;
    eval {
	my $sampletext;
	my $ch_width  = $w->fontMeasure($w->{'curr_font'}, 'M');
	my $ch_height = $w->fontMetrics($w->{'curr_font'}, -linespace);
	if ($w->{'alt_sample'}) {
	    my $x;
	    my $y = 4;
	    for(my $i = 32; $i < 256; $i+=16) {
		$x = 4;
		for my $j (0 .. 15) {
		    next if $i+$j == 127;
		    my $ch = chr($i + $j);
		    unless ($ch eq "\r" || $ch eq "\n") {
			$c->createText($x, $y, -anchor => 'nw',
				       -text => $ch,
				       -font => $w->{'curr_font'},
				       -tags => 'font');
		    }
		    $x += $ch_width + 4;
		}
		$y += $ch_height;
	    }
	} else {
	    $c->createText(4, 4,
			   -anchor => 'nw',
			   -text => $w->cget(-sampletext),
			   -font => $w->{'curr_font'},
			   -tags => 'font');
	}
    };
    warn $@ if $@;
#    $w->Unbusy;
}

sub Cancel {
    my $w = shift;
    $w->{Selected} = undef;
}

sub Accept {
    my $w = shift;
    $w->{Selected} = $w->{'curr_font'};
}

sub Show {
    my($w, %args) = @_;

    my $test_hack = delete $args{'-_testhack'};

    $w->transient($w->Parent->toplevel);
    my $oldFocus = $w->focusCurrent;
    my $oldGrab = $w->grab('current');
    my $grabStatus = $oldGrab->grab('status') if ($oldGrab);
    $w->grab;

    $w->InsertFamilies();
    $w->UpdateFont();
    # XXX ugly...
    $w->Subwidget('family_list')->configure(-bg => $w->cget(-subbg));
    $w->Subwidget('size_list')->configure(-bg => $w->cget(-subbg));
    $w->Subwidget('sample_canvas')->configure(-bg => $w->cget(-subbg));

    $w->Popup(%args);
    # XXX won't work with 800.015?
    #$w->waitVisibility;
    $w->focus;
    $w->OnDestroy(sub { $w->Cancel });
    $w->waitVariable(\$w->{Selected}) unless $test_hack;

    return if !Tk::Exists($w); # probably MainWindow closed

    eval {
	$oldFocus->focus if $oldFocus;
    };
    $w->grab('release');
    $w->withdraw;
    if ($oldGrab) {
	if ($grabStatus eq 'global') {
	    $oldGrab->grab('-global');
	} else {
	    $oldGrab->grab;
	}
    }

    $w->ReturnFont($w->{Selected});
}

sub ReturnFont {
    my($w, $var) = @_;
    if (defined $var) {
	my $ret = $w->fontCreate($w->font('actual', $var));
	$ret;
    } else {
	undef;
    }
}

sub InsertFamilies {
    my $w = shift;

# XXX Busy ist gefaehrlich ... anscheinend wird der alte grab nicht
# richtig gespeichert!
#    $w->Busy;
    my $old_cursor = $w->cget(-cursor);
    $w->configure(-cursor => 'watch');
    $w->idletasks;
    eval {
	$w->{'family_index'} = [];
	my $nicefont = $w->cget(-nicefont); # XXX name?
	my $fixedfont = $w->cget(-fixedfont);
	my $curr_family = $w->fontActual($w->{'curr_font'}, -family);
	my $famlb = $w->Subwidget('family_list');
	$famlb->delete('all');
	my @fam = sort $w->fontFamilies;
	my $bg = $w->cget(-subbg);
	my $i = 0;
	foreach my $fam (@fam) {
	    next if $fam eq '';
	    next if $fixedfont
	      and not $w->fontMetrics($w->Font(-family => $fam), '-fixed');
	    my $u_fam = $fam;
	    #(my $u_fam = $fam) =~ s/\b(.)/\u$1/g;
	    $w->{'family_index'}[$i] = $fam;
	    my $f_style = $famlb->ItemStyle
	      ('text',
	       ($nicefont ? (-font => "{$fam}") : ()),
	       -background => $bg,
	      );
	    $famlb->add($i, -text => $u_fam, -style => $f_style);
	    if ($curr_family eq $fam) {
		$famlb->selectionSet($i);
		$famlb->anchorSet($i);
		$famlb->see($i);
	    }
	    $i++;
	}
    };
    warn $@ if $@;
    $w->configure(-cursor => $old_cursor);
#    $w->Unbusy;

}

# get position of the tilde character and delete it
sub _get_label {
    my $s = shift;
    my %res;
    if ($s =~ s/(.*)~(.)/$1$2/) {
	my $key = lc($2);
	my $underline = length($1);
	@{$res{'args'}} = (-text      => $s,
			   -underline => $underline);
	$res{'key'}  = $key;
    } else {
	@{$res{'args'}} = (-text => $s);
    }
    %res;
}

sub _custom_size {
    my($w) = @_;
    my $t = $w->Toplevel;
    my $label = $w->cget(-customsizetitle);
    $t->title($label);

    my $sizelb = $w->Subwidget("size_list");
    my $fontsize = 10;
    if (defined $sizelb->info("selection")) {
	$fontsize = $sizelb->entrycget($sizelb->info("selection"), -text);
    }

    my $f1 = $t->Frame->pack;
    $f1->Label(-text => $label)->pack(-side => 'left');
    my $e = $f1->Entry(-width => 4,
		       -textvariable => \$fontsize)->pack(-side => "left");
    $e->focus;
    $e->selectionRange(0,'end');
    $e->icursor('end');

    my $f = $t->Frame->pack;
    my $waitvar = 0;
    my $ok = $f->Button
      (-text => "Ok",
       -command => sub {
	   $w->UpdateFont(-size => $fontsize);
	   $sizelb->selectionClear;
	   $sizelb->anchorClear;
	   foreach ($sizelb->info("children")) {
	       if ($sizelb->entrycget($_, -text) eq $fontsize) {
		   $sizelb->selectionSet($_);
		   $sizelb->anchorSet($_);
		   $sizelb->see($_);
		   last;
	       }
	   }
	   $waitvar = 1;
       })->pack(-side => "left");
    $f->Button(-text => "Cancel",
	       -command => sub { $waitvar = -1 })->pack(-side => "left");

    $e->bind("<Return>" => sub { $ok->invoke });

    $t->Popup(-popover => "cursor");
    $t->waitVariable(\$waitvar);
    $t->destroy;
}

# put some dirt into Tk::Widget...
package       # hide from CPAN indexer
  Tk::Widget;

# XXX Refont Canvases?
sub RefontTree {
    my ($w, %args) = @_;
    my $dbOption;
    my $value;
    my $font = $args{-font} or die "No font specified";
    eval { local $SIG{'__DIE__'}; $value = $w->cget(-font) };
    if (defined $value) {
	$w->configure(-font => $font);
    }
    if ($w->isa('Tk::Canvas') and $args{-canvas}) {
	foreach my $item ($w->find('all')) {
	    eval { local $SIG{'__DIE__'};
		   $value = $w->itemcget($item, -font) };
	    if (defined $value) {
		$w->itemconfigure($item, -font => $font);
	    }
	}
    }
    foreach my $child ($w->children) {
	$child->RefontTree(%args);
    }
}

1;

__END__

=head1 NAME

Tk::FontDialog - a font dialog widget for perl/Tk

=head1 SYNOPSIS

    use Tk::FontDialog;
    $font = $top->FontDialog->Show;

=head1 DESCRIPTION

Tk::FontDialog implements a font dialog widget.

In the Family and Size listboxes, the font family and font size can be
specified. The checkbuttons on the right turn on bold, italic,
underlined and overstriked variants of the chosen font. A sample of
the font is shown in the middle area.

With the "Alt sample" checkbutton, it is possible to show all
characters in the charset instead of the default text. "Fixed only"
restricts the font family list to fixed fonts only. If the "Nicefonts"
checkbutton is set, then the font names in the listbox are displayed
in the corresponding font. Note that this option can be slow if a lot
of fonts are installed or for 16 bit fonts.

A click with the right button in the font size listbox pops up a
window to enter arbitrary font sizes.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item -font

The dialog font.

=item -initfont

The initial font.

=item -fontsizes

A list of font sizes. The default contains sizes from 0 to 72 points
(XXX or pixels?).

=item -nicefont

If set, font names are displayed in its font style. This may be slow,
especially if you have many fonts or 16 bit fonts (e.g. Asian fonts).

=item -nicefontsbutton

If set to false, then the "Nice fonts" button is not displayed.

=item -fixedfont

If set, proportional font families are not listed, leaving only the fixed
fonts. This is slow, as each font must be checked to see if it is fixed
or proportional.

=item -fixedfontsbutton

If set to false, then the "Fixed fonts" button is not displayed.

=item -sampletext

The sample text which should contain all letters. The default is "The
Quick Brown Fox Jumps Over The Lazy Dog" German readers may probably
use "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern".

=back

=head1 INTERNATIONALIZATION

There are a couple of options to change the labels of the dialog. Note
that you can prepend a tilde (C<~>) to get an accelerator key with
C<Alt>. Here is a list of these options with the default (English)
setting:

=over 4

=item -familylabel (Family:)

=item -sizelabel (Size:)

=item -weightlabel (Bold)

=item -slantlabel (Italic)

=item -underlinelabel (Underline)

=item -overstrikelabel (Overstrike)

=item -oklabel (OK)

=item -applylabel (Apply)

=item -cancellabel (Cancel)

=item -altsamplelabel (Alt sample)

=item -nicefontslabel (Nicefonts)

=item -fixedfontslabel (Fixed Only)

=item -title (Choose font)

=item -customsizetitle (Choose font size)

=back

=head1 CAVEAT

Note that font names with whitespace like "New century schoolbook" or
"MS Sans Serif" can cause problems when using in a -font option. The
solution is to put the names in Tcl-like braces, like

    -font => "{New century schoolbook} 10"

=head1 BUGS/TODO

  - ConfigSpecs handling is poor
    put at least -font into configspecs
  - run test, call dialog for 2nd time: immediate change of font?
  - better name for nicefont
  - restrict on charsets and encodings (xlsfonts? X11::Protocol::ListFonts?)
    difficult because core Tk font handling ignores charsets and encodings

=head1 SEE ALSO

L<Tk::font|Tk::font>

=head1 AUTHOR

Slaven Rezic <slaven@rezic.de>

Suggestions by Michael Houghton <herveus@Radix.Net>.

=head1 COPYRIGHT

Copyright (c) 1998,1999,2003 Slaven Rezic. All rights reserved.
This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
