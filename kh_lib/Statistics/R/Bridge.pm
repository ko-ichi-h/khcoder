#############################################################################
## This file was generated automatically by Class::HPLOO/0.12
##
## Original file:    ./lib/Statistics/R/Bridge.hploo
## Generation date:  2004-02-23 22:13:23
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        Bridge.pm
## Purpose:     Statistics::R::Bridge
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-01-29
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


{ package Statistics::R::Bridge ;

  use strict qw(vars) ; no warnings ;

  my (%CLASS_HPLOO , $this) ;
 
  sub new { 
    my $class = shift ;
    my $this = bless({} , $class) ;
    my $undef = \'' ;
    sub UNDEF {$undef} ;
    my $ret_this = defined &Bridge ? $this->Bridge(@_) : undef ;
    $this = $ret_this if ( UNIVERSAL::isa($ret_this,$class) ) ;
    $this = undef if ( $ret_this == $undef ) ;
    if ( $this && $CLASS_HPLOO{ATTR} ) {
    foreach my $Key ( keys %{$CLASS_HPLOO{ATTR}} ) {
    tie( $this->{$Key} => 'Class::HPLOO::TIESCALAR' , $CLASS_HPLOO{ATTR}{$Key}{tp} , $CLASS_HPLOO{ATTR}{$Key}{pr} , \$this->{CLASS_HPLOO_ATTR}{$Key} ) if !exists $this->{$Key} ;
    } } return $this ;
  }


  use vars qw($VERSION) ;
  
  $VERSION = 0.01 ;
  
  sub Bridge { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my %args = @_ ;
    @_ = () ;
      
    if ( $^O =~ /^(?:.*?win32|dos)$/i ) {
      require Statistics::R::Bridge::Win32 ;
      $this->{OS} = Statistics::R::Bridge::Win32->new(%args) ;
    }
    else {
      require Statistics::R::Bridge::Linux ;
      $this->{OS} = Statistics::R::Bridge::Linux->new(%args) ;
    }
    
    return UNDEF if !$this->{OS} ;
  }
  
  sub error { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; &Statistics::R::error ;}

  sub start { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    delete $this->{OS}->{START_SHARED} ;
    $this->{OS}->start ;
  }

  sub start_shared { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; $this->{OS}->start_shared ;}

  sub stop { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    delete $this->{OS}->{START_SHARED} ;
    $this->{OS}->stop ;
  }
  
  sub restart { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; $this->{OS}->restart ;}
  
  sub bin { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; $this->{OS}->{R_BIN} ;}
  
  sub lock { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; $this->{OS}->lock(@_) ;}
  sub unlock { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; $this->{OS}->unlock(@_) ;}
  sub is_blocked { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; $this->{OS}->is_blocked(@_) ;}
  
  sub send { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; $this->{OS}->send(@_) ;}
  sub read { my $CLASS_HPLOO ;$CLASS_HPLOO = $this if defined $this ;my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;my $class = ref($this) || __PACKAGE__ ;$CLASS_HPLOO = undef ; $this->{OS}->read(@_) ;}
  
  sub find_file { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my @files = ref($_[0]) eq 'ARRAY' ? @{ shift(@_) } : ( ref($_[0]) eq 'HASH' ? %{ shift(@_) } : shift(@_) ) ;
    my @path = @_ ;
    @_ = () ;
    
    foreach my $path_i ( @path ) {
      foreach my $files_i ( @files ) {
        my $file = "$path_i/$files_i" ;
        return $file if (-e $file && -x $file) ;
      }
    }
  }
  
  sub cat_dir { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    my ( $dir , $cut , $r , $f ) = @_ ;
    $dir =~ s/\\/\//g ;
    
    my @files ;
    
    my @DIR = $dir ;
    foreach my $DIR ( @DIR ) {
      my $DH ;
      opendir ($DH, $DIR);
  
      while (my $filename = readdir $DH) {
        if ($filename ne "\." && $filename ne "\.\.") {
          my $file = "$DIR/$filename" ;
          if ($r && -d $file) { push(@DIR , $file) ;}
          else {
            if (!$f || !-d $file) {
              $file =~ s/^\Q$dir\E\/?//s if $cut ;
              push(@files , $file) ;
            }
          }
        }
      }
      
      closedir ($DH) ;
    }
    
    return( @files ) ;
  }


}



1;

__END__

=head1 NAME

Statistics::R::Bridge - Implements a communication bridge between Perl and R (R-project).

=head1 DESCRIPTION

This will implements a communication bridge between Perl and R (R-project) in different architectures and OS.

=head1 USAGE

B<You shouldn't use this directly. See L<Statistics::R> for usage.>

=head1 METHODS

=over 4

=item start

Start R and the bridge.

=item stop

Stop R and the bridge.

=item restart

stop() and start() R.

=item bin

Return the path to the R binary (executable).

=item send ($CMD)

Send some command to be executed inside R. Note that I<$CMD> will be loaded by R with I<source()>

=item read ($TIMEOUT)

Read the output of R for the last group of commands sent to R by I<send()>.

=item error

Return the last error message.

=back

=head1 SEE ALSO

L<Statistics::R>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

