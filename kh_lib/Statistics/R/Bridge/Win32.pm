#############################################################################
## This file was generated automatically by Class::HPLOO/0.12
##
## Original file:    ./lib/Statistics/R/Bridge/Win32.hploo
## Generation date:  2004-02-23 22:13:24
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

{ package Statistics::R::Bridge::Win32 ;

  use strict qw(vars) ; no warnings ;

  use vars qw(@ISA) ; push(@ISA , qw(Statistics::R::Bridge::pipe UNIVERSAL)) ;

  my (%CLASS_HPLOO , $this) ;
 
  sub new { 
    my $class = shift ;
    my $this = bless({} , $class) ;
    my $undef = \'' ;
    sub UNDEF {$undef} ;
    my $ret_this = defined &Win32 ? $this->Win32(@_) : undef ;
    $this = $ret_this if ( UNIVERSAL::isa($ret_this,$class) ) ;
    $this = undef if ( $ret_this == $undef ) ;
    if ( $this && $CLASS_HPLOO{ATTR} ) {
    foreach my $Key ( keys %{$CLASS_HPLOO{ATTR}} ) {
    tie( $this->{$Key} => 'Class::HPLOO::TIESCALAR' , $CLASS_HPLOO{ATTR}{$Key}{tp} , $CLASS_HPLOO{ATTR}{$Key}{pr} , \$this->{CLASS_HPLOO_ATTR}{$Key} ) if !exists $this->{$Key} ;
    } } return $this ;
  }


  use vars qw($VERSION) ;
  
  $VERSION = 0.01 ;
  
  sub Win32 { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my %args = @_ ;
    @_ = () ;
    
    $this->{R_BIN} = $args{r_bin} || $args{R_bin} ;
    $this->{R_DIR} = $args{r_dir} || $args{R_dir} ;
    $this->{TMP_DIR} = $args{tmp_dir} ;
    
    if ( !-s $this->{R_BIN} ) {
      my $ver_dir = ($this->cat_dir("$ENV{ProgramFiles}/R"))[0] ;
    
      my $bin = "$ver_dir/bin/Rterm.exe" ;
      if ( !-e $bin || !-x $bin ) { $bin = undef ;}
      
      if ( !$bin ) {
        my @dir = $this->cat_dir("$ENV{ProgramFiles}/R",undef,1,1) ;
        foreach my $dir_i ( @dir ) {
          if ( $dir_i =~ /\/Rterm\.exe$/ ) { $bin = $dir_i ; last ;}
        }
      }
      
      if ( !$bin ) {    
        my @files = qw(Rterm.exe) ;
        my @path = (split(";" , $ENV{PATH} || $ENV{Path} || $ENV{path} ) ) ;
        $bin = $this->find_file(\@files , @path) ;
      }
      
      $this->{R_BIN} = $bin ;
    }
    
    if ( !$this->{R_DIR} && $this->{R_BIN} ) {
      ($this->{R_DIR}) = ( $this->{R_BIN} =~ /^(.*?)[\\\/]+[^\\\/]+$/s );
      $this->{R_DIR} =~ s/\/bin$// ;
    }
    
    if ( !$this->{TMP_DIR} ) {
      $this->{TMP_DIR} = $ENV{TMP} || $ENV{TEMP} ;
      if ( !$this->{TMP_DIR} ) {
        foreach my $dir (qw(c:/tmp c:/temp c:/windows/tmp c:/windows/temp)) {
          if ( -d $dir ) { $this->{TMP_DIR} = $dir ; last ;}
        }
      }
    }
    
    if ( !-s $this->{R_BIN} ) { $this->error("Can'find R binary!") ; return UNDEF ;}
    if ( !-d $this->{R_DIR} ) { $this->error("Can'find R directory!") ; return UNDEF ;}
    
    $this->{R_BIN} =~ s/\//\\/g ;
    $this->{R_DIR} =~ s/\//\\/g ;
    $this->{TMP_DIR} =~ s/[\/\\]+/\//g ;
    
    my $exec = $this->{R_BIN} ;
    $exec = "\"$exec\"" if $exec =~ /\s/ ;
    
    $this->{START_CMD} = "$exec --slave --vanilla" ;
    
    if ( !$args{log_dir} ) {
      $args{log_dir} = "$this->{R_DIR}/Statistics-R" ;
      $args{log_dir} =~ s/\\+/\//gs ;
    }
    
    $this->{OS} = 'win32' ;
    
    $this->SUPER::pipe(%args) ;
  }
  
  sub find_file { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; &Statistics::R::Bridge::find_file ;}
  sub cat_dir { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; &Statistics::R::Bridge::cat_dir ;}
  sub error { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; &Statistics::R::error ;}


}



1;

__END__

=head1 NAME

Statistics::R::Bridge::Win32 - Handles R on Win32.

=head1 DESCRIPTION

This will handle R on Win32.

=head1 SEE ALSO

L<Statistics::R>, L<Statistics::R::Bridge>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

