package Statistics::R;

use strict;
use warnings;

use Statistics::R::Bridge;

our $VERSION = '0.08';

my( $this, @ERROR );

sub new {
    my $class = shift;

    if( !defined $this ) {
        $this  = bless( {}, $class );
        $this->R( @_ );

        return unless $this->{ BRIDGE };
    }

    return $this;
}

sub R {
    my $this = shift;
    $this->{ BRIDGE } = Statistics::R::Bridge->new( @_ );
}

sub error {
    my $this = shift;

    if( @_ ) {
        my $e = shift;
        push @ERROR, $e;
        warn $e;
    }

    splice( @ERROR, 0, ( $#ERROR - 10 ) ) if @ERROR > 10;

    return @ERROR if wantarray;
    return $ERROR[ -1 ];
}

sub startR {
    my $this = shift;
    delete $this->{ BRIDGE }->{ START_SHARED };
    $this->{ BRIDGE }->start;
}

sub start_sharedR {
    shift->{ BRIDGE }->start_shared;
}

sub stopR {
    my $this = shift;
    delete $this->{ BRIDGE }->{ START_SHARED };
    $this->{ BRIDGE }->stop;
}

sub restartR {
    shift->{ BRIDGE }->restart;
}

sub Rbin {
    shift->{ BRIDGE }->bin;
}

sub lock {
    my $this = shift;
    #$this->{ BRIDGE }->lock( @_ );
}

sub unlock {
    my $this = shift;
    #shift->{ BRIDGE }->unlock( @_ );
}

sub is_blocked {
    my $this = shift;
    $this->{ BRIDGE }->is_blocked( @_ );
}

sub is_started {
    my $this = shift;
    $this->{ BRIDGE }->is_started;
}

sub send {
    my $this = shift;
    $this->{ BRIDGE }->send( @_ );
}

sub read {
    my $this = shift;
    $this->{ BRIDGE }->read( @_ );
}

sub clean_up {
    shift->send( 'rm(list = ls(all = TRUE))' );
}

1;

__END__

=head1 NAME

Statistics::R - Controls the R (R-project) interpreter through Perl.

=head1 DESCRIPTION

This will permit the control of the the R (R-project) interpreter through Perl in different architectures and OS.

You can for example, start only one instance of the R interpreter and have different Perl process accessing it.

=head1 SYNOPSIS

  use Statistics::R;
  
  my $R = Statistics::R->new();
  
  $R->startR;
  
  $R->send(q`postscript("file.ps" , horizontal=FALSE , width=500 , height=500 , pointsize=1)`);
  $R->send(q`plot(c(1, 5, 10), type = "l")`);
  $R->send(q`dev.off()`);
  $R->send(qq`x = 123 \n print(x)`);

  my $ret = $R->read;
  print "\$ret : $ret\n";

  $R->stopR();

=head1 NEW

When creating the R bridje object (Statistics::R), you can set some options:

=over 4

=item log_dir

The directory where the bridge between R and Perl will be created.

B<R and Perl need to have read and write access to the directory!>

I<By dafault it will be created at I<%TMP_DIR%/Statistics-R>.>

=item r_bin

The path to the R binary.

I<By default the path will be searched in the default installation path of R in the OS.>

=item r_dir

The directory of R.

=item tmp_dir

A temporary directory.

I<By default the temporary directory of the OS will be used/searched.>

=back

=head1 METHODS

=over 4

=item startR

Start R and the communication bridge.

=item start_sharedR

Start R or use an already running communication bridge.

=item stopR

Stop R and the bridge.

=item restartR

stop() and start() R.

=item Rbin

Return the path to the R binary (executable).

=item send ($CMD)

Send some command to be executed inside R. Note that I<$CMD> will be loaded by R with I<source()>

=item read ($TIMEOUT)

Read the output of R for the last group of commands sent to R by I<send()>.

=item lock

Lock the bridge for your PID.

=item unlock

Unlock the bridge if your PID have locked it.

=item is_blocked

Return I<TRUE> if the bridge is blocked for your PID.

In other words, returns I<TRUE> if other process has I<lock()ed> the bridge.

=item is_started

Return I<TRUE> if the R interpreter is started, or still started.

=item clean_up

Clean up the enverioment, removing all the objects.

=item error

Return the last error message.

=back

=head1 INSTALL

To install this package you need to install R in your OS first, since I<Statistics::R> need to find R path to work fine.

A standart installation of R on Win32 and Linux will work fine and detected automatically by I<Statistics::R>.

Download page of R:
L<http://cran.r-project.org/banner.shtml>

Or go to the R web site:
L<http://www.r-project.org/>

=head1 EXECUTION FOR MULTIPLE PROCESS

The main pourpose of I<Statistics::R> is to start a single R interpreter that hear
multiple Perl process.

Note that to do that R and Perl need to be running with the same user/group level.

To start the I<Statistics::R> bridge you can use the script I<statistics-r.pl>:

  $> statistics-r.pl start

From your script you need to use the I<start_sharedR()> option:

  use Statistics::R;
  
  my $R = Statistics::R->new();
  
  $R->start_sharedR;
  
  $R->send('x = 123');
  
  exit;

Note that in the example above the method I<stopR()> wasn't called, sine it will close the bridge.

=head1 SEE ALSO

=over 4

=item * L<Statistics::R::Bridge>

=item * The R-project web site: L<http://www.r-project.org/>

=item * Statistics:: modules for Perl: L<http://search.cpan.org/search?query=Statistics&mode=module>

=back

=head1 AUTHOR

Graciliano M. P. E<lt>gm@virtuasites.com.brE<gt>

=head1 MAINTAINER

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

