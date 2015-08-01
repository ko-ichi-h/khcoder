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

my $DEBUG_TIMING = 0;

{ package Statistics::R::Bridge::pipe ;

  use strict qw(vars) ; no warnings ;

	require Time::HiRes; # kh

  my (%CLASS_HPLOO , $this) ;
  my $debug  = 0;     # kh
  my $debug2 = 0;     # kh
  my $debug3 = 0;     # kh
  my $flag_retry = 0; # kh

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
  use File::Copy;
  
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
		if ( ($::config_obj->os eq 'linux') || ($DEBUG_TIMING) ){
			Time::HiRes::sleep(0.05);
		}
	}

    my $CLASS_HPLOO ;
    $CLASS_HPLOO = $this if defined $this ;
    my $this = UNIVERSAL::isa($_[0],'UNIVERSAL') ? shift : $CLASS_HPLOO ;
    my $class = ref($this) || __PACKAGE__ ;
    $CLASS_HPLOO = undef ;
    my $cmd = shift(@_) ;
    
    $cmd =~ s/\r\n?/\n/gs ;
    $cmd .= "\n" if $cmd !~ /\n$/ ;
    $cmd =~ s/\n/\r\n/gs ;

	unless ( length($this->{LOG_DIR}) ){
		print "Statistics::R::Bridge::pipe::send, skipping cmd: $cmd" if $debug; # kh
		return UNDEF;
	}

    print "Statistics::R::Bridge::pipe::send, cmd: $cmd" if $debug; # kh
    
    while ( $this->is_blocked ) { sleep(1) ;}
    
    my $n = $this->read_processR ;
    $n = 1 if $n eq '0' || $n eq '' ;
    
    print "Statistics::R::Bridge::pipe::send, n: $n\n" if $debug2;
    
    my $file = "$this->{LOG_DIR}/input.$n.r" ;
    
    while( -e $file || -e "$file._" ) {
      ++$n ;
      $file = "$this->{LOG_DIR}/input.$n.r" ;
    }

    open (my $fh, '>:encoding(utf8)' ,"$file._") ;
    print $fh "$cmd\n" ;
    close ($fh) ;
    chmod(0777 , "$file._") ;
    $this->{OUTPUT_R_POS} = -s $this->{OUTPUT_R} ;

	# Win9xではいったん他のファイルにコピーしないとサイズを読めない
	if (
		   ( $DEBUG_TIMING )
		|| ( ( $^O eq 'MSWin32' ) and not ( Win32::IsWinNT() ) )
	){
		unlink("$this->{LOG_DIR}/temp_out")
			if -e "$this->{LOG_DIR}/temp_out";
		if (-e $this->{OUTPUT_R}) {
			copy($this->{OUTPUT_R}, "$this->{LOG_DIR}/temp_out")
				or warn("i/o error 1: $cmd\n");
			$this->{OUTPUT_R_POS} = -s "$this->{LOG_DIR}/temp_out" ;
		}
	}

	print "Statistics::R::Bridge::pipe::send, size: $this->{OUTPUT_R_POS}\n" if $debug; # kh

    rename("$file._" , $file) ;
    
    my $has_quit = 1 if $cmd =~ /^\s*(?:q|quit)\s*\(.*?\)\s*$/s ;
    
    Time::HiRes::sleep(0.05) if $DEBUG_TIMING;
    
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
      print "sleep $xx $file\n" if $debug;
      select(undef,undef,undef,$delay) ;
      if ( $x == 20 ) {
        my (undef , $data) = $this->read_processR ;
        if ( $data =~ /\s$n\s+\.\.\.\s+\// ) {
        	print "Statistics::R::Bridge::pipe::send, signal from read_processR\n";
        	last;
        }
        $x = 0 ;
        ++$xx ;
        $delay = 0.5 ;
      }
      if ( $xx > 10000 ) {
      	$status = undef ;
      	warn "Could not send the command to R! (Statistics::R::Bridge::pipe::send)\n";
      	last;
      }
    }

	unless ($has_quit){
		if ($Statistics::R::output_chk){
			print "Statistics::R::Bridge::pipe::send, checking output "
				if $debug;
			my $rtc = 0;
			while (1){
				my $s = -s $this->{OUTPUT_R};
				
				# Win9xではいったん他のファイルにコピーしないとサイズを読めない
				if (
					   ( $DEBUG_TIMING )
					|| ( ( $^O eq 'MSWin32' ) and not ( Win32::IsWinNT() ) )
				){
					unlink("$this->{LOG_DIR}/temp_out")
						if -e "$this->{LOG_DIR}/temp_out";
					if (-e $this->{OUTPUT_R}) {
						copy($this->{OUTPUT_R}, "$this->{LOG_DIR}/temp_out")
							or warn("i/o error 2\n");
						$s = -s "$this->{LOG_DIR}/temp_out" ;
					}
				}
				
				if ($s > $this->{OUTPUT_R_POS}){
					last;
				}
				print "$s," if $debug;
				sleep 1;
				++$rtc;
				if ($rtc > 20){
					print "Statistics::R::Bridge::pipe::send: Could not check output...\n";
					last;
				}
			}
			print "...ok\n" if $debug;
		}
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

		# Win9xではいったん他のファイルにコピーしないとサイズを読めない
		if (
			   ( $DEBUG_TIMING )
			|| ( ( $^O eq 'MSWin32' ) and not ( Win32::IsWinNT() ) )
		){
			unlink("$this->{LOG_DIR}/temp_out")
				if -e "$this->{LOG_DIR}/temp_out";
			if (-e $this->{OUTPUT_R}) {
				copy($this->{OUTPUT_R}, "$this->{LOG_DIR}/temp_out")
					or warn("i/o error 3\n");
				$s = -s "$this->{LOG_DIR}/temp_out" ;
			}
		}

      my $r = read($fh , $data , ($s - $this->{OUTPUT_R_POS}) , length($data) ) ;
	print "Statistics::R::Bridge::pipe::read, size: $s, start: $this->{OUTPUT_R_POS}, read: $r, timeout: $timeout \n" if $debug; # kh
	
	
      $this->{OUTPUT_R_POS} = tell($fh) ;
      last if !$r ;
    }
    
    close($fh) ;
    
    my @lines = split(/(?:\r\n?|\n)/s , $data) ;
    
    my @lines2 = ();
    foreach my $i (@lines){
    	if (
    		   $i =~ /\"input\.[0-9]+\.r\"/
    		|| $i =~ /\"mark[0-9]+\"/
    	){
    		next;
    	}
    	push @lines2, $i;
    }
    
    return @lines2 if wantarray ;
    return join("\n", @lines2) ;
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
        

	my $pid; # kh 
	if ($::config_obj->os eq 'win32'){
		# WindowsではWin32::Processを使って起動
		my $r_process;
		require Win32::Process;
		#print "starting R in $this->{LOG_DIR}, $this->{R_BIN}\n";
		Win32::Process::Create(
			$r_process,
			$this->{R_BIN},
			"rterm --slave --vanilla -f start.r",
			0,
			Win32::Process->NORMAL_PRIORITY_CLASS,
			$this->{LOG_DIR},
		) || die("Could not start R!");
		$pid = $r_process->GetProcessID();
		
		$this->{PIPE} = "dummy" ;
		
		$this->{HOLD_PIPE_X} = ++$HOLD_PIPE_X ;
		*{"HOLD_PIPE$HOLD_PIPE_X"} = "dummy" ;

		# Windowsの場合はドライブのファイルシステムをチェック
		require Win32::DriveInfo;
		my @drive_info = Win32::DriveInfo::VolumeInfo (
			substr($::config_obj->cwd, 0, 1)
		);
		unless ($drive_info[3] eq 'NTFS'){
			print "File system: $drive_info[3]\n";
			$DEBUG_TIMING = 1;
		}

	} else {
		chdir("$this->{LOG_DIR}") ;
		my $cmd = "$this->{START_CMD} < start.r > output.log" ;
		$pid = open(my $read , "| $cmd") ;
		return if !$pid ;

		$this->{PIPE} = $read ;

		$this->{HOLD_PIPE_X} = ++$HOLD_PIPE_X ;
		*{"HOLD_PIPE$HOLD_PIPE_X"} = $read ;
	}

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

	if ($::config_obj->os eq 'win32'){ # kh
		
	} else {
		close( *{'HOLD_PIPE' . $this->{HOLD_PIPE_X} } ) ;
	}

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
    
    my $chk_opn1 = 1;
    open(my $fh, '<', $this->{PROCESS_R}) or $chk_opn1 = 0;
    unless ($chk_opn1) {
    	print "Statistics::R::Bridge::pipe::read_processR, could not open file!\n" if $debug2;
    	return('','') if wantarray ;
    	return '';
    }
    
    seek($fh, ($s-100) ,0) ;
    
    my $data ;
    my $r = read($fh , $data , 1000) ;
    close($fh) ;
	print "Statistics::R::Bridge::pipe::read_processR, r: $r\n" if $debug2;
	#print "Statistics::R::Bridge::pipe::read_processR, d: $data\n" if $debug2;

    return if !$r;
	
    my ($n) = ( $data =~ /(\d+)\s*$/gi );
    if ($n eq ''){
    	if ($flag_retry){
    		print "Statistics::R::Bridge::pipe::read_processR, Sleep and Retry!\n";
    		Time::HiRes::sleep(0.8);
    		#sleep(1);
    		print "Statistics::R::Bridge::pipe::read_processR, slept\n" if $debug3;
    		my $s = -s $this->{PROCESS_R};
    		print "Statistics::R::Bridge::pipe::read_processR, size\n" if $debug3;
    		my $chk_opn2 = 1;
    		open(my $fh , '<', $this->{PROCESS_R}) or $chk_opn2 = 0;
			unless ($chk_opn2) {
				print "Statistics::R::Bridge::pipe::read_processR, could not open file!\n" if $debug2;
				return('','') if wantarray ;
				return '';
			}
			print "Statistics::R::Bridge::pipe::read_processR, opened\n" if $debug3;
    		seek($fh, ($s-100) ,0) ;
    		my $data ;
    		my $r = read($fh , $data , 1000) ;
    		close($fh) ;
    		print "Statistics::R::Bridge::pipe::read_processR, closed\n" if $debug3;
    		($n) = ( $data =~ /(\d+)\s*$/gi );
    		print "Statistics::R::Bridge::pipe::read_processR, Retry: $n\n";
    	} else {
    		$n = 1;
    	}
    }
    
    $flag_retry = 1 if $n > 1;
    
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
    my $icode = Jcode::getcode($process_r);
    $process_r = Jcode->new($process_r)->euc;
    $process_r =~ s/\\/\\\\/g ;
    $process_r = Jcode->new($process_r)->$icode
    	if ( length($icode) and ( $icode ne 'ascii' ) );
    
    my $pid_r = $this->{PID_R} ;
    $pid_r = Jcode->new($pid_r)->euc;
    $pid_r =~ s/\\/\\\\/g ;    
    $pid_r = Jcode->new($pid_r)->$icode
    	if ( length($icode) and ( $icode ne 'ascii' ) );
    
	if ($::config_obj->os eq 'win32'){ # kh
		print $fh "sink(file=\"output.log\", append=TRUE )\n";
	}
    
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
        
        PERLSLEEPDELAY = 0.01 ;
        PERLSLEEPDELAYX = 0 ;
        
        options(warn=-1);
        while(
			tryCatch(
				test_open <- file(PERLINPUTFILE,"r") ,
				error = function(e) { return(0) }
			)
			== 0
        ) {
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
        
        try( close(test_open), silent=T );
        try( rm(test_open), silent=T  );
        
        cat("...\\n" , file=PERLOUTPUTFILE) ;
        
        # We have to be sure...
        FILETESTX <- 0 ;
        while(
			tryCatch(
				test_open <- file(PERLINPUTFILE,"r") ,
				error = function(e) { return(0) }
			)
			== 0
        ) {
        	Sys.sleep(0.2) ;
        	FILETESTX <- FILETESTX + 1 ;
        	if (FILETESTX >= 300){
        		print("The file is gone???") ;
        		break ;
        	}
        }
        try( close(test_open), silent=T );
        try( rm(test_open), silent=T  );
        options(warn=1);
        
        tryCatch( eval(parse(PERLINPUTFILE, encoding="UTF-8")) , error = function(e) { print(e) } ) ;
        
        ## Ensure that device is off after execute the input file.
        # tryCatch( dev.off() , error = function(e) {} ) ;

        cat("/\\n" , file=PERLOUTPUTFILE)
        
        unlink(PERLINPUTFILE) ;
        
        # Wait for unlinking the file...
        FILETESTX <- 0 ;
        while( file.access(PERLINPUTFILE, mode=0) == 0 ) {
        	Sys.sleep(0.2) ;
        	FILETESTX <- FILETESTX + 1 ;
        	if (FILETESTX >= 600){
        		print("Could not unlink input file...") ;
        		break ;
        	}
        }
        
        if (PERLINPUTFILEX > 1000) {
          PERLINPUTFILEX = 0 ;
          close(PERLOUTPUTFILE) ;
          PERLOUTPUTFILE <- file("$process_r","w") ;
        }
      }
      
      close(PERLOUTPUTFILE) ;
    ` ;

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

