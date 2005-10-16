#############################################################################
## This file was generated automatically by Class::HPLOO/0.12
##
## Original file:    ./lib/Statistics/R/Bridge/pipe.hploo
## Generation date:  2004-02-23 22:13:24
##
## ** Do not change this file, use the original HPLOO source! **
#############################################################################

#############################################################################
## Name:        pipe.pm
## Purpose:     Statistics::R::Bridge::pipe
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-01-29
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################
#qw(dump nice) ;

{ package Statistics::R::Bridge::pipe ;

  use strict qw(vars) ; no warnings ;

  my (%CLASS_HPLOO , $this) ;
  my $debug = 0; # kh

  sub new { 
    my $class = shift ;
    my $this = bless({} , $class) ;
    my $undef = \'' ;
    sub UNDEF {$undef} ;
    my $ret_this = defined &pipe ? $this->pipe(@_) : undef ;
    $this = $ret_this if ( UNIVERSAL::isa($ret_this,$class) ) ;
    $this = undef if ( $ret_this == $undef ) ;
    if ( $this && $CLASS_HPLOO{ATTR} ) {
    foreach my $Key ( keys %{$CLASS_HPLOO{ATTR}} ) {
    tie( $this->{$Key} => 'Class::HPLOO::TIESCALAR' , $CLASS_HPLOO{ATTR}{$Key}{tp} , $CLASS_HPLOO{ATTR}{$Key}{pr} , \$this->{CLASS_HPLOO_ATTR}{$Key} ) if !exists $this->{$Key} ;
    } } return $this ;
  }


  use IO::Select ;
  
  use vars qw($VERSION $HOLD_PIPE_X) ;
  
  $VERSION = 0.01 ;
  
  sub pipe { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my %args = @_ ;
    @_ = () ;
    
    $this->{LOG_DIR} = $args{log_dir} || "$this->{TMP_DIR}/Statistics-R" ;
    
    if ( !-e $this->{LOG_DIR} ) { mkdir($this->{LOG_DIR} , 0777) ;}
    
    if ( !-d $this->{LOG_DIR} || !-r $this->{LOG_DIR} || !-w $this->{LOG_DIR} ) {
      $this->error("Can't read or write to the directory (LOG_DIR) $this->{LOG_DIR}") ;
      return UNDEF ;
    }
    
    $this->{OUTPUT_DIR} = $args{output_dir} || "$this->{LOG_DIR}/output" ;
    
    if ( !-d $this->{OUTPUT_DIR} || !-e $this->{OUTPUT_DIR} ) { mkdir($this->{OUTPUT_DIR} , 0777) ;}
    
    if ( !-r $this->{OUTPUT_DIR} || !-w $this->{OUTPUT_DIR}) {
      $this->error("Can't read or write to the directory (OUTPUT_DIR) $this->{OUTPUT_DIR}") ;
      return UNDEF ;
    }
    
    $this->{START_R} = "$this->{LOG_DIR}/start.r" ;
    $this->{OUTPUT_R} = "$this->{LOG_DIR}/output.log" ;
    $this->{PROCESS_R} = "$this->{LOG_DIR}/process.log" ;
    $this->{PID_R} = "$this->{LOG_DIR}/R.pid" ;
    $this->{LOCK_R} = "$this->{LOG_DIR}/lock.pid" ;
    $this->{STARTING_R} = "$this->{LOG_DIR}/R.starting" ;
    $this->{STOPING_R} = "$this->{LOG_DIR}/R.stoping" ;
    
    if ( $this->{OS} eq 'win32' ) {
      $this->{START_R} =~ s/\//\\/g ;
      $this->{OUTPUT_R} =~ s/\//\\/g ;
      $this->{PROCESS_R} =~ s/\//\\/g ;
      $this->{PID_R} =~ s/\//\\/g ;
      $this->{LOCK_R} =~ s/\//\\/g ;
      $this->{STARTING_R} =~ s/\//\\/g ;
      $this->{STOPING_R} =~ s/\//\\/g ;
    }
    
  }

  sub send {
	if ($::config_obj){                                   # kh
		if ($::config_obj->os eq 'linux'){                # kh
			require Time::HiRes;                          # kh
			Time::HiRes::sleep(0.05);                     # kh
		}                                                 # kh
	}                                                     # kh

    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my $cmd = shift(@_) ;
    
    $cmd =~ s/\r\n?/\n/gs ;
    $cmd .= "\n" if $cmd !~ /\n$/ ;
    $cmd =~ s/\n/\r\n/gs ;

    print "Statistics::R::Bridge::pipe::send cmd: $cmd" if $debug; # kh
    
    while ( $this->is_blocked ) { sleep(1) ;}
    
    my $n = $this->read_processR ;
    $n = 1 if $n eq '0' || $n eq '' ;
    
    my $file = "$this->{LOG_DIR}/input.$n.r" ;
    
    while( -e $file || -e "$file._" ) {
      ++$n ;
      $file = "$this->{LOG_DIR}/input.$n.r" ;
    }

    open (my $fh,">$file._") ;
    print $fh "$cmd\n" ;
    close ($fh) ;
    chmod(0777 , "$file._") ;
    $this->{OUTPUT_R_POS} = -s $this->{OUTPUT_R} ;

	print "Statistics::R::Bridge::pipe::send, size: $this->{OUTPUT_R_POS}\n" if $debug; # kh

    rename("$file._" , $file) ;
    
    my $has_quit = 1 if $cmd =~ /^\s*(?:q|quit)\s*\(.*?\)\s*$/s ;
    
    ##print "CMD[$n]$has_quit>> $cmd\n" if $debug;
    
    my $status = 1 ;
    my $delay = 0.02 ;
    
    my ($x,$xx) ;
    while (
		   (!$has_quit || $this->{STOPING} == 1)
		&& -e $file
		&& $this->is_started( !$this->{STOPING} )
	) {
      ++$x ;
      print "sleep $file\n" if $debug;
      select(undef,undef,undef,$delay) ;
      if ( $x == 20 ) {
        my (undef , $data) = $this->read_processR ;
        if ( $data =~ /\s$n\s+\.\.\.\s+\// ) { last ;}
        $x = 0 ;
        ++$xx ;
        $delay = 0.5 ;
      }
      if ( $xx > 5 ) { $status = undef ;} ## xx > 5 = x > 50
    }

	unless ($has_quit){
		print "Statistics::R::Bridge::pipe::send, checking output " if $debug;
		while (-s $this->{OUTPUT_R} == $this->{OUTPUT_R_POS}){
			print -s $this->{OUTPUT_R},"," if $debug;
			sleep 1;
		}
		print "...ok\n" if $debug;
	}

    if ( $has_quit && !$this->{STOPING} ) { $this->stop(1) ;}

    return $status ;
  }
  
  sub read { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my $timeout = shift(@_) ;

	#print "Statistics::R::Bridge::pipe::read, file: $this->{OUTPUT_R} pos: $this->{OUTPUT_R_POS} \n" if $debug; # kh

    $timeout = -1 if $timeout eq '' ;

	open (my $fh, $this->{OUTPUT_R} );
	binmode($fh);
	seek($fh , ($this->{OUTPUT_R_POS}||0) , 0) ;

	my $time = time ;
	my ($x,$data) ;

    while( $x == 0 || (time-$time) <= $timeout ) {
      ++$x ;
      my $s = -s $this->{OUTPUT_R} ;
      my $r = read($fh , $data , ($s - $this->{OUTPUT_R_POS}) , length($data) ) ;
	print "Statistics::R::Bridge::pipe::read, size: $s, start: $this->{OUTPUT_R_POS}, read: $r, timeout: $timeout \n" if $debug; # kh
	
	
      $this->{OUTPUT_R_POS} = tell($fh) ;
      last if !$r ;
    }
    
    close($fh) ;
    
    my @lines = split(/(?:\r\n?|\n)/s , $data) ;
    
    return @lines if wantarray ;
    return join("\n", @lines) ;
  }
  
  sub clean_log_dir { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    my @dir = $this->cat_dir($this->{LOG_DIR},0,0,1) ;
    foreach my $dir_i ( @dir ) {
      ##print "RM>> $dir_i\n" ;
      unlink $dir_i if $dir_i !~ /R\.(?:starting|stoping)$/ ;
    }
  }

  sub is_started { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my $can_auto_start = shift(@_) ;
    
    if ( $this->{PID} ) {
      if (kill(0,$this->{PID}) <= 0) {
        $this->update_pid ;
        $this->stop(undef , 1) if (kill(0,$this->{PID}) <= 0) ;
        return 0 ;
      }
      elsif ( !-s $this->{PID_R} ) {
        $this->sleep_unsync ;

        if ( $can_auto_start ) {
          $this->wait_stoping ;
          if ( -e $this->{PID_R} ) { $this->wait_starting ;}
        }
        
        if ( -s $this->{PID_R} ) { $this->update_pid ;}
        elsif ($can_auto_start) {
          open (my $fh,">$this->{PID_R}") ; close ($fh) ;
          chmod(0777 , $this->{PID_R}) ;
          $this->stop ;
          return $this->start_shared ;
        }
        else { return ; }
      }
      return 1 ;
    }
    return undef ;
  }
  
  sub lock { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    while ( $this->is_blocked ) { select(undef,undef,undef,0.5) ;}
    
    open (my $fh,">$this->{LOCK_R}") ;
    print $fh "$$\n" ;
    close ($fh) ;
    
    chmod(0777 , $this->{LOCK_R}) ;
    
    $this->{LOCK} = 1 ;
  }
  
  sub unlock { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    return if $this->is_blocked ;
    unlink( $this->{LOCK_R} ) ;
    return 1 ;
  }
  
  sub is_blocked { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    return undef if ( $this->{LOCK} || !-e $this->{LOCK_R} || !-s $this->{LOCK_R} ) ;
    
    open (my $fh, $this->{LOCK_R}) ;
    my $pid = join '' , <$fh> ;
    close ($fh) ;
    $pid =~ s/\s//gs ;
    
    return undef if $pid == $$ ;
    
    if ( !kill(0,$pid) ) { unlink( $this->{LOCK_R} ) ; return undef ;}
    return 1 ;
  }
  
  sub update_pid { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    open (my $fh, $this->{PID_R}) ;
    my $pid = join '' , <$fh> ;
    close ($fh) ;
    $pid =~ s/\s//gs ;
    return $this->{PID} if $pid eq '' ;
    $this->{PID} = $pid ;
  }
  
  sub chmod_all { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    chmod(0777 , $this->{LOG_DIR} , $this->{OUTPUT_DIR} , $this->{START_R} , $this->{OUTPUT_R} , $this->{PROCESS_R} , $this->{LOCK_R} , $this->{PID_R} ) ;
  }

  sub start { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    return if $this->is_started ;
    
    $this->stop(undef , undef , 1) ;
    $this->clean_log_dir ;
    
    $this->save_file_startR ;
    
    open(my $fh,">$this->{PID_R}") ; close($fh) ;
    open(my $fh,">$this->{OUTPUT_R}") ; close($fh) ;
    open(my $fh,">$this->{PROCESS_R}") ; close($fh) ;
    
    $this->chmod_all ;
        
    my $cmd = "$this->{START_CMD} <start.r >output.log" ;

    chdir("$this->{LOG_DIR}") ;

    #print "debug: $cmd\n";

    my $pid = open(my $read , "| $cmd") ;
    return if !$pid ;

    $this->{PIPE} = $read ;

    $this->{HOLD_PIPE_X} = ++$HOLD_PIPE_X ;
    *{"HOLD_PIPE$HOLD_PIPE_X"} = $read ;

    $this->{PID} = $pid ;
        
    $this->chmod_all ;

    while( !-s $this->{PID_R} ) { select(undef,undef,undef,0.05) ;}

    $this->update_pid ;

    while( $this->read_processR() eq '' ) { select(undef,undef,undef,0.10) ;}

    $this->chmod_all ;

    return 1 ;
  }
  
  sub wait_starting { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    {
      my $c ;
      while( -e $this->{STARTING_R} ) {
        ++$c ;
        sleep(1) ;
        if ($c == 10) { return ;}
      }
    }
    
    if ( -s $this->{START_R} && -e $this->{PID_R} && -e $this->{OUTPUT_R} && -e $this->{PROCESS_R} ) {
      my $c ;
      while( -s $this->{PID_R} == 0 || -s $this->{PROCESS_R} == 0 ) {
        ++$c ;
        sleep(1) ;
        if ($c == 10) { return ;}
      }
      return 1 ;
    }
    return ;
  }
  
  sub wait_stoping { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    my $c ;
    while( -e $this->{STOPING_R} ) {
      ++$c ;
      sleep(1) ;
      if ($c == 10) { return ;}
    }
    return 1 ;
  }
  
  sub sleep_unsync { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    my $n = "0." . int(rand(100)) ;
    select(undef,undef,undef,$n) ;
  }
  
  sub start_shared { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my  $no_recall  = shift(@_) ;
    
    return if $this->is_started ;
    $this->{START_SHARED} = 1 ;
    
    $this->wait_stoping ;
    
    $this->wait_starting ;
    
    if ( -s $this->{START_R} && -s $this->{PID_R} && -s $this->{OUTPUT_R} && -s $this->{PROCESS_R} ) {
      delete $this->{PIPE} ;
      
      $this->update_pid ;
      $this->{OUTPUT_R_POS} = 0 ;
      $this->{STOPING} = undef ;
      
      $this->chmod_all ;
      
      if ( $this->is_started ) {
        while( $this->read_processR() eq '' ) { select(undef,undef,undef,0.10) ;}
        return 1 ;
      }
    }
    
    my $starting ;
    if ( !-e $this->{STARTING_R} ) {
      open(my $fh,">$this->{STARTING_R}") ; close($fh) ;
      $starting = 1 ;
    }
    
    if ( $starting ) {
      $this->stop ;
    }
    else {
      $this->sleep_unsync ;
      if ( $this->wait_starting && $no_recall ) {
        unlink($this->{STARTING_R}) ;
        return $this->start_shared(1) ;
      }
    }

    my $stat = $this->start ;
    
    unlink($this->{STARTING_R}) if $starting ;
    
    return $stat ;
  }
  
  sub stop { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my $no_send = shift(@_) ;
    my $not_started = shift(@_) ;
    my $no_stoping_file = shift(@_) ;
    
    my $started = $not_started ? undef : $this->is_started ;
    
    $this->{STOPING} = $started ? 1 : 2 ;

    if ( !$no_stoping_file ) {
      open(my $fh,">$this->{STOPING_R}") ; close($fh) ;
    }
    
    $this->unlock if $started ;
    
    my $pid_old = $this->{PID} ;
    my $pid = $this->update_pid || $pid_old ;
    
    unlink( $this->{PID_R} ) ;
    
    if ( $pid_old && $pid_old != $pid ) {
      for (1..3) { kill(9 , $pid_old) ;}
    }
    
    $this->send(q`q("no",0,TRUE)`) if !$no_send ;    
    
    if ( $pid ) {
      for (1..3) { kill(9 , $pid) ;}
    }
    
    close( *{'HOLD_PIPE' . $this->{HOLD_PIPE_X} } ) ;

    delete $this->{PIPE} ;
    delete $this->{PID} ;
    delete $this->{OUTPUT_R_POS} ;
    
    sleep(1) if !$started ;
    
    unlink($this->{STOPING_R}) ;
    
    $this->clean_log_dir ;
    
    $this->{STOPING} = undef ;
    
    return 1 ;
  }
  
  sub restart { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    $this->stop ;
    $this->start ;
  }
  
  sub read_processR { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    my $s = -s $this->{PROCESS_R} ;
    
    open(my $fh , $this->{PROCESS_R}) ;
    seek($fh, ($s-100) ,0) ;
    
    my $data ;
    my $r = read($fh , $data , 1000) ;
    close($fh) ;

    return if !$r ;
    
    my ($n) = ( $data =~ /(\d+)\s*$/gi );
    $n = 1 if $n eq '' ;
    
    return( $n , $data ) if wantarray ;
    return $n ;
  }
  
  sub save_file_startR { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    open (my $fh,">$this->{START_R}") ;
    
    my $process_r = $this->{PROCESS_R} ;
    $process_r =~ s/\\/\\\\/g ;
    
    my $pid_r = $this->{PID_R} ;
    $pid_r =~ s/\\/\\\\/g ;    
    
	my $r_start_cmd;
	$r_start_cmd .= "print(\"Statistics::R - Perl bridge started!\")\n\n";
	$r_start_cmd .= 'PERLINPUTFILEX = 0'."\n";
	$r_start_cmd .= 'PERLINPUTFILE = ""'."\n";

	$r_start_cmd .= "PERLOUTPUTFILE <- file(\"$process_r\",\"w\")\n";
	$r_start_cmd .= 'cat(0 , "\\n" , file=PERLOUTPUTFILE)'."\n";

	$r_start_cmd .= qq`.Last <- function(x) {`."\n";
	$r_start_cmd .= qq`  cat("/\\n" , file=PERLOUTPUTFILE)`."\n";
	$r_start_cmd .= qq`  unlink(PERLINPUTFILE) ;`."\n";
	$r_start_cmd .= qq`  print("QUIT") ;`."\n";
	$r_start_cmd .= qq`  close(PERLOUTPUTFILE) ;`."\n";
	$r_start_cmd .= qq`  unlink("$process_r") ;`."\n";
	$r_start_cmd .= qq`  unlink("$pid_r") ;`."\n";
	$r_start_cmd .= qq`}`."\n";

	$r_start_cmd .= qq`PERLPIDFILE <- file("$pid_r","w")`."\n";
	$r_start_cmd .= qq`cat( Sys.getpid() , "\\n" , file=PERLPIDFILE)`."\n";
	$r_start_cmd .= qq`close(PERLPIDFILE) ;`."\n";

	$r_start_cmd .= qq`while(1) {`."\n";
	$r_start_cmd .= qq`  PERLINPUTFILEX = PERLINPUTFILEX + 1 ;`."\n";

	$r_start_cmd .= qq`  ##print(PERLINPUTFILEX) ;`."\n";
	$r_start_cmd .= qq`  cat(PERLINPUTFILEX , "\\n" , file=PERLOUTPUTFILE)`."\n";

	$r_start_cmd .= qq`  PERLINPUTFILE <- paste("input.", PERLINPUTFILEX , ".r" , sep="") ;`."\n";

	$r_start_cmd .= qq`  ##print(PERLINPUTFILE) ;`."\n";

	$r_start_cmd .= qq`  PERLSLEEPDELAY = 0.01`."\n";
	$r_start_cmd .= qq`  PERLSLEEPDELAYX = 0 ;`."\n";

	$r_start_cmd .= qq`  while( file.access(PERLINPUTFILE, mode=0) ) {`."\n";
	$r_start_cmd .= qq`    ##print(PERLINPUTFILE);`."\n";
	$r_start_cmd .= qq`    Sys.sleep(PERLSLEEPDELAY) ;`."\n";

	$r_start_cmd .= qq`    ## Change the delays to process fast consecutive files,`."\n";
	$r_start_cmd .= qq`    ## but without has a small sleep() time after some time`."\n";
	$r_start_cmd .= qq`    ## without process files, soo, will save CPU.`."\n";

	$r_start_cmd .= qq`    if ( PERLSLEEPDELAYX < 165 ) {`."\n";
	$r_start_cmd .= qq`      PERLSLEEPDELAYX = PERLSLEEPDELAYX + 1 ;`."\n";
	$r_start_cmd .= qq`      if      (PERLSLEEPDELAYX == 50)  { PERLSLEEPDELAY = 0.1 } ## 0.5s`."\n";
	$r_start_cmd .= qq`      else if (PERLSLEEPDELAYX == 100) { PERLSLEEPDELAY = 0.5 } ## 5.5s`."\n";
	$r_start_cmd .= qq`      else if (PERLSLEEPDELAYX == 120) { PERLSLEEPDELAY = 1 }   ## 15.5s`."\n";
	$r_start_cmd .= qq`      else if (PERLSLEEPDELAYX == 165) { PERLSLEEPDELAY = 2 }   ## 60.5s`."\n";
	$r_start_cmd .= qq`      else if (PERLSLEEPDELAYX == 195) { PERLSLEEPDELAY = 3 }   ## 120.5s`."\n";
	$r_start_cmd .= qq`    }`."\n";
	$r_start_cmd .= qq`  }`."\n";

	$r_start_cmd .= qq`  cat("...\\n" , file=PERLOUTPUTFILE)`."\n";

	$r_start_cmd .= qq`  tryCatch( source(PERLINPUTFILE) , error = function(e) { print(e) } ) ;`."\n";

  ## Ensure that device is off after execute the input file.
  ##tryCatch( dev.off() , error = function(e) {} ) ;

	$r_start_cmd .= qq`  cat("/\\n" , file=PERLOUTPUTFILE)`."\n";

	$r_start_cmd .= qq`  unlink(PERLINPUTFILE) ;`."\n";

	$r_start_cmd .= qq`  if (PERLINPUTFILEX > 1000) {`."\n";
	$r_start_cmd .= qq`    PERLINPUTFILEX = 0 ;`."\n";
	$r_start_cmd .= qq`    close(PERLOUTPUTFILE) ;`."\n";
	$r_start_cmd .= qq`    PERLOUTPUTFILE <- file("$process_r","w") ;`."\n";
	$r_start_cmd .= qq`  }`."\n";
	$r_start_cmd .= qq`}`."\n";

	$r_start_cmd .= qq`close(PERLOUTPUTFILE) ;`."\n";

	print $fh $r_start_cmd;
    close($fh) ;
    chmod(0777 , $this->{START_R}) ;
  }
  
  sub DESTROY { 
    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    
    $this->unlock ;
    $this->stop if !$this->{START_SHARED} ;
  }


}



1;

__END__

=head1 NAME

Statistics::R::Bridge::pipe - Base class for pipe communication with R.

=head1 DESCRIPTION

This will implement a pipe communication with R.

=head1 SEE ALSO

L<Statistics::R>, L<Statistics::R::Bridge>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

