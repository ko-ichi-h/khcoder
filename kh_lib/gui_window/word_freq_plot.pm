package gui_window::word_freq_plot;
use strict;
use Tk::PNG;
use base qw(gui_window);

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	my $self = shift;
	my %args = @_;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};

	$win->title($self->gui_jt( kh_msg->get('win_title') )); # '出現回数：分布：プロット'
	
	$self->{img} = $win->Photo(-file => $args{images}->[1]->path);
	
	$self->{photo} = $win->Label(
		-image       => $self->{img},
		-borderwidth => 2,
		-relief      => 'sunken',
	)->pack( -anchor => 'c' );

	my $f1 = $win->Frame()->pack(-expand => 'y', -fill => 'x', -pady => 2);

	$f1->Label(
		-text => kh_msg->get('log'),#$self->gui_jchar(' 対数軸の使用：'),
		-font => "TKFN"
	)->pack(-anchor => 'e', -side => 'left');
	
	$self->{optmenu} = gui_widget::optmenu->open(
		parent  => $f1,
		pack    => {-anchor=>'e', -side => 'left', -padx => 0},
		options =>
			[
				[kh_msg->get('x') => 1], # $self->gui_jchar('出現回数(X)')
				[kh_msg->get('xy') => 2], # $self->gui_jchar('出現回数(X)と度数(Y)')
				[kh_msg->get('none') => 0], # $self->gui_jchar('なし')
			],
		variable => \$self->{ax},
		command  => sub {$self->renew;},
	);

	$f1->Button(
		-text => kh_msg->gget('close'), #$self->gui_jchar('閉じる'),
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub {
					$self->close();
				}
	)->pack(-side => 'right');

	$f1->Button(
		-text => kh_msg->gget('save'), #$self->gui_jchar('保存'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub {
					$self->save();
				}
	)->pack(-side => 'right', -padx => 4);

	$self->{images} = $args{images};
	return $self;
}

sub save{
	my $self = shift;

	# 保存先の参照
	my @types = (
		[ "Encapsulated PostScript",[qw/.eps/] ],
		#[ "Adobe PDF",[qw/.pdf/] ],
		[ "PNG",[qw/.png/] ],
		[ "R Source",[qw/.r/] ],
	);
	@types = ([ "Enhanced Metafile",[qw/.emf/] ], @types)
		if $::config_obj->os eq 'win32';

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.eps',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt( kh_msg->get('saving') ),#'プロットを保存'
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	$self->{images}[$self->{ax}]->save($path) if $path;

	return 1;
}

sub renew{
	my $self = shift;
	
	$self->{img}->read( $self->{images}[$self->{ax}]->path );
	
	$self->{photo}->update;
}

sub end{
	my $self = shift;
	$self->{images} = undef;
	$self->{img}->delete;
}

#--------------#
#   Window名   #

sub win_name{
	return 'w_word_freq_plot';
}

1;
