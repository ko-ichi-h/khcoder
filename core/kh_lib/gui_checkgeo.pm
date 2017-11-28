package gui_checkgeo;

use strict;

my $monitors;

sub init{
	require Win32::API;
	require Win32::API::Callback;

	Win32::API::Struct->typedef( RECT => qw{
									LONG Left; 
									LONG Top;
									LONG Right;
									LONG Bottom; });
	Win32::API::Struct->typedef( MONITORINFO => qw{
									LONG cbSize; 
									RECT rcMonitor;
									RECT rcWork;
									LONG dwFlags; });

	Win32::API->Import('User32', 'EnumDisplayMonitors', 'NPKN', 'N');
	Win32::API->Import('User32', 'int GetMonitorInfoA (int hMonitor, LPMONITORINFO lpmi)');
	
	my $MonitorEnumProc = Win32::API::Callback->new(
		sub {
			my( $hMonitor, $hdcMonitor, $lprcMonitor, $dwData) = @_;
			
			my $MI	 = Win32::API::Struct->new('MONITORINFO');
			my $R	  = Win32::API::Struct->new('RECT');
			$MI->{cbSize} = 40;
			GetMonitorInfoA ($hMonitor, $MI);
			my $mon;
			$mon->{l} = $MI->{rcMonitor}->{Left};
			$mon->{r} = $MI->{rcMonitor}->{Right};
			$mon->{t} = $MI->{rcMonitor}->{Top};
			$mon->{b} = $MI->{rcMonitor}->{Bottom};
			push @{$monitors}, $mon;
			return 1;
		},
		"NNPN", "N",
	);
	EnumDisplayMonitors ( 0x0, 0x0, $MonitorEnumProc, 0x0  );

	my $t = 'Monitors';
	foreach my $i (@{$monitors}){
		$t .= ": $i->{l}, $i->{r}, $i->{t}, $i->{b} ";
	}
	print "$t\n";
}

sub check{
	my $x = shift;
	my $y = shift;
	
	&init unless $monitors;
	
	my $r = 0;
		
	foreach my $i (@{$monitors}){
		if (
			   $x >= $i->{l}
			&& $x <= $i->{r}
			&& $y >= $i->{t}
			&& $y <= $i->{b}
		){
			$r = 1;
			last;
		}
	}
	
	return $r;
}

1;