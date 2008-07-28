#
# $Id: Jcode_kh.pm,v 1.2 2008-07-28 07:39:28 ko-ichi Exp $
#

# kh
# shiftjisをcp932に、euc-jpをeucJP-msに変換した。
# Encode::EUCJPMSモジュールが必要

no warnings 'redefine';

package Jcode;
use 5.005; # fair ?
use Carp;
use strict;
use vars qw($RCSID $VERSION $DEBUG);

$RCSID = q$Id: Jcode_kh.pm,v 1.2 2008-07-28 07:39:28 ko-ichi Exp $;
$VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
$DEBUG = 0;

# we no longer use Exporter
use vars qw($USE_ENCODE);
$USE_ENCODE = ($] >= 5.008001);

use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA         = qw(Exporter);
@EXPORT      = qw(jcode getcode);
@EXPORT_OK   = qw($RCSID $VERSION $DEBUG);
%EXPORT_TAGS = ( all       => [ @EXPORT, @EXPORT_OK ] );

no warnings 'all';
use overload 
    q("") => sub { $_[0]->euc },
    q(==) => sub { overload::StrVal($_[0]) eq overload::StrVal($_[1]) },
    q(.=) => sub { $_[0]->append( $_[1] ) },
    fallback => 1,
    ;

if ($USE_ENCODE){
    $DEBUG and warn "Using Encode";
    my $data = join("", <DATA>);
    eval $data;
    $@ and die $@;
}else{
    $DEBUG and warn "Not Using Encode";
    require Jcode::_Classic;
    use vars qw/@ISA/;
    unshift @ISA, qw/Jcode::_Classic/;
    for my $sub (qw/jcode getcode convert load_module/){
	no strict 'refs';
	*{$sub} = \&{'Jcode::_Classic::' . $sub };
    }
    for my $enc (qw/sjis jis ucs2 utf8/){
	no strict 'refs';
	*{"euc_" . $enc} = \&{"Jcode::_Classic::" . "euc_" . $enc};
	*{$enc . "_euc"} = \&{"Jcode::_Classic::" . $enc . "_euc"};
    }
}

1;
__DATA__
#
# This idea was inspired by JEncode
# http://www.donzoko.net/cgi/jencode/
#
package Jcode;
use Encode;
use Encode::EUCJPMS;
use Encode::Alias;
use Encode::Guess;
use Encode::JP::H2Z;
use Scalar::Util; # to resolve from_to() vs. 'constant' issue.

my %jname2e = (
	       sjis        => 'cp932',
	       euc         => 'eucJP-ms',
	       jis         => '7bit-jis',
	       iso_2022_jp => 'iso-2022-jp',
	       ucs2        => 'UTF-16BE',
	      );

my %ename2j = reverse %jname2e;

our $FALLBACK = Encode::LEAVE_SRC;
sub FB_PERLQQ()   { Encode::FB_PERLQQ() };
sub FB_XMLCREF()  { Encode::FB_XMLCREF() };
sub FB_HTMLCREF() { Encode::FB_HTMLCREF() };
#for my $fb (qw/FB_PERLQQ FB_XMLCREF FB_HTMLCREF/){
#    no strict 'refs';
#    *{$fb} = \&{"Encode::$fb"};
#}


#######################################
# Functions
#######################################

sub jcode { return __PACKAGE__->new(@_); }

#
# Used to be in Jcode::Constants
#

my %_0208 = (
	     1978 => '\e\$\@',
	     1983 => '\e\$B',
	     1990 => '\e&\@\e\$B',
	    );
my %RE = (
       ASCII     => '[\x00-\x7f]',
       BIN       => '[\x00-\x06\x7f\xff]',
       EUC_0212  => '\x8f[\xa1-\xfe][\xa1-\xfe]',
       EUC_C     => '[\xa1-\xfe][\xa1-\xfe]',
       EUC_KANA  => '\x8e[\xa1-\xdf]',
       JIS_0208  =>  "$_0208{1978}|$_0208{1983}|$_0208{1990}",
       JIS_0212  => "\e" . '\$\(D',
       JIS_ASC   => "\e" . '\([BJ]',     
       JIS_KANA  => "\e" . '\(I',
       SJIS_C    => '[\x81-\x9f\xe0-\xfc][\x40-\x7e\x80-\xfc]',
       SJIS_KANA => '[\xa1-\xdf]',
       UTF8      => '[\xc0-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf][\x80-\xbf]'
      );

