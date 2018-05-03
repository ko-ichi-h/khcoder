package ptb_tokenizer_en;

# Converted the Penn Treebank Tokenizer sed script into a Perl library.
# $result = ptb_tokenizer_en::Run('one sentence.')

use strict;
use Symbol;
use vars qw{ $CondReg $doAutoPrint $doOpenWrite $doPrint };
$doAutoPrint = 1;
$doOpenWrite = 1;

# Run: the sed loop reading input and applying the script
#
sub Run{

	my $d = shift;
	$d =~ s/>(\S)/> $1/g;
	$d =~ s/(\S)</$1 </g;

    my( $h, $icnt, $s, $n );
    # hack (not unbreakable :-/) to avoid // matching an empty string
    my $z = "\000"; $z =~ /$z/;
    # Initialize.
    $CondReg = 0;
    $doPrint = $doAutoPrint;
CYCLE:
    # while( getsARGV() ){ # kh
    # foreach my $i ( @{$d} ){
    $_ = $d;
	chomp();
	#print "input: $_\n";
	$CondReg = 0;   # cleared on t
BOS:;
# #!/bin/sed -f
# # Sed script to produce Penn Treebank tokenization on arbitrary raw text.
# # Yeah, sure.
# # expected input: raw text with ONE SENTENCE TOKEN PER LINE
# # by Robert MacIntyre, University of Pennsylvania, late 1995.
# # If this wasn't such a trivial program, I'd include all that stuff about
# # no warrantee, free use, etc. from the GNU General Public License.  If you
# # want to be picky, assume that all of its terms apply.  Okay?
# # attempt to get correct directional quotes
# s=^"=`` =g
{ $s = s =^"=`` =sg;
  $CondReg ||= $s;
}
# s=\([ ([{<]\)"=\1 `` =g
{ $s = s =([ ([{])"=${1} `` =sg;
  $CondReg ||= $s;
}
# # close quotes handled at end
# s=\.\.\.= ... =g
{ $s = s =\.\.\.= ... =sg;
  $CondReg ||= $s;
}
# s=[,;:@#$%&]= & =g
{ $s = s =[,;:@#\$%&]= $& =sg;
  $CondReg ||= $s;
}
# # Assume sentence tokenization has been done first, so split FINAL periods
# # only. 
# s=\([^.]\)\([.]\)\([])}>"']*\)[ 	]*$=\1 \2\3 =g
{ $s = s =([^.])([.])([])}"']*)[ \t]*$=${1} ${2}${3} =sg;
  $CondReg ||= $s;
}
# # however, we may as well split ALL question marks and exclamation points,
# # since they shouldn't have the abbrev.-marker ambiguity problem
# s=[?!]= & =g
{ $s = s =[?!]= $& =sg;
  $CondReg ||= $s;
}
# # parentheses, brackets, etc.
# s=[][(){}<>]= & =g
{ $s = s =[][(){}]= $& =sg;
  $CondReg ||= $s;
}
# # Some taggers, such as Adwait Ratnaparkhi's MXPOST, use the parsed-file
# # version of these symbols.
# # UNCOMMENT THE FOLLOWING 6 LINES if you're using MXPOST.
# # s/(/-LRB-/g
# # s/)/-RRB-/g
# # s/\[/-LSB-/g
# # s/\]/-RSB-/g
# # s/{/-LCB-/g
# # s/}/-RCB-/g
# s=--= -- =g
{ $s = s =--= -- =sg;
  $CondReg ||= $s;
}
# # NOTE THAT SPLIT WORDS ARE NOT MARKED.  Obviously this isn't great, since
# # you might someday want to know how the words originally fit together --
# # but it's too late to make a better system now, given the millions of
# # words we've already done "wrong".
# # First off, add a space to the beginning and end of each line, to reduce
# # necessary number of regexps.
# s=$= =
{ $s = s =$= =s;
  $CondReg ||= $s;
}
# s=^= =
{ $s = s =^= =s;
  $CondReg ||= $s;
}
# s="= '' =g
{ $s = s ="= '' =sg;
  $CondReg ||= $s;
}
# # possessive or close-single-quote
# s=\([^']\)' =\1 ' =g
{ $s = s =([^'])' =${1} ' =sg;
  $CondReg ||= $s;
}
# # as in it's, I'm, we'd
# s='\([sSmMdD]\) = '\1 =g
{ $s = s ='([sSmMdD]) = '${1} =sg;
  $CondReg ||= $s;
}
# s='ll = 'll =g
{ $s = s ='ll = 'll =sg;
  $CondReg ||= $s;
}
# s='re = 're =g
{ $s = s ='re = 're =sg;
  $CondReg ||= $s;
}
# s='ve = 've =g
{ $s = s ='ve = 've =sg;
  $CondReg ||= $s;
}
# s=n't = n't =g
{ $s = s =n't = n't =sg;
  $CondReg ||= $s;
}
# s='LL = 'LL =g
{ $s = s ='LL = 'LL =sg;
  $CondReg ||= $s;
}
# s='RE = 'RE =g
{ $s = s ='RE = 'RE =sg;
  $CondReg ||= $s;
}
# s='VE = 'VE =g
{ $s = s ='VE = 'VE =sg;
  $CondReg ||= $s;
}
# s=N'T = N'T =g
{ $s = s =N'T = N'T =sg;
  $CondReg ||= $s;
}
# s= \([Cc]\)annot = \1an not =g
{ $s = s = ([Cc])annot = ${1}an not =sg;
  $CondReg ||= $s;
}
# s= \([Dd]\)'ye = \1' ye =g
{ $s = s = ([Dd])'ye = ${1}' ye =sg;
  $CondReg ||= $s;
}
# s= \([Gg]\)imme = \1im me =g
{ $s = s = ([Gg])imme = ${1}im me =sg;
  $CondReg ||= $s;
}
# s= \([Gg]\)onna = \1on na =g
{ $s = s = ([Gg])onna = ${1}on na =sg;
  $CondReg ||= $s;
}
# s= \([Gg]\)otta = \1ot ta =g
{ $s = s = ([Gg])otta = ${1}ot ta =sg;
  $CondReg ||= $s;
}
# s= \([Ll]\)emme = \1em me =g
{ $s = s = ([Ll])emme = ${1}em me =sg;
  $CondReg ||= $s;
}
# s= \([Mm]\)ore'n = \1ore 'n =g
{ $s = s = ([Mm])ore'n = ${1}ore 'n =sg;
  $CondReg ||= $s;
}
# s= '\([Tt]\)is = '\1 is =g
{ $s = s = '([Tt])is = '${1} is =sg;
  $CondReg ||= $s;
}
# s= '\([Tt]\)was = '\1 was =g
{ $s = s = '([Tt])was = '${1} was =sg;
  $CondReg ||= $s;
}
# s= \([Ww]\)anna = \1an na =g
{ $s = s = ([Ww])anna = ${1}an na =sg;
  $CondReg ||= $s;
}
# # s= \([Ww]\)haddya = \1ha dd ya =g
# # s= \([Ww]\)hatcha = \1ha t cha =g
# # clean out extra spaces
# s=  *= =g
{ $s = s =  *= =sg;
  $CondReg ||= $s;
}
# s=^ *==g
{ $s = s =^ *==sg;
  $CondReg ||= $s;
}
EOS:    if( $doPrint ){
            return $_;
        } else {
	    $doPrint = $doAutoPrint;
	}
#    }


}


1;