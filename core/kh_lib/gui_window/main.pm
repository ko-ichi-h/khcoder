package gui_window::main;
use base qw(gui_window);
use strict;

#use gui_window::main::linux;
#use gui_window::main::win32;
use gui_window::main::menu;
use gui_window::main::inner;

use Tk;

#----------------------------------#
#   メインウィンドウ・クラス作成   #
#----------------------------------#

sub _new{
	# クラス作成
	my $class = 'gui_window::main';
	
	my $self;

	my $mw= MainWindow->new;
	$self->{mw} = $mw;
	bless $self, "$class";

	# Windowへの書き込み
	$mw->title('KH Coder [MAIN WINDOW]');          # Windowタイトル
	$self->make_font;                              # フォント
	$self->{menu}  = gui_window::main::menu->make(\$self);   # メニュー
	$self->{inner} = gui_window::main::inner->make(\$self);  # Windowの中身
	$self->{win_obj} = $mw;

	if ($::config_obj->os eq 'win32'){
		if ($::config_obj->all_in_one_pack){
			use kh_all_in_one;
			kh_all_in_one->init;
		}
		$::splash->Destroy;
	}

	# GUI未作成のコマンド
	use kh_hinshi;
	$self->win_obj->bind(
		'<Control-Key-h>',
		sub { kh_hinshi->output; }
	);

	$::main_gui = $self;
	return $self;
}

sub start{
	my $self = shift;
	$self->menu->refresh;
	$self->inner->refresh;
}

#------------------#
#   フォント設定   #
#------------------#

sub make_font{
	my $self = shift;
	my @font = split /,/, $::config_obj->font_main;
	
	$self->mw->fontCreate('TKFN',
		-family => $font[0],
		-size   => $font[1],
	);
	$self->mw->optionAdd('*font',"TKFN");
}

sub remove_font{
	my $self = shift;
	$self->{mw}->fontDelete('TKFN');
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
	my $win;
	if ( defined($self->{$window_name}) ){
		$win = $self->{$window_name}->win_obj;
	} else {
		return 0;
	}
	
	if ( Exists($win) ){
		focus $win;
		return 1;
	} else {
		return 0;
	}
}
sub get{
	my $self        = shift;
	my $window_name = shift;
	return $self->{$window_name};
}
sub opened{
	my $self        = shift;
	my $window_name = shift;
	my $window      = shift;
	
	$self->{$window_name} = $window;
	$::main_gui = $self;
}

# プログラム全体の終了処理
sub close{
	my $self        = shift;
	$self->close_all;
	$::config_obj->win_gmtry($self->win_name,$self->win_obj->geometry);
	$::config_obj->save;
	if ($::config_obj->all_in_one_pack){
		kh_all_in_one->mysql_stop;
	}
	$self->win_obj->destroy;
}

sub close_all{
	my $self = shift;
	foreach my $i (keys %{$self}){
		if ( substr($i,0,2) eq 'w_'){
			my $win;
			if ($self->{$i}){
				my $win = $self->{$i}->win_obj;
				if (Exists($win)){
					$self->{$i}->close;
				}
			}
		}
	}
}



1;