sub _max {
    my $result = shift;
    for my $n (@_){
	$result = $n if $n > $result;
    }
    return $result;
}

sub getcode {
    my $arg = shift;
    my $r_str = ref $arg ? $arg : \$arg;
    Encode::is_utf8($$r_str) and return 'utf8';
    my ($code, $nmatch, $sjis, $euc, $utf8) = ("", 0, 0, 0, 0);
    if ($$r_str =~ /$RE{BIN}/o) {	# 'binary'
	my $ucs2;
	$ucs2 += length($1)
	    while $$r_str =~ /(\x00$RE{ASCII})+/go;
	if ($ucs2){      # smells like raw unicode 
	    ($code, $nmatch) = ('ucs2', $ucs2);
	}else{
	    ($code, $nmatch) = ('binary', 0);
	 }
    }
    elsif ($$r_str !~ /[\e\x80-\xff]/o) {	# not Japanese
	($code, $nmatch) = ('ascii', 1);
    }				# 'jis'
    elsif ($$r_str =~ 
	   m[
	     $RE{JIS_0208}|$RE{JIS_0212}|$RE{JIS_ASC}|$RE{JIS_KANA}
	   ]ox)
    {
	($code, $nmatch) = ('jis', 1);
    } 
    else { # should be euc|sjis|utf8
	# use of (?:) by Hiroki Ohzaki <ohzaki@iod.ricoh.co.jp>
	$sjis += length($1) 
	    while $$r_str =~ /((?:$RE{SJIS_C})+)/go;
	$euc  += length($1) 
	    while $$r_str =~ /((?:$RE{EUC_C}|$RE{EUC_KANA}|$RE{EUC_0212})+)/go;
	$utf8 += length($1) 
	    while $$r_str =~ /((?:$RE{UTF8})+)/go;
	# $utf8 *= 1.5; # M. Takahashi's suggestion
	$nmatch = _max($utf8, $sjis, $euc);
	carp ">DEBUG:sjis = $sjis, euc = $euc, utf8 = $utf8" if $DEBUG >= 3;
	$code = 
	    ($euc > $sjis and $euc > $utf8) ? 'euc' :
		($sjis > $euc and $sjis > $utf8) ? 'sjis' :
		    ($utf8 > $euc and $utf8 > $sjis) ? 'utf8' : undef;
    }
    return wantarray ? ($code, $nmatch) : $code;
}

sub convert{
    my $r_str = (ref $_[0]) ? $_[0] : \$_[0];
    my (undef,$ocode,$icode,$opt) = @_;
    Encode::is_utf8($$r_str) and utf8::encode($$r_str);
    defined $icode or $icode = getcode($r_str) or return;
    $icode eq 'binary' and return $$r_str;

    $jname2e{$icode} and $icode = $jname2e{$icode};
    $jname2e{$ocode} and $ocode = $jname2e{$ocode};

    if ($opt){
	return $opt eq 'z' 
	    ? jcode($r_str, $icode)->h2z->$ocode
		: jcode($r_str, $icode)->z2h->$ocode ;
	    
    }else{
	if (Scalar::Util::readonly($$r_str)){
	    my $tmp = $$r_str;
	    Encode::from_to($tmp, $icode, $ocode);
	    return $tmp;
	}else{
	    Encode::from_to($$r_str, $icode, $ocode);
	    return $$r_str;
	}
    }
}

#######################################
# Constructors
#######################################

sub new{
    my $class = shift;
    my $self  = {};
    bless $self => $class;
    defined $_[0] or $_[0] = '';
    $self->set(@_);
}

sub set{
    my $self  = shift;
    my $str   = $_[0];
    my $r_str = (ref $str) ? $str : \$str;
    my $code  = $_[1] if(defined $_[1]);
    my $icode =  $code || getcode($r_str) || 'euc';
    $self->{icode}  = $jname2e{$icode} || $icode;
    # binary and flagged utf8 are stored as-is
    unless (Encode::is_utf8($$r_str) || $icode eq 'binary'){
	$$r_str = decode($self->{icode}, $$r_str);
    }
    $self->{r_str}  = $r_str;
    $self->{nmatch} = 0;
    $self->{method} = 'Encode';
    $self->{fallback} = $FALLBACK;
    $self;
}

