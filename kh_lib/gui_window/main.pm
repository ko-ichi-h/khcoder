package gui_window::main;
use base qw(gui_window);
use strict;

use gui_window::main::menu;
use gui_window::main::inner;

use Tk;

#----------------------------------#
#   メインウィンドウ・クラス作成   #
#----------------------------------#

sub _new{
	my $self = shift;
	$::main_gui = $self; # リファレンスなので、以降はどちらを書き換えても、両方書き換わる

	# Windowへの書き込み
	$self->make_font;                                        # フォント準備
	$self->{win_obj}->title('KH Coder');                     # Windowタイトル
	$self->{menu}  =
		gui_window::main::menu->make(  $self->{win_obj} );   # メニュー＆内容

	#-----------------------#
	#   KH Coder 開始処理   #
	#-----------------------#
	
	$self->menu->refresh;
	$self->inner->refresh;

	$self->{win_obj}->bind(
		'<Configure>' => sub {
			#print "Main window moved.\n";
			if ($::main_gui->if_opened('suggest')){
				$::main_gui->get('suggest')->delayed_follow;
			}
		}
	);

	# スプラッシュWindowを閉じる
	if ($::config_obj->os eq 'win32'){
		$::splash->Destroy if $::splash;
		$self->{win_obj}->focusForce;
	}

	return $self;
}

sub start{
	
	my $self = shift;
	
	# Windowsではここでiconをセットしないとフォーカスが来なかった？
	# $self->position_icon(no_geometry => 1);
	$self->position_icon();
	$self->inner->refresh;
	# メイン画面だけはESCキーで閉じない
	$self->win_obj->bind(
		'<Key-Escape>',
		sub{ return 1; }
	);
}

#------------------#
#   フォント設定   #
#------------------#

sub make_font{
	my $self = shift;
	my @font = split /,/, $::config_obj->font_main;

	if ($Tk::VERSION < 804 && $::config_obj->os eq 'linux'){
		$self->mw->fontCreate('TKFN',
			-compound => [
				['ricoh-gothic','-12'],
				'-ricoh-gothic--medium-r-normal--12-*-*-*-c-*-jisx0208.1983-0'
			]
		);
	} else {
		$self->mw->fontCreate('TKFN',
			-family => $font[0],
			-size   => $font[1],
		);
	}
	$self->mw->optionAdd('*font',"TKFN");
}

sub remove_font{
	my $self = shift;
	$self->{win_obj}->fontDelete('TKFN');
}

#--------------#
#   アクセサ   #
#--------------#

sub mw{
	my $self = shift;
	return $self->{win_obj};
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
		#focus $win;
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
	#$::main_gui = $self; # リファレンスなので自動的に更新される
}
sub closed{
	my $self        = shift;
	my $window_name = shift;
	
	undef $self->{$window_name};
	#$::main_gui = $self; # リファレンスなので自動的に更新される
}

# プログラム全体の終了処理
sub close{
	my $self        = shift;
	$self->close_all;
	#SCREEN Plugin
	use screen_code::r_plot_multiselect;
	screen_code::r_plot_multiselect::close_KWIC();

	# remember position of "suggest" window
	#$self->get('suggest')->close if $self->if_opened('suggest');

	# remember position of main window
	$::config_obj->win_gmtry($self->win_name, $self->win_obj->geometry);

	$::config_obj->save;

	# End sub-process
	if ($::config_obj->all_in_one_pack){
		kh_all_in_one->mysql_stop;
	}
	if ($::config_obj->R){
		$::config_obj->R->stopR;
	}
	$self->win_obj->destroy;
	exit;
}

sub close_all{
	my $self = shift;
	my %args = @_;
	foreach my $i (keys %{$self}){
		if ( substr($i,0,2) eq 'w_'){ # do not close main window: 'main_window'
			my $win;
			if ($self->{$i}){
				my $win = $self->{$i}->win_obj;
				if (Exists($win)){
					my $skip = 0;
					foreach my $h (@{$args{except}}){
						$skip = 1 if $h eq $self->{$i}->win_name;
					}
					$self->{$i}->close unless $skip;
				}
			}
		}
	}
}



1;
