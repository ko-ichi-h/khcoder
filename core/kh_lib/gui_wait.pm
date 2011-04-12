package gui_wait;
use strict;
use Tk;
use Tk::WaitBox_kh;
use Time::Local;
use POSIX 'strftime';
use gui_errormsg;

sub start{
	my $class = shift;
	my $self;
	my $d = [localtime];
	$self->{win} = $::main_gui->mw->WaitBox_kh(
		-title      => 'KH Coder is processing data...',
		-txt1       => "Start: ".strftime('%Y %m/%d %H:%M:%S',@{$d}),
		-background => 'white',
		-takefocus  => 0
	);
	my $icon = $self->{win}->Photo(
		-file =>   Tk->findINC('acre.gif')
	);
	$self->{win}->Icon(-image => $icon);
	$self->{win}->Show;
	
	$self->{started} = timelocal(@{$d});
	bless $self, $class;
	return $self;
}

sub end{
	my $self = shift;
	my %args = @_;
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
	
	if ( $args{no_dialog} ){
		print "done:  $h:$m:$s\n";
	} else {
		gui_errormsg->open(
			msg  => "処理が完了しました。\n経過時間： $h:$m:$s",
			type => 'msg',
			icon => 'info'
		);
	}
	
	$self->{win}->unShow;
}


1;