sub append{
    my $self  = shift;
    my $str   = $_[0];
    my $r_str = (ref $str) ? $str : \$str;
    my $code  = $_[1] if(defined $_[1]);
    my $icode =  $code || getcode($r_str) || 'euc';
    $self->{icode}  = $jname2e{$icode} || $icode;
    # binary and flagged utf8 are stored as-is
    unless (Encode::is_utf8($$r_str) || $icode eq 'binary'){
	$$r_str = decode($self->{icode}, $$r_str);
    }
    ${ $self->{r_str} }  .= $$r_str;
    $self->{nmatch} = 0;
    $self->{method} = 'internal';
    $self;
}

#######################################
# Accessors
#######################################

for my $method (qw/r_str icode nmatch error_m error_r error_tr/){
    no strict 'refs';
    *{$method} = sub { $_[0]->{$method} };
}

sub fallback{
    my $self = shift;
    @_ or return $self->{fallback};
    $self->{fallback} =  $_[0]|Encode::LEAVE_SRC;
    return $self;
}

#######################################
# Converters
#######################################

sub utf8 { encode_utf8( ${$_[0]->{r_str}} ) }

#
#  Those supported in Jcode 0.x are defined as default
#

for my $enc (keys %jname2e){
    no strict 'refs';
    my $name = $jname2e{$enc} || $enc;
    my $e = find_encoding($name) or croak "$enc not supported";
    *{$enc} = sub {
	my $r_str = $_[0]->{r_str};
	Encode::is_utf8($$r_str) ? 
		$e->encode($$r_str, $_[0]->{fallback}) : $$r_str;
    };
}

#
# The rest is defined on the fly
#

sub DESTROY {};

sub AUTOLOAD {
    our $AUTOLOAD;
    my $self = shift;
    my $type = ref $self
        or confess "$self is not an object";
    my $myname = $AUTOLOAD;
    $myname =~ s/.*:://;  # strip fully-qualified portion
    $myname eq 'DESTROY' and return;
    my $e = find_encoding($myname) 
	or confess __PACKAGE__, ": unknown encoding: $myname";
    $DEBUG and warn ref($self), "->$myname defined";
    no strict 'refs';
    *{$myname} =
	sub {
	    my $str = ${ $_[0]->{r_str} };
            Encode::is_utf8($str) ?
		      $e->encode($str, $_[0]->{fallback}) : $str;
	  };
    $myname->($self);
}

#######################################
# Length, Translation and Fold
#######################################

sub jlength{
    length(  ${$_[0]->{r_str}} );
}

sub tr{
    my $self = shift;
    my $str  = ${$self->{r_str}};
    my $from = Encode::is_utf8($_[0]) ? $_[0] : decode('eucJP-ms', $_[0]);
    my $to   = Encode::is_utf8($_[1]) ? $_[1] : decode('eucJP-ms', $_[1]);
    my $opt  = $_[2] || '';
    $from =~ s,\\,\\\\,og; $from =~ s,/,\\/,og;
    $to   =~ s,\\,\\\\,og; $to   =~ s,/,\\/,og;
    $opt  =~ s,[^a-z],,og;
    my $match = eval qq{ \$str =~ tr/$from/$to/$opt };
    if ($@){
        $self->{error_tr} = $@;
        return $self;
    }
    $self->{r_str} = \$str;
    $self->{nmatch} = $match || 0;
    return $self;
}

