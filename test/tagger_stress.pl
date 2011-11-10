# stanford pos taggerのストレステスト

	# クライアントの準備
	use Net::Telnet;
	$self->{client} = undef;
	while (not $self->{client}){
		$self->{client} = new Net::Telnet(
			Host => 'localhost',
			Port => 2020,
			Errmode => 'return',
		);
		sleep 1;
		print "new-ok, ";
	}
	while ( not $self->{client}->open ){
		sleep 1;
		print ".";
	}
	print "open-ok\n";
	$self->{client}->close;

	# ストレステストの開始
	my $nn = 0;
	while (1){
		my $n = 0;
		while ( not $self->{client}->open ){
			++$n;
			sleep 1;
			print " .";
			die("Cannot connect to the Server! nn: $nn\n") if $n > 10;
		}

		$self->{client}->print( "I loved you!" );
		my @lines = $self->{client}->getlines;
		$self->{client}->close;
		++$nn;
		
		if ($nn % 1000 == 0){
			print "nn: $nn\n";
		}
	}

