package gui_window::main;
use base qw(gui_window);
use strict;

use gui_window::main::linux;
use gui_window::main::win32;
use gui_window::main::menu;
use gui_window::main::inner;

use Tk;

#----------------------------------#
#   メインウィンドウ・クラス作成   #
#----------------------------------#

sub open{
	# クラス作成
	my $class = shift;
	my $self;

	my $mw= MainWindow->new;
	$self->{mw} = $mw;
	bless $self, "$class".'::'.$::config_obj->os;

	# Windowへの書き込み
	$mw->title('KH Coder   MAIN WINDOW');          # Windowタイトル
	$self->make_font;                              # フォント
	$self->{menu}  = gui_window::main::menu->make(\$self);   # メニュー
	$self->{inner} = gui_window::main::inner->make(\$self);  # Windowの中身

	if ( my $g = $::config_obj->win_gmtry('main_window') ){
		$mw->geometry($g);
	}
	$mw->bind('<Control-Key-q>',sub{ $self->close; });
	$mw->protocol('WM_DELETE_WINDOW', sub{ $self->close; });
	$self->{win_obj} = $mw;

	if ($::config_obj->os eq 'win32'){
		$::splash->Destroy;
	}
	
	$::main_gui = $self;
	return $self;
}

#--------------#
#   アクセサ   #
#--------------#

sub mw{
	my $self = shift;
	return $self->{mw};
}
sub inner{
	my $self = shift;
	return $self->{inner}
}
sub menu{
	my $self = shift;
	return $self->{menu};
}

sub win_name{
	return 'main_window';
}
#----------------------#
#   他のWindowの管理   #
#----------------------#
sub if_opened{
	my $self        = shift;
	my $window_name = shift;
	my $win         = $self->{$window_name};
	
	if ( Exists($win) ){
		focus $win;
		return 1;
	} else {
		return 0;
	}
}
sub opened{
	my $self        = shift;
	my $window_name = shift;
	my $window      = shift;
	
	$self->{$window_name} = $window;
	$::main_gui = $self;
}

sub _close{
	my $self        = shift;
	my $window_name = shift;
	my $win         = $self->{$window_name};
	if ( Exists($win) ){
		$::config_obj->win_gmtry($window_name,$win->geometry);
		$::config_obj->save;
		$win->destroy;
	}
	$self->{$window_name} = undef;
}
sub close_all{
	my $self = shift;
	foreach my $i (keys %{$self}){
		if ( substr($i,0,2) eq 'w_'){
			$self->_close($i);
		}
	}
}



1;