sub jfold{
    my $self = shift;
    my $r_str  = $self->{r_str};
    my $bpl = shift || 72;
    my $nl  = shift || "\n";
    my $kin = shift;

    my @lines = ();
    my %kinsoku = ();
    my ($len, $i) = (0,0);

    if( defined $kin and (ref $kin) eq 'ARRAY' ){
	%kinsoku = map { my $k = Encode::is_utf8($_) ? 
			     $_ : decode('eucJP-ms' =>  $_);
			 ($k, 1) } @$kin;
    }

    while($$r_str =~ m/(.)/sg){
	my $char = $1;
	# <UFF61> \xA1 |0 # HALFWIDTH IDEOGRAPHIC FULL STOP
	# <UFF9F> \xDF |0 # HALFWIDTH KATAKANA SEMI-VOICED SOUND MARK
	my $ord = ord($char);
	my $clen =  $ord < 128 ? 1
	    : $ord <  0xff61 ? 2 
	    : $ord <= 0xff9f ? 1 : 2; 
	if ($len + $clen > $bpl){
	    unless($kinsoku{$char}){
		$i++; 
		$len = 0;
	    }
	}
	$lines[$i] .= $char;
	$len += $clen;
    }
    defined($lines[$i]) or pop @lines;
    $$r_str = join($nl, @lines);

    $self->{r_str} = $r_str;
    my $e = find_encoding($self->{icode});
    @lines = map {
	Encode::is_utf8($_) ? $e->encode($_, $self->{fallback}) : $_
    } @lines;

    return wantarray ? @lines : $self;
}

#######################################
# Full and Half
#######################################

sub h2z{
    my $self = shift;
    my $euc  = $self->euc;
    Encode::JP::H2Z::h2z(\$euc, @_);
    $self->set($euc => 'euc');
    $self;
}

sub z2h{
    my $self = shift;
    my $euc =  $self->euc;
    Encode::JP::H2Z::z2h(\$euc, @_);
    $self->set($euc => 'euc');
    $self;
}

#######################################
# MIME-Encoding
#######################################

sub mime_decode{
    my $self = shift;
    my $utf8  = Encode::decode('MIME-Header', $self->utf8);
    $self->set($utf8 =>'utf8');
}

sub mime_encode{
    my $self = shift;
    my $str = $self->euc;
    my $r_str = \$str;
    my $lf  = shift || "\n";
    my $bpl = shift || 76;
    my ($trailing_crlf) = ($$r_str =~ /(\n|\r|\x0d\x0a)$/o);
    $str  = _mime_unstructured_header($$r_str, $lf, $bpl);
    not $trailing_crlf and $str =~ s/(\n|\r|\x0d\x0a)$//o;
    $str;
}

#
# shamelessly stolen from
# http://www.din.or.jp/~ohzaki/perl.htm#JP_Base64
#

