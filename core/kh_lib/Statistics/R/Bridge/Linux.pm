#############################################################################
## This file was generated automatically by Class::HPLOO/0.12
##
## Original file:    ./lib/Statistics/R/Bridge/Linux.hploo
## Generation date:  2004-02-23 22:13:23
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        Win32.pm
## Purpose:     Statistics::R::Bridge::Win32
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-01-29
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


  use Statistics::R::Bridge::pipe ;

{ package Statistics::R::Bridge::Linux ;

  use strict qw(vars) ; no warnings ;

  use vars qw(@ISA) ; push(@ISA , qw(Statistics::R::Bridge::pipe UNIVERSAL)) ;

  my (%CLASS_HPLOO , $this) ;
 
  sub new { 
    my $class = shift ;
    my $this = bless({} , $class) ;
    my $undef = \'' ;
    sub UNDEF {$undef} ;
    my $ret_this = defined &Linux ? $this->Linux(@_) : undef ;
    $this = $ret_this if ( UNIVERSAL::isa($ret_this,$class) ) ;
    $this = undef if ( $ret_this == $undef ) ;
    if ( $this && $CLASS_HPLOO{ATTR} ) {
    foreach my $Key ( keys %{$CLASS_HPLOO{ATTR}} ) {
    tie( $this->{$Key} => 'Class::HPLOO::TIESCALAR' , $CLASS_HPLOO{ATTR}{$Key}{tp} , $CLASS_HPLOO{ATTR}{$Key}{pr} , \$this->{CLASS_HPLOO_ATTR}{$Key} ) if !exists $this->{$Key} ;
    } } return $this ;
  }


  use vars qw($VERSION) ;
  
  $VERSION = 0.02 ;
  
  sub Linux { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my %args = @_ ;
    @_ = () ;
    
    $this->{R_BIN}   = $args{r_bin} || $args{R_bin} ;
    $this->{R_DIR}   = $args{r_dir} || $args{R_dir} ;
    $this->{TMP_DIR} = $args{tmp_dir} ;
    
    if ( !-s $this->{R_BIN} ) {
      my @files = qw(R R-project Rproject) ;
      ## my @path = (split(":" , $ENV{PATH} || $ENV{Path} || $ENV{path} ) , '/usr/lib/R/bin' , '/usr/lib/R/bin' ) ;
    # CHANGE MADE BY CTBROWN 2008-06-16
    # RESPONSE TO RT BUG#23948: bug in Statistics::R
      my @path = (split(":" , $ENV{PATH} || $ENV{Path} || $ENV{path} ) , '/usr/lib/R/bin' ) ;
      
      my $bin ;
      while( !$bin && @files ) {
        $bin = $this->find_file(shift(@files) , @path) ;
      }
      
      if ( !$bin ) {
        my $path = `which R` ;
        $path =~ s/^\s+//s ;
        $path =~ s/\s+$//s ;
        if ( -e $path && -x $path ) { $bin = $path ;}
      }
      
      $this->{R_BIN} = $bin ;
    }
    
    if ( !$this->{R_DIR} && $this->{R_BIN} ) {
      ($this->{R_DIR}) = ( $this->{R_BIN} =~ /^(.*?)[\\\/]+[^\\\/]+$/s );
      $this->{R_DIR} =~ s/\/bin$// ;
    }
    
    if ( !$this->{TMP_DIR} ) {
      foreach my $dir (qw(/tmp /usr/local/tmp)) {
        if ( -d $dir ) { $this->{TMP_DIR} = $dir ; last ;}
      }
    }
    
    if ( !-s $this->{R_BIN} ) { $this->error("Can'find R binary!") ; return UNDEF ;}
    if ( !-d $this->{R_DIR} ) { $this->error("Can'find R directory!") ; return UNDEF ;}
    
    $this->{START_CMD} = "$this->{R_BIN} --slave --vanilla " ;
    
    if ( !$args{log_dir} ) { $args{log_dir} = "$this->{TMP_DIR}/Statistics-R" ;}
    
    $this->{OS} = 'linux' ;
    
    $this->SUPER::pipe(%args) ;
  }
  
  sub find_file { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; &Statistics::R::Bridge::find_file ;}
  sub cat_dir { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; &Statistics::R::Bridge::cat_dir ;}
  sub error { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; &Statistics::R::error ;}


}



1;

__END__

=head1 NAME

Statistics::R::Bridge::Linux - Handles R on Linux.

=head1 DESCRIPTION

This will handle R on Linux.

=head1 SEE ALSO

L<Statistics::R>, L<Statistics::R::Bridge>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

