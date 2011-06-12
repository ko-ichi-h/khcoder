package Statistics::R::Bridge;

use strict;
use warnings;

use IO::Select;

our $VERSION = '0.07';
our $HOLD_PIPE_X;

my $this;

sub new {
    my $class = shift;

    if( !defined $this ) {
        $this = bless( {}, $class );

        my $method = ( $^O =~ /^(?:.*?win32|dos)$/i ) ? 'Win32' : 'Linux';
        $this->$method( @_ );

        return unless $this->{ OS };
    }

    return $this;
}

sub pipe {
    my( $this, %args ) = @_;

    $this->{ LOG_DIR } = $args{ log_dir } || "$this->{TMP_DIR}/Statistics-R";

    if ( !-e $this->{ LOG_DIR } ) { mkdir( $this->{ LOG_DIR }, 0777 ); }

    if (   !-d $this->{ LOG_DIR }
        || !-r $this->{ LOG_DIR }
        || !-w $this->{ LOG_DIR } )
    {
        $this->error(
            "Can't read or write to the directory (LOG_DIR) $this->{LOG_DIR}"
        );
        return undef;
    }

    $this->{ OUTPUT_DIR } = $args{ output_dir } || "$this->{LOG_DIR}/output";

    if ( !-d $this->{ OUTPUT_DIR } || !-e $this->{ OUTPUT_DIR } ) {
        mkdir( $this->{ OUTPUT_DIR }, 0777 );
    }

    if ( !-r $this->{ OUTPUT_DIR } || !-w $this->{ OUTPUT_DIR } ) {
        $this->error(
            "Can't read or write to the directory (OUTPUT_DIR) $this->{OUTPUT_DIR}"
        );
        return undef;
    }

    $this->{ START_R }    = "$this->{LOG_DIR}/start.r";
    $this->{ OUTPUT_R }   = "$this->{LOG_DIR}/output.log";
    $this->{ PROCESS_R }  = "$this->{LOG_DIR}/process.log";
    $this->{ PID_R }      = "$this->{LOG_DIR}/R.pid";
    $this->{ LOCK_R }     = "$this->{LOG_DIR}/lock.pid";
    $this->{ STARTING_R } = "$this->{LOG_DIR}/R.starting";
    $this->{ STOPING_R }  = "$this->{LOG_DIR}/R.stoping";

    if ( $this->{ OS } eq 'win32' ) {
        $this->{ START_R }    =~ s/\//\\/g;
        $this->{ OUTPUT_R }   =~ s/\//\\/g;
        $this->{ PROCESS_R }  =~ s/\//\\/g;
        $this->{ PID_R }      =~ s/\//\\/g;
        $this->{ LOCK_R }     =~ s/\//\\/g;
        $this->{ STARTING_R } =~ s/\//\\/g;
        $this->{ STOPING_R }  =~ s/\//\\/g;
    }

}

sub bin {
    shift->{ R_BIN };
}