sub _add_encoded_word {
    require MIME::Base64;
    my($str, $line, $lf, $bpl) = @_;
    my $result = '';
    while (length($str)) {
	my $target = $str;
	$str = '';
	if (length($line) + 22 +
	    ($target =~ /^(?:$RE{EUC_0212}|$RE{EUC_C})/o) * 8 > $bpl) {
	    $line =~ s/[ \t\n\r]*$/$lf/eo;
	    $result .= $line;
	    $line = ' ';
	}
	while (1) {
	    my $iso_2022_jp = jcode($target, 'euc')->iso_2022_jp;
	    if (my $count = ($iso_2022_jp =~ tr/\x80-\xff//d)){
		$DEBUG and warn $count;
		$target = jcode($iso_2022_jp, 'iso_2022_jp')->euc;
	    }
	    my $encoded = '=?ISO-2022-JP?B?' .
	      MIME::Base64::encode_base64($iso_2022_jp, '')
		      . '?=';
	    if (length($encoded) + length($line) > $bpl) {
		$target =~ 
		    s/($RE{EUC_0212}|$RE{EUC_KANA}|$RE{EUC_C}|$RE{ASCII})$//o;
		$str = $1 . $str;
	    } else {
		$line .= $encoded;
		last;
	    }
	}
    }
    return $result . $line;
}

sub _mime_unstructured_header {
    my ($oldheader, $lf, $bpl) = @_;
    my(@words, @wordstmp, $i);
    my $header = '';
    $oldheader =~ s/\s+$//;
    @wordstmp = split /\s+/, $oldheader;
    for ($i = 0; $i < $#wordstmp; $i++) {
	if ($wordstmp[$i] !~ /^[\x21-\x7E]+$/ and
	    $wordstmp[$i + 1] !~ /^[\x21-\x7E]+$/) {
	    $wordstmp[$i + 1] = "$wordstmp[$i] $wordstmp[$i + 1]";
	} else {
	    push(@words, $wordstmp[$i]);
	}
    }
    push(@words, $wordstmp[-1]);
    for my $word (@words) {
	if ($word =~ /^[\x21-\x7E]+$/) {
	    $header =~ /(?:.*\n)*(.*)/;
	    if (length($1) + length($word) > $bpl) {
		$header .= "$lf $word";
	    } else {
		$header .= $word;
	    }
	} else {
	    $header = _add_encoded_word($word, $header, $lf, $bpl);
	}
	$header =~ /(?:.*\n)*(.*)/;
	if (length($1) == $bpl) {
	    $header .= "$lf ";
	} else {
	    $header .= ' ';
	}
    }
    $header =~ s/\n? $/\n/;
    $header;
}

#######################################
# Matching and Replacing
#######################################

no warnings 'uninitialized';

sub m{
    use utf8;
    my $self    = shift;
    my $r_str   = $self->{r_str};
    my $pattern = Encode::is_utf8($_[0]) ? shift : decode("eucJP-ms" => shift);
    my $opt     = shift || '' ;
    my @match;

    $pattern =~ s,\\,\\\\,og; $pattern =~ s,/,\\/,og;
    $opt     =~ s,[^a-z],,og;
    
    eval qq{ \@match = (\$\$r_str =~ m/$pattern/$opt) };
    if ($@){
	$self->{error_m} = $@;
	return;
    }
    # print @match, "\n";
    wantarray ?  map {encode('eucJP-ms' => $_)} @match : scalar @match;
}

sub s{
    use utf8;
    my $self    = shift;
    my $r_str   = $self->{r_str};
    my $pattern = Encode::is_utf8($_[0]) ? shift : decode("eucJP-ms" => shift);
    my $replace = Encode::is_utf8($_[0]) ? shift : decode("eucJP-ms" => shift);
    my $opt     = shift;

    $pattern =~ s,\\,\\\\,og; $pattern =~ s,/,\\/,og;
    $replace =~ s,\\,\\\\,og; $replace =~ s,/,\\/,og;
    $opt     =~ s,[^a-z],,og;

    eval qq{ (\$\$r_str =~ s/$pattern/$replace/$opt) };
    if ($@){
	$self->{error_s} = $@;
    }
    $self;
}

1;
__END__

=head1 NAME

Jcode - Japanese Charset Handler

=head1 SYNOPSIS

 use Jcode;
 # 
 # traditional
 Jcode::convert(\$str, $ocode, $icode, "z");
 # or OOP!
 print Jcode->new($str)->h2z->tr($from, $to)->utf8;

=cut

=head1 DESCRIPTION

B<<Japanese document is now available as L<Jcode::Nihongo>. >>

Jcode.pm supports both object and traditional approach.  
With object approach, you can go like;

  $iso_2022_jp = Jcode->new($str)->h2z->jis;

Which is more elegant than:

  $iso_2022_jp = $str;
  &jcode::convert(\$iso_2022_jp, 'jis', &jcode::getcode(\$str), "z");

For those unfamiliar with objects, Jcode.pm still supports C<getcode()>
and C<convert().>

If the perl version is 5.8.1, Jcode acts as a wrapper to L<Encode>,
the standard charset handler module for Perl 5.8 or later.

=head1 Methods

Methods mentioned here all return Jcode object unless otherwise mentioned.

=head2 Constructors

=over 2

=item $j = Jcode-E<gt>new($str [, $icode])

Creates Jcode object $j from $str.  Input code is automatically checked 
unless you explicitly set $icode. For available charset, see L<getcode>
below.

For perl 5.8.1 or better, C<$icode> can be I<any encoding name>
that L<Encode> understands. 

  $j = Jcode->new($european, 'iso-latin1');

When the object is stringified, it returns the EUC-converted string so
you can <print $j> instead of <print $j->euc>.

=over 2

=item Passing Reference

Instead of scalar value, You can use reference as

Jcode->new(\$str);

This saves time a little bit.  In exchange of the value of $str being 
converted. (In a way, $str is now "tied" to jcode object).

=back

=item $j-E<gt>set($str [, $icode])

Sets $j's internal string to $str.  Handy when you use Jcode object repeatedly 
(saves time and memory to create object). 

 # converts mailbox to SJIS format
 my $jconv = new Jcode;
 $/ = 00;
 while(&lt;&gt;){
     print $jconv->set(\$_)->mime_decode->sjis;
 }

=item $j-E<gt>append($str [, $icode]);

Appends $str to $j's internal string.

=item $j = jcode($str [, $icode]);

shortcut for Jcode->new() so you can go like;

=back

=head2 Encoded Strings

In general, you can retrieve I<encoded> string as $j-E<gt>I<encoded>.

=over 2

=item $sjis = jcode($str)->sjis

=item $euc = $j-E<gt>euc

=item $jis = $j-E<gt>jis

=item $sjis = $j-E<gt>sjis

=item $ucs2 = $j-E<gt>ucs2

=item $utf8 = $j-E<gt>utf8

What you code is what you get :)

