package gui_window;
use strict;

use strict;
use Tk;
use Tk::LabFrame;
use Tk::ItemStyle;
use Tk::DropSite;
require Tk::ErrorDialog;

use gui_wait;
use gui_OtherWin;

use gui_window::main;
use gui_window::about;
use gui_window::project_new;
use gui_window::project_open;
use gui_window::project_edit;
use gui_window::sysconfig;
use gui_window::sql_select;
use gui_window::sql_do;
use gui_window::word_search;
use gui_window::dictionary;

sub open{
	my $class = shift;
	my $self;
	my @arg = @_;
	$self->{dummy} = 1;
	bless $self, $class;
	
	
	my $check = 0;
	if ($::main_gui){
		$check = $::main_gui->if_opened($self->win_name);
	}
	
	unless ( $check ){
		$self = $self->_new(@arg);
		$::main_gui->opened($self->win_name,$self);

		# Windowサイズと位置の指定
		if ( my $g = $::config_obj->win_gmtry($self->win_name) ){
			$self->win_obj->geometry($g);
		}

		# Windowを閉じる際のバインド
		$self->win_obj->bind(
			'<Control-Key-q>',
			sub{ $self->close; }
		);
		$self->win_obj->protocol('WM_DELETE_WINDOW', sub{ $self->close; });
		
		# 特殊処理に対応
		$self->start;
	}
	return $self;
}


sub close{
	my $self = shift;
	$::config_obj->win_gmtry($self->win_name,$self->win_obj->geometry);
	$::config_obj->save;
	$self->win_obj->destroy;
}

sub win_obj{
	my $self = shift;
	return $self->{win_obj};
}

sub start{
	return 1;
}

1;
