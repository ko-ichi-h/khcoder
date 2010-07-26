package gui_window::doc_cls_height;
use strict;
use base qw(gui_window);

#------------------#
#   Windowを開く   #
#------------------#

sub _new{
	if ($::config_obj->os eq 'linux') {
		require Tk::PNG;
	}

	my $self = shift;
	my %args = @_;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$self->{plots} = $args{plots};
	$self->{type}  = $args{type};

	$win->title($self->gui_jt('文書のクラスター分析：併合水準','euc'));
	
	$self->{photo} = $win->Label(
		-image => $win->Photo(-file => $args{plots}->{$args{type}}->path),
		-borderwidth => 2,
		-relief => 'sunken',
	)->pack(-anchor => 'c');

	my $f1 = $win->Frame()->pack(-expand => 'y', -fill => 'x', -pady => 2);


	$f1->Button(
		-text => $self->gui_jchar('閉じる'),
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->close();
				}
			);
		}
	)->pack(-side => 'right');

	$f1->Button(
		-text => $self->gui_jchar('保存'),
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub{ $mw->after
			(
				10,
				sub {
					$self->save();
				}
			);
		}
	)->pack(-side => 'right', -padx => 4);

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
			$self->gui_jt('プロットを保存'),
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	# R Sourceを保存する場合には対策が必要？
	$self->{plots}->{$self->{type}}->save($path) if $path;

	return 1;
}

sub renew{
	my $self = shift;
	
	if ($_[0]){
		$self->{type} = shift;
	}
	
	$self->{photo}->configure(
		-image =>
			$self->{win_obj}->Photo(
				-file => $self->{plots}->{$self->{type}}->path
			)
	);
	
	$self->{photo}->update;
	return $self;
}

#--------------#
#   Window名   #

sub win_name{
	return 'w_doc_cls_height';
}

1;