=item $iso_2022_jp = $j-E<gt>iso_2022_jp

Same as C<< $j->h2z->jis >>.
Hankaku Kanas are forcibly converted to Zenkaku.

For perl 5.8.1 and better, you can also use any encoding names and
aliases that Encode supports.  For example:

  $european = $j->iso_latin1; # replace '-' with '_' for names.

B<FYI>: L<Encode::Encoder> uses similar trick.

=over 2

=item $j-E<gt>fallback($fallback)

For perl is 5.8.1 or better, Jcode stores the internal string in
UTF-8.  Any character that does not map to I<< -E<gt>encoding >> are
replaced with a '?', which is L<Encode> standard.

  my $unistr = "\x{262f}"; # YIN YANG
  my $j = jcode($unistr);  # $j->euc is '?'

You can change this behavior by specifying fallback like L<Encode>.
Values are the same as L<Encode>.  C<Jcode::FB_PERLQQ>,
C<Jcode::FB_XMLCREF>, C<Jcode::FB_HTMLCREF> are aliased to those
of L<Encode> for convenice.

  print $j->fallback(Jcode::FB_PERLQQ)->euc;   # '\x{262f}'
  print $j->fallback(Jcode::FB_XMLCREF)->euc;  # '&#x262f;'
  print $j->fallback(Jcode::FB_HTMLCREF)->euc; # '&#9775;'

The global variable C<$Jcode::FALLBACK> stores the default fallback so you can override that by assigning the value.

  $Jcode::FALLBACK = Jcode::FB_PERLQQ; # set default fallback scheme

=back

=item [@lines =] $jcode-E<gt>jfold([$width, $newline_str, $kref])

folds lines in jcode string every $width (default: 72) where $width is
the number of "halfwidth" character.  Fullwidth Characters are counted
as two.

with a newline string spefied by $newline_str (default: "\n").

Rudimentary kinsoku suppport is now available for Perl 5.8.1 and better.

=item $length = $jcode-E<gt>jlength();

returns character length properly, rather than byte length.

=back

=head2 Methods that use MIME::Base64

To use methods below, you need L<MIME::Base64>.  To install, simply

   perl -MCPAN -e 'CPAN::Shell->install("MIME::Base64")'

If your perl is 5.6 or better, there is no need since L<MIME::Base64> 
is bundled.

=over 2

=item $mime_header = $j-E<gt>mime_encode([$lf, $bpl])

Converts $str to MIME-Header documented in RFC1522. 
When $lf is specified, it uses $lf to fold line (default: \n).
When $bpl is specified, it uses $bpl for the number of bytes (default: 76; 
this number must be smaller than 76).

For Perl 5.8.1 or better, you can also encode MIME Header as:

  $mime_header = $j->MIME_Header;

In which case the resulting C<$mime_header> is MIME-B-encoded UTF-8
whereas C<< $j->mime_encode() >> returnes MIME-B-encoded ISO-2022-JP.
Most modern MUAs support both.

=item $j-E<gt>mime_decode;

Decodes MIME-Header in Jcode object.  For perl 5.8.1 or better, you
can also do the same as:

  Jcode->new($str, 'MIME-Header')

=back

=head2 Hankaku vs. Zenkaku

=over 2

=item $j-E<gt>h2z([$keep_dakuten])

Converts X201 kana (Hankaku) to X208 kana (Zenkaku).  
When $keep_dakuten is set, it leaves dakuten as is
(That is, "ka + dakuten" is left as is instead of
being converted to "ga")

You can retrieve the number of matches via $j->nmatch;

=item $j-E<gt>z2h

Converts X208 kana (Zenkaku) to X201 kana (Hankaku).

