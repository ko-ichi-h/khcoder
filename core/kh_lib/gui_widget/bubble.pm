package gui_widget::bubble;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	
	$win->Checkbutton(
		-text     => gui_window->gui_jchar('出現数の多い語ほど大きく描画（バブルプロット）'),
		-variable => \$self->{check_bubble},
		-command  => sub{ $self->refresh_std_radius;},
	)->pack(
		-anchor => 'w',
	);

	my $frm_std_radius = $win->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 2,
	);

	$frm_std_radius->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');
	$self->{chk_resize_vars} = 1;
	$self->{chkw_resize_vars} = $frm_std_radius->Checkbutton(
			-text     => gui_window->gui_jchar('変数の値 / 見出しの大きさも可変に','euc'),
			-variable => \$self->{chk_resize_vars},
			-anchor => 'w',
			-state => 'disabled',
	)->pack(-anchor => 'w');

	if ($self->{type} eq 'corresp'){
		$self->{chk_std_radius} = 1;
		$self->{chkw_std_radius} = $frm_std_radius->Checkbutton(
				-text     => gui_window->gui_jchar('バブルの大きさを標準化する','euc'),
				-variable => \$self->{chk_std_radius},
				-anchor => 'w',
				-state => 'disabled',
		)->pack(-anchor => 'w');
	}

	$self->refresh_std_radius;
	$self->{win_obj} = $win;
	return $self;
}

sub refresh_std_radius{
	my $self = shift;
	if ( $self->{check_bubble} ){
		$self->{chkw_std_radius}->configure(-state => 'normal');
		$self->{chkw_resize_vars}->configure(-state => 'normal');
	} else {
		$self->{chkw_std_radius}->configure(-state => 'disabled');
		$self->{chkw_resize_vars}->configure(-state => 'disabled');
	}
}


#----------------------#
#   設定へのアクセサ   #

sub check_bubble{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_bubble} );
}

sub chk_resize_vars{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_bubble} );
}

sub chk_std_radius{
	my $self = shift;
	return gui_window->gui_jg( $self->{chk_resize_vars} );
}


1;