package gui_wait;
use strict;
use Tk;
use Tk::WaitBox;
use Time::Local;
use Time::CTime;    # Time-modulesに同梱
use gui_errormsg;

sub start{
	my $class = shift;
	
	my $d = [localtime];
	my $wait = $::main_gui->mw->WaitBox(
		-title      => 'KH Coder is processing data...',
		-txt1       => "Start: ".strftime("%Y %m/%d %T",@{$d}),
		-background => 'white',
		-takefocus  => 0
	);
	
	$wait->Show;
	my $self;
	$self->{win} = $wait;
	$self->{started} = timelocal(@{$d});
	bless $self, $class;
	return $self;
}

sub end{
	my $self = shift;
	$self->{win}->unShow;
	my $e = timelocal(localtime) - $self->{started};
	
	my ($h, $m, $s);
	if ($e >= 3600){
		$h = int($e / 3600);
		$e %= 3600;
		if ($h < 10){
			$h = "0"."$h";
		}
	} else {
		$h = "00";
	}
	
	if ($e >= 60){
		$m = int($e / 60);
		$e %= 60;
		if ($m < 10){
			$m = "0"."$m";
		}
	} else {
		$m = "00";
	}
	
	if ($e < 10){
		$s = "0"."$e";
	} else {
		$s = $e;
	}
	
	gui_errormsg->open(
		msg  => "処理が完了しました。\n経過時間： $h:$m:$s",
		type => 'msg',
		icon => 'info'
	);
	
}



1;