sub send {
    my( $this, $cmd ) = @_;

    $cmd =~ s/\r\n?/\n/gs;
    $cmd .= "\n" if $cmd !~ /\n$/;
    $cmd =~ s/\n/\r\n/gs;

    while ( $this->is_blocked ) { sleep( 1 ); }

    my $n = $this->read_processR || 0;
    $n = 1 if $n eq '0' || $n eq '';

    my $file = "$this->{LOG_DIR}/input.$n.r";

    while ( -e $file || -e "$file._" ) {
        ++$n;
        $file = "$this->{LOG_DIR}/input.$n.r";
    }

    open( my $fh, ">$file._" );
    print $fh "$cmd\n";
    close( $fh );

    chmod( 0777, "$file._" );

    $this->{ OUTPUT_R_POS } = -s $this->{ OUTPUT_R };

    rename( "$file._", $file );

    my $has_quit = 1 if $cmd =~ /^\s*(?:q|quit)\s*\(.*?\)\s*$/s;

    ##print "CMD[$n]$has_quit>> $cmd\n" ;

    my $status = 1;
    my $delay  = 0.02;

    my ( $x, $xx );
    while (( !$has_quit || $this->{ STOPING } == 1 )
        && -e $file
        && $this->is_started( !$this->{ STOPING } ) )
    {
        ++$x;
        ##print "sleep $file\n" ;
        select( undef, undef, undef, $delay );
        if ( $x == 20 ) {
            my ( undef, $data ) = $this->read_processR;
            if ( $data =~ /\s$n\s+\.\.\.\s+\// ) { last; }
            $x = 0;
            ++$xx;
            $delay = 0.5;
        }
        if ( $xx || 0 > 5 ) { $status = undef; }    ## xx > 5 = x > 50
    }

    if ( $has_quit && !$this->{ STOPING } ) { $this->stop( 1 ); }

    return $status;
}

sub read {
    my( $this, $timeout ) = @_;

    $timeout = -1 if !defined $timeout;

    open( my $fh, $this->{ OUTPUT_R } );
    binmode( $fh );
    seek( $fh, ( $this->{ OUTPUT_R_POS } || 0 ), 0 );

    my $time = time;
    my ( $x, $data ) = ( 0, '' );

    while ( $x == 0 || ( time - $time ) <= $timeout ) {
        ++$x;
        my $s = -s $this->{ OUTPUT_R };
        my $r = read(
            $fh, $data,
            ( $s - $this->{ OUTPUT_R_POS } ),
            length( $data )
        );
        $this->{ OUTPUT_R_POS } = tell( $fh );
        last if !$r;
    }

    close( $fh );

    my @lines = split( /(?:\r\n?|\n)/s, $data );

    return @lines if wantarray;
    return join( "\n", @lines );
}

sub clean_log_dir {
    my $this = shift;

    my @dir = $this->cat_dir( $this->{ LOG_DIR }, 0, 0, 1 );
    foreach my $dir_i ( @dir ) {
        ##print "RM>> $dir_i\n" ;
        unlink $dir_i if $dir_i !~ /R\.(?:starting|stoping)$/;
    }
}

sub is_started {
    my( $this, $can_auto_start ) = @_;

    return unless $this->{ PID };

    if ( kill( 0, $this->{ PID } ) <= 0 ) {
        $this->update_pid;
        $this->stop( undef, 1 ) if ( kill( 0, $this->{ PID } ) <= 0 );
        return 0;
    }
    elsif ( !-s $this->{ PID_R } ) {
        $this->sleep_unsync;

        if ( $can_auto_start ) {
            $this->wait_stoping;
            if ( -e $this->{ PID_R } ) { $this->wait_starting; }
        }

        if ( -s $this->{ PID_R } ) { $this->update_pid; }
        elsif ( $can_auto_start ) {
            open( my $fh, ">$this->{PID_R}" );
            close( $fh );
            chmod( 0777, $this->{ PID_R } );
            $this->stop;
            return $this->start_shared;
        }
        else { return; }
    }

    return 1;
}

sub lock {
    my $this = shift;

    while ( $this->is_blocked ) { select( undef, undef, undef, 0.5 ); }

    open( my $fh, ">$this->{LOCK_R}" );
    print $fh "$$\n";
    close( $fh );

    chmod( 0777, $this->{ LOCK_R } );

    $this->{ LOCK } = 1;
}

sub unlock {
    my $this = shift;

    return if $this->is_blocked;
    unlink( $this->{ LOCK_R } );
    return 1;
}

sub is_blocked {
    my $this = shift;

    return undef
        if ( $this->{ LOCK }
        || !-e $this->{ LOCK_R }
        || !-s $this->{ LOCK_R } );

    open( my $fh, $this->{ LOCK_R } );
    my $pid = join '', <$fh>;
    close( $fh );
    $pid =~ s/\s//gs;

    return undef if $pid == $$;

    if ( !kill( 0, $pid ) ) { unlink( $this->{ LOCK_R } ); return undef; }
    return 1;
}

sub update_pid {
    my $this = shift;

    open( my $fh, $this->{ PID_R } ) or return $this->{ PID };
    my $pid = join '', <$fh>;
    close( $fh );
    $pid =~ s/\s//gs;
    return $this->{ PID } if $pid eq '';
    $this->{ PID } = $pid;
}

sub chmod_all {
    my $this = shift;

    chmod( 0777,
        $this->{ LOG_DIR },
        $this->{ OUTPUT_DIR },
        $this->{ START_R },
        $this->{ OUTPUT_R },
        $this->{ PROCESS_R },
        $this->{ LOCK_R },
        $this->{ PID_R } );
}

sub start {
    my $this = shift;

    return if $this->is_started;

    $this->stop( undef, undef, 1 );

    $this->clean_log_dir;

    $this->save_file_startR;

    my $fh;

    open( $fh, ">$this->{PID_R}" );
    close( $fh );
    open( $fh, ">$this->{OUTPUT_R}" );
    close( $fh );
    open( $fh, ">$this->{PROCESS_R}" );
    close( $fh );

    $this->chmod_all;

    my $cmd = "$this->{START_CMD} <start.r >output.log";

    chdir( "$this->{LOG_DIR}" );
    my $pid = open( my $read, "| $cmd" );
    return if !$pid;

    $this->{ PIPE } = $read;

    $this->{ HOLD_PIPE_X } = ++$HOLD_PIPE_X;
    {
        no strict 'refs'; # squash more errors
        *{ "HOLD_PIPE$HOLD_PIPE_X" } = $read;
    }

    $this->{ PID } = $pid;

    $this->chmod_all;

    while ( !-s $this->{ PID_R } ) { select( undef, undef, undef, 0.05 ); }

    $this->update_pid;

    while ( $this->read_processR() eq '' ) {
        select( undef, undef, undef, 0.10 );
    }

    $this->chmod_all;

    return 1;
}

sub wait_starting {
    my $this = shift;

    {
        my $c;
        while ( -e $this->{ STARTING_R } ) {
            ++$c;
            sleep( 1 );
            if ( $c == 10 ) { return; }
        }
    }

    if (   -s $this->{ START_R }
        && -e $this->{ PID_R }
        && -e $this->{ OUTPUT_R }
        && -e $this->{ PROCESS_R } )
    {
        my $c;
        while ( -s $this->{ PID_R } == 0 || -s $this->{ PROCESS_R } == 0 ) {
            ++$c;
            sleep( 1 );
            if ( $c == 10 ) { return; }
        }
        return 1;
    }
    return;
}

sub wait_stoping {
    my $this = shift;

    my $c;
    while ( -e $this->{ STOPING_R } ) {
        ++$c;
        sleep( 1 );
        if ( $c == 10 ) { return; }
    }
    return 1;
}

sub sleep_unsync {
    my $this = shift;

    my $n = "0." . int( rand( 100 ) );
    select( undef, undef, undef, $n );
}

sub start_shared {
    my( $this, $no_recall ) = @_;

    return if $this->is_started;
    $this->{ START_SHARED } = 1;

    $this->wait_stoping;

    $this->wait_starting;

    if (   -s $this->{ START_R }
        && -s $this->{ PID_R }
        && -s $this->{ OUTPUT_R }
        && -s $this->{ PROCESS_R } )
    {
        delete $this->{ PIPE };

        $this->update_pid;
        $this->{ OUTPUT_R_POS } = 0;
        $this->{ STOPING }      = undef;

        $this->chmod_all;

        if ( $this->is_started ) {
            while ( $this->read_processR() eq '' ) {
                select( undef, undef, undef, 0.10 );
            }
            return 1;
        }
    }

    my $starting;
    if ( !-e $this->{ STARTING_R } ) {
        open( my $fh, ">$this->{STARTING_R}" );
        close( $fh );
        $starting = 1;
    }

    if ( $starting ) {
        $this->stop;
    }
    else {
        $this->sleep_unsync;
        if ( $this->wait_starting && $no_recall ) {
            unlink( $this->{ STARTING_R } );
            return $this->start_shared( 1 );
        }
    }

    my $stat = $this->start;

    unlink( $this->{ STARTING_R } ) if $starting;

    return $stat;
}

sub stop {
    no warnings; # squash "Killed" warning for now
    my $this = shift;
    my $no_send         = shift( @_ );
    my $not_started     = shift( @_ );
    my $no_stoping_file = shift( @_ );

    my $started = $not_started ? undef : $this->is_started;

    $this->{ STOPING } = $started ? 1 : 2;

    if ( !$no_stoping_file ) {
        open( my $fh, ">$this->{STOPING_R}" );
        close( $fh );
    }

    $this->unlock if $started;

    my $pid_old = $this->{ PID };
    my $pid = $this->update_pid || $pid_old;

    unlink( $this->{ PID_R } );

    if ( $pid_old && $pid_old != $pid ) {
        for ( 1 .. 3 ) { kill( 9, $pid_old ); }
    }

    $this->send( q`q("no",0,TRUE)` ) if !$no_send;

    if ( $pid ) {
        for ( 1 .. 3 ) { kill( 9, $pid ); }
    }

    {
        no strict 'refs'; # squash more errors
        close( *{ 'HOLD_PIPE' . $this->{ HOLD_PIPE_X } } );
    }

    delete $this->{ PIPE };
    delete $this->{ PID };
    delete $this->{ OUTPUT_R_POS };

    sleep( 1 ) if !$started;

    unlink( $this->{ STOPING_R } );

    $this->clean_log_dir;

    $this->{ STOPING } = undef;

    return 1;
}

sub restart {
    my $this = shift;

    $this->stop;
    $this->start;
}

sub read_processR {
    my $this = shift;

    my $s = -s $this->{ PROCESS_R } || 0;

    open( my $fh, $this->{ PROCESS_R } ) || return;
    seek( $fh, ( $s - 100 ), 0 );

    my $data;
    my $r = CORE::read( $fh, $data, 1000 );
    close( $fh );

    return if !$r;

    my ( $n ) = ( $data =~ /(\d+)\s*$/gi );
    $n = 1 unless $n;

    return ( $n, $data ) if wantarray;
    return $n;
}

sub save_file_startR {
    my $this = shift;

    open( my $fh, ">$this->{START_R}" );

    my $process_r = $this->{ PROCESS_R };
    $process_r =~ s/\\/\\\\/g;

    my $pid_r = $this->{ PID_R };
    $pid_r =~ s/\\/\\\\/g;

    print $fh qq`
      print("Statistics::R - Perl bridge started!") ;
      
      PERLINPUTFILEX = 0 ;
      PERLINPUTFILE = "" ;

      PERLOUTPUTFILE <- file("$process_r","w")
      cat(0 , "\\n" , file=PERLOUTPUTFILE)
      
      .Last <- function(x) {
        cat("/\\n" , file=PERLOUTPUTFILE)
        unlink(PERLINPUTFILE) ;
        print("QUIT") ;
        close(PERLOUTPUTFILE) ;
        unlink("$process_r") ;
        unlink("$pid_r") ;
      }
      
      PERLPIDFILE <- file("$pid_r","w")
      cat( Sys.getpid() , "\\n" , file=PERLPIDFILE)
      close(PERLPIDFILE) ;
      
      while(1) {
        PERLINPUTFILEX = PERLINPUTFILEX + 1 ;
        
        ##print(PERLINPUTFILEX) ;
        cat(PERLINPUTFILEX , "\\n" , file=PERLOUTPUTFILE)
        
        PERLINPUTFILE <- paste("input.", PERLINPUTFILEX , ".r" , sep="") ;
        
        ##print(PERLINPUTFILE) ;
        
        PERLSLEEPDELAY = 0.01
        PERLSLEEPDELAYX = 0 ;
        
        while( file.access(PERLINPUTFILE, mode=0) ) {
          ##print(PERLINPUTFILE);
          Sys.sleep(PERLSLEEPDELAY) ;
          
          ## Change the delays to process fast consecutive files,
          ## but without has a small sleep() time after some time
          ## without process files, soo, will save CPU.
          
          if ( PERLSLEEPDELAYX < 165 ) {
            PERLSLEEPDELAYX = PERLSLEEPDELAYX + 1 ;
            if      (PERLSLEEPDELAYX == 50)  { PERLSLEEPDELAY = 0.1 } ## 0.5s
            else if (PERLSLEEPDELAYX == 100) { PERLSLEEPDELAY = 0.5 } ## 5.5s
            else if (PERLSLEEPDELAYX == 120) { PERLSLEEPDELAY = 1 }   ## 15.5s
            else if (PERLSLEEPDELAYX == 165) { PERLSLEEPDELAY = 2 }   ## 60.5s
            else if (PERLSLEEPDELAYX == 195) { PERLSLEEPDELAY = 3 }   ## 120.5s
          }
        }
        
        cat("...\\n" , file=PERLOUTPUTFILE)
        
        tryCatch( source(PERLINPUTFILE) , error = function(e) { print(e) } ) ;
        
        ## Ensure that device is off after execute the input file.
        #tryCatch( dev.off() , error = function(e) {} ) ;

        cat("/\\n" , file=PERLOUTPUTFILE)
        
        unlink(PERLINPUTFILE) ;
      
        if (PERLINPUTFILEX > 1000) {
          PERLINPUTFILEX = 0 ;
          close(PERLOUTPUTFILE) ;
          PERLOUTPUTFILE <- file("$process_r","w") ;
        }
      }
      
      close(PERLOUTPUTFILE) ;
    `;

    close( $fh );

    chmod( 0777, $this->{ START_R } );
}

sub find_file {
    my $this  = shift;
    my @files = ref $_[ 0 ] ? @{ shift() } : shift;
    my @paths = @_;

    for my $path ( @paths ) {
        for my $file ( @files ) {
            my $fn = "$path/$file";
            return $fn if -e $fn && -x $fn;
        }
    }
}

sub cat_dir {
    my $this = shift;

    my ( $dir, $cut, $r, $f ) = @_;
    $dir =~ s/\\/\//g;

    my @files;

    my @DIR = $dir;
    foreach my $DIR ( @DIR ) {
        my $DH;
        opendir( $DH, $DIR );

        while ( my $filename = readdir $DH ) {
            next if $filename eq '.' or $filename eq '..';
            my $file = "$DIR/$filename";
            if ( $r && -d $file ) {
                push( @DIR, $file );
            }
            elsif ( !$f || !-d $file ) {
                $file =~ s/^\Q$dir\E\/?//s if $cut;
                push( @files, $file );
            }
        }

        closedir( $DH );
    }

    return ( @files );
}

sub error {
    my $this = shift;
    Statistics::R->error( @_ );
}

sub Linux {
    my( $this, %args ) = @_;

    $this->{ R_BIN } = $args{ r_bin } || $args{ R_bin } || '';
    $this->{ R_DIR } = $args{ r_dir } || $args{ R_dir } || '';
    $this->{ TMP_DIR } = $args{ tmp_dir } || '';

    if ( !-s $this->{ R_BIN } ) {
        my @files = qw(R R-project Rproject);
        ## my @path = (split(":" , $ENV{PATH} || $ENV{Path} || $ENV{path} ) , '/usr/lib/R/bin' , '/usr/lib/R/bin' ) ;
        # CHANGE MADE BY CTBROWN 2008-06-16
        # RESPONSE TO RT BUG#23948: bug in Statistics::R
        my @path = (
            split( ":", $ENV{ PATH } || $ENV{ Path } || $ENV{ path } ),
            '/usr/lib/R/bin'
        );

        my $bin;
        while ( !$bin && @files ) {
            $bin = $this->find_file( shift( @files ), @path );
        }

        if ( !$bin ) {
            my $path = `which R`;
            $path =~ s/^\s+//s;
            $path =~ s/\s+$//s;
            if ( -e $path && -x $path ) { $bin = $path; }
        }

        $this->{ R_BIN } = $bin;
    }

    if ( !$this->{ R_DIR } && $this->{ R_BIN } ) {
        ( $this->{ R_DIR } )
            = ( $this->{ R_BIN } =~ /^(.*?)[\\\/]+[^\\\/]+$/s );
        $this->{ R_DIR } =~ s/\/bin$//;
    }

    if ( !$this->{ TMP_DIR } ) {
        foreach my $dir ( qw(/tmp /usr/local/tmp) ) {
            if ( -d $dir ) { $this->{ TMP_DIR } = $dir; last; }
        }
    }

    if ( !-s $this->{ R_BIN } ) {
        $this->error( "Can'find R binary!" );
        return undef;
    }
    if ( !-d $this->{ R_DIR } ) {
        $this->error( "Can'find R directory!" );
        return undef;
    }

    $this->{ START_CMD } = "$this->{R_BIN} --slave --vanilla ";

    if ( !$args{ log_dir } ) {
        $args{ log_dir } = "$this->{TMP_DIR}/Statistics-R";
    }

    $this->{ OS } = 'linux';

    $this->pipe( %args );
}

sub Win32 {
    my( $this, %args ) = @_;

    $this->{ R_BIN } = $args{ r_bin } || $args{ R_bin } || '';
    $this->{ R_DIR } = $args{ r_dir } || $args{ R_dir } || '';
    $this->{ TMP_DIR } = $args{ tmp_dir } || '';

    if ( !-s $this->{ R_BIN } ) {
        my $ver_dir = ( $this->cat_dir( "$ENV{ProgramFiles}/R" ) )[ 0 ];

        my $bin = "$ver_dir/bin/Rterm.exe";
        if ( !-e $bin || !-x $bin ) { $bin = undef; }

        if ( !$bin ) {
            my @dir = $this->cat_dir( "$ENV{ProgramFiles}/R", undef, 1, 1 );
            foreach my $dir_i ( @dir ) {
                if ( $dir_i =~ /\/Rterm\.exe$/ ) { $bin = $dir_i; last; }
            }
        }

        if ( !$bin ) {
            my @files = qw(Rterm.exe);
            my @path  = (
                split( ";", $ENV{ PATH } || $ENV{ Path } || $ENV{ path } ) );
            $bin = $this->find_file( \@files, @path );
        }

        $this->{ R_BIN } = $bin;
    }

    if ( !$this->{ R_DIR } && $this->{ R_BIN } ) {
        ( $this->{ R_DIR } )
            = ( $this->{ R_BIN } =~ /^(.*?)[\\\/]+[^\\\/]+$/s );
        $this->{ R_DIR } =~ s/\/bin$//;
    }

    if ( !$this->{ TMP_DIR } ) {
        $this->{ TMP_DIR } = $ENV{ TMP } || $ENV{ TEMP };
        if ( !$this->{ TMP_DIR } ) {
            foreach
                my $dir ( qw(c:/tmp c:/temp c:/windows/tmp c:/windows/temp) )
            {
                if ( -d $dir ) { $this->{ TMP_DIR } = $dir; last; }
            }
        }
    }

    if ( !-s $this->{ R_BIN } ) {
        $this->error( "Can'find R binary!" );
        return undef;
    }
    if ( !-d $this->{ R_DIR } ) {
        $this->error( "Can'find R directory!" );
        return undef;
    }

    $this->{ R_BIN }   =~ s/\//\\/g;
    $this->{ R_DIR }   =~ s/\//\\/g;
    $this->{ TMP_DIR } =~ s/[\/\\]+/\//g;

    my $exec = $this->{ R_BIN };
    $exec = "\"$exec\"" if $exec =~ /\s/;

    $this->{ START_CMD } = "$exec --slave --vanilla";

    if ( !$args{ log_dir } ) {

# $args{log_dir} = "$this->{R_DIR}/Statistics-R" ;
# Bug Fix by CTB:  Reponse to RT Bug #17956: Win32: log_dir is not in tmp_dir by default as advertised
        $args{ log_dir } = "$this->{TMP_DIR}/Statistics-R";
        $args{ log_dir } =~ s/\\+/\//gs;
    }

    $this->{ OS } = 'win32';

    $this->pipe( %args );
}

sub DESTROY {
    my $this = shift;

    return unless $this->{ OS };

    $this->unlock;
    $this->stop if !$this->{ START_SHARED };
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

=over 4 

=item * L<Statistics::R>

=back 

=head1 AUTHOR

Graciliano M. P. E<lt>gm@virtuasites.com.brE<gt>

=head1 MAINTAINER

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

