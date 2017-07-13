package gui_wait;
use strict;
use Tk;
use Tk::WaitBox_kh;
use Time::Local;
use POSIX 'strftime';
use gui_errormsg;

my $win;

sub start{
	my $class = shift;
	my $self;
	my $d = [localtime];
	
	if ($win){
		$win->configure(-txt1 => "Start: ".strftime('%Y %m/%d %H:%M:%S',@{$d}));
		#print "gui_wait: re-using...\n";
	} else {
		#print "gui_wait: making new...\n";
		$win = $::main_gui->mw->WaitBox_kh(
			-title      => 'KH Coder is processing data...',
			-txt1       => "Start: ".strftime('%Y %m/%d %H:%M:%S',@{$d}),
			-background => 'white',
			-takefocus  => 0
		);
	}

	if (
		   ($::config_obj->os eq 'win32')
		&& (eval 'require Tk::Icon' )
	) {
		$win->Show;
		require Tk::Icon;
		$win->setIcon(-file => Tk->findINC('1.ico') );
	} else {
		eval'$win->Icon(-image => \'window_icon\')';
		$win->Show;
	}

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
			msg    => kh_msg->get('done')." $h:$m:$s",#"処理が完了しました。\n経過時間： 
			type   => 'msg',
			icon   => 'info',
			window => \$win,
		);
	}
	
	$win->unShow unless $::config_obj->os eq 'win32';
	$win->{bitmap}->destroy;
	$win->destroy;
	undef $win;
	
	return 1;
}


1;