You can retrieve the number of matches via $j->nmatch;

=back

=head2 Regexp emulators

To use C<< -E<gt>m() >> and C<< -E<gt>s() >>, you need perl 5.8.1 or
better.

=over 2

=item $j-E<gt>tr($from, $to, $opt);

Applies C<tr/$from/$to/> on Jcode object where $from and $to are
eucJP-ms strings.  On perl 5.8.1 or better, $from and $to can 
also be flagged UTF-8 strings.

If C<$opt> is set, C<tr/$from/$to/$opt> is applied.  C<$opt> must
be 'c', 'd' or the combination thereof.

You can retrieve the number of matches via $j->nmatch;

The following methods are available only for perl 5.8.1 or better.

=item $j-E<gt>s($patter, $replace, $opt);

Applies C<s/$pattern/$replace/$opt>. C<$pattern> and C<replace> must
be in eucJP-ms or flagged UTF-8. C<$opt> are the same as regexp options.
See L<perlre> for regexp options.

Like C<< $j->tr() >>, C<< $j->s() >> returns the object itself so
you can nest the operation as follows;

  $j->tr("a-z", "A-Z")->s("foo", "bar");

=item  [@match = ] $j-E<gt>m($pattern, $opt);

Applies C<m/$patter/$opt>.  Note that this method DOES NOT RETURN
AN OBJECT so you can't chain the method like  C<< $j->s() >>.

=back

=head2 Instance Variables

If you need to access instance variables of Jcode object, use access
methods below instead of directly accessing them (That's what OOP
is all about)

FYI, Jcode uses a ref to array instead of ref to hash (common way) to
optimize speed (Actually you don't have to know as long as you use
access methods instead;  Once again, that's OOP)

=over 2

=item $j-E<gt>r_str

Reference to the EUC-coded String.

=item $j-E<gt>icode

Input charcode in recent operation.

=item $j-E<gt>nmatch

Number of matches (Used in $j->tr, etc.)

=back

=cut

=head1 Subroutines

=over 2

=item ($code, [$nmatch]) = getcode($str)

Returns char code of $str. Return codes are as follows

 ascii   Ascii (Contains no Japanese Code)
 binary  Binary (Not Text File)
 euc     eucJP-ms
 sjis    SHIFT_JIS
 jis     JIS (ISO-2022-JP)
 ucs2    UCS2 (Raw Unicode)
 utf8    UTF8

When array context is used instead of scaler, it also returns how many
character codes are found.  As mentioned above, $str can be \$str
instead.

B<jcode.pl Users:>  This function is 100% upper-conpatible with 
jcode::getcode() -- well, almost;

 * When its return value is an array, the order is the opposite;
   jcode::getcode() returns $nmatch first.

 * jcode::getcode() returns 'undef' when the number of EUC characters
   is equal to that of SJIS.  Jcode::getcode() returns EUC.  for
   Jcode.pm there is no in-betweens. 

=item Jcode::convert($str, [$ocode, $icode, $opt])

Converts $str to char code specified by $ocode.  When $icode is specified
also, it assumes $icode for input string instead of the one checked by
getcode(). As mentioned above, $str can be \$str instead.

B<jcode.pl Users:>  This function is 100% upper-conpatible with 
jcode::convert() !

=back

=head1 BUGS

For perl is 5.8.1 or later, Jcode acts as a wrapper to L<Encode>.
Meaning Jcode is subject to bugs therein.

=head1 ACKNOWLEDGEMENTS

This package owes a lot in motivation, design, and code, to the jcode.pl 
for Perl4 by Kazumasa Utashiro <utashiro@iij.ad.jp>.

Hiroki Ohzaki <ohzaki@iod.ricoh.co.jp> has helped me polish regexp from the 
very first stage of development.

JEncode by makamaka@donzoko.net has inspired me to integrate Encode to
Jcode.  He has also contributed Japanese POD.

And folks at Jcode Mailing list <jcode5@ring.gr.jp>.  Without them, I
couldn't have coded this far.

=head1 SEE ALSO

L<Encode>

L<Jcode::Nihongo>

L<http://www.iana.org/assignments/character-sets>

=head1 COPYRIGHT

Copyright 1999-2005 Dan Kogai <dankogai@dan.co.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
