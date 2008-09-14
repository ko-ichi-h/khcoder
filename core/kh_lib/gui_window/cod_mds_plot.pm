package gui_window::cod_mds_plot;
use base qw(gui_window);

use strict;
use gui_hlist;
use mysql_words;

use Tk;
use Tk::Pane;

sub _new{
	if ($::config_obj->os eq 'linux') {
		require Tk::PNG;
	}

	my $self = shift;

	my %args = @_;
	$self->{plots} = $args{plots};
	
	my $mw = $::main_gui->mw;
	my $win= $self->{win_obj};
	$win->title($self->gui_jt('コーディング・多次元尺度法'));

	# 画像サイズをチェック
	my $img = $win->Photo(-file => $self->{plots}[$self->{ax}]->path);
	$self->{img_height} = $img->height;
	$self->{img_width}  = $img->width;
	my $size = $img->height;
	$size += 10;
	$size = 490 if $size < 490;
	my $cursor = undef;
	if ($size > 650){
		$size = 650;
		$cursor = 'fleur';
	}
	if ($win->screenheight - 180 < $size){
		$size = $win->screenheight - 180;
		$cursor = 'fleur';
	}

	# 画像表示用ペイン
	$self->{photo_pane} = $win->Scrolled(
		'Pane',
		-scrollbars => 'osoe',
		-width      => $size,
		-height     => $size,
		-relief => 'sunken',
		-borderwidth => 2,
	)->pack(
		-anchor => 'c',
		-fill => 'both',
		-expand => 1
	);
	$self->{photo} = $self->{photo_pane}->Label(
		-image  => $img,
		-cursor => $cursor,
	)->pack(
		-expand => 1,
		-fill => 'both',
	);

	# 画像のドラッグ
	( $self->{xscroll}, $self->{yscroll} ) =
		$self->{photo_pane}->Subwidget( 'xscrollbar', 'yscrollbar' );
	$self->{photo}->bind(
		'<Button1-ButtonRelease>' => sub {
			undef $self->{last_x};
		}
	);
	$self->{photo}->bind(
		'<Button1-Motion>' => [
			\&drag, $self, Ev('X'), Ev('Y')
		]
	);

	my $f1 = $win->Frame()->pack(
		-expand => 0,
		-fill   => 'x',
		-pady   => 2,
		-padx   => 2,
		-anchor => 's',
	);

	# カーソルキーによるスクロール
	$self->win_obj->bind( '<Up>'    =>
		sub {
			$self->{photo_pane}->yview(scroll => -0.1, 'pages');
		}
	);
	$self->win_obj->bind( '<Down>'  =>
		sub {
			$self->{photo_pane}->yview(scroll =>  0.1, 'pages');
		}
	);
	$self->win_obj->bind( '<Left>'  =>
		sub {
			$self->{photo_pane}->xview(scroll => -0.1, 'pages');
		}
	);
	$self->win_obj->bind( '<Right>' =>
		sub {
			$self->{photo_pane}->xview(scroll =>  0.1, 'pages');
		}
	);


	$f1->Label(
		-text => $self->gui_jchar(' 表示：'),
		-font => "TKFN"
	)->pack(-anchor => 'e', -side => 'left');
	
	$self->{optmenu} = gui_widget::optmenu->open(
		parent  => $f1,
		pack    => {-anchor=>'e', -side => 'left', -padx => 2},
		options =>
			[
				[$self->gui_jchar('コード名とドット') => 0],
				[$self->gui_jchar('ドット')   => 1],
				#[$self->gui_jchar('コード名＋ドット') => 2],
			],
		variable => \$self->{ax},
		command  => sub {$self->renew;},
	);

	$f1->Button(
		-text => $self->gui_jchar('調整'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $mw->after
			(
				10,
				sub {
					gui_window::cod_mds_plot_opt->open(
						command_f => $self->{plots}[$self->{ax}]->command_f,
						size      => $self->{photo}->cget(-image)->height,
					);
				}
			);
		}
	)->pack(-side => 'left', -padx => 2);

	if (length($args{stress})){
		$f1->Label(
			-text => " Stress = ".$args{stress}
		)->pack(-side => 'left');
	}

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
	)->pack(-side => 'right',-padx => 4);

	return $self;
}

sub drag {
	my( $w, $self, $x, $y ) = @_;
	if ( defined $self->{last_x} )
	{
		my( $dx, $dy ) = ( $x - $self->{last_x}, $y - $self->{last_y} );
		my( $xf1, $xf2 ) = $self->{xscroll}->get;
		my( $yf1, $yf2 ) = $self->{yscroll}->get;
		my( $iw, $ih ) = ( $self->{img_width}, $self->{img_height} );
		if ( $dx < 0 )
		{
			$self->{photo_pane}->xview( moveto => $xf1-($dx/$iw) );
		}
		else
		{
			$self->{photo_pane}->xview( moveto => $xf1-($xf2*$dx/$iw) );
		}
		if ( $dy < 0 )
		{
			$self->{photo_pane}->yview( moveto => $yf1-($dy/$ih) );
		}
		else
		{
			$self->{photo_pane}->yview( moveto => $yf1-($yf2*$dy/$ih) );
		}
	}
	( $self->{last_x}, $self->{last_y} ) = ( $x, $y );
	return $self;
}

sub renew{
	my $self = shift;
	return 0 unless $self->{optmenu};
	
	$self->{photo}->configure(
		-image => $self->{win_obj}->Photo(-file => $self->{plots}[$self->{ax}]->path)
	);
	$self->{photo}->update;
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

	$self->{plots}[$self->{ax}]->save($path) if $path;

	return 1;
}

#--------------#
#   アクセサ   #


sub win_name{
	return 'w_cod_mds_plot';
}

1;