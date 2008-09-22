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

	$self->{mw} = $self->{win_obj};
	$::main_gui = $self;

	# Windowへの書き込み
	$self->{mw}->title('KH Coder');                          # Windowタイトル
	$self->make_font;                                        # フォント
	$self->{menu}  = gui_window::main::menu->make(\$self);   # メニュー
	$self->{inner} = gui_window::main::inner->make(\$self);  # Windowの中身

	#-----------------------#
	#   KH Coder 開始処理   #
	#-----------------------#
	
	$self->menu->refresh;
	$self->inner->refresh;

	# GUI未作成のコマンド
	#use kh_hinshi;
	#$self->win_obj->bind(
	#	'<Control-Key-h>',
	#	sub { kh_hinshi->output; }
	#);
	
	# スプラッシュWindowを閉じる
	if ($::config_obj->os eq 'win32'){
		$::splash->Destroy;
		$self->{win_obj}->focus;
	}

	return $self;
}

sub start {
	# Windowsではここでiconをセットしないとフォーカスが来ない?!
	my $self = shift;
	$self->position_icon;
}


#------------------#
#   フォント設定   #
#------------------#

sub make_font{
	my $self = shift;
	my @font = split /,/, $::config_obj->font_main;

	# Win9x & Perl/Tk 804用の特殊処理
	my $flg = 0;
	if (
		        ( $] > 5.008 )
		and     ( $^O eq 'MSWin32' )
		and not ( Win32::IsWinNT() )
	){
		$flg = 1;
	}

	if ($Tk::VERSION < 804 && $::config_obj->os eq 'linux'){
		$self->mw->fontCreate('TKFN',
			-compound => [
				['ricoh-gothic','-12'],
				'-ricoh-gothic--medium-r-normal--12-*-*-*-c-*-jisx0208.1983-0'
			]
		);
	} else {
		$self->mw->fontCreate('TKFN',
			-family => (
				$flg ? Jcode->new($font[0])->sjis : $self->gui_jchar($font[0])
			),
			-size   => $font[1],
		);
	}
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
	if ($::config_obj->R){
		# print "Stopping R...\n";
		$::config_obj->R->stopR;
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
