package gui_window::r_plot;
use base qw(gui_window);

use gui_window::r_plot::word_cls;
use gui_window::r_plot::word_som;
use gui_window::r_plot::word_corresp;
use gui_window::r_plot::word_mds;
use gui_window::r_plot::word_netgraph;
use gui_window::r_plot::cod_cls;
use gui_window::r_plot::cod_corresp;
use gui_window::r_plot::cod_mds;
use gui_window::r_plot::cod_netg;
use gui_window::r_plot::cod_som;
use gui_window::r_plot::cod_mat;
use gui_window::r_plot::cod_mat_line;
use gui_window::r_plot::selected_netgraph;
use gui_window::r_plot::doc_cls;
use gui_window::r_plot::topic_n_perplexity;
use gui_window::r_plot::topic_n_ldatuning;
use gui_window::r_plot::tpc_mat_line;
use gui_window::r_plot::tpc_mat;

use strict;
use gui_hlist;
use mysql_words;

use Tk;
use Tk::Pane;
use Tk::PNG;

use vars qw($imgs);

sub _new{

	my $self = shift;
	my %args = @_;

	$self->{original_plot_size} = $args{plot_size} if $args{plot_size};
	foreach my $key (keys %args){
		next if $key eq 'plot_size';
		$self->{$key} = $args{$key};
	}
	undef %args;
	return 0 unless $self->{plots};

	my $mw = $::main_gui->mw;
	my $win= $self->{win_obj};
	$win->title($self->gui_jt( $self->win_title ));

	# 画像をロード
	$self->{ax} = 0 unless defined( $self->{ax} );
	$self->{ax} = 0 if $self->{ax} < 0;
	$self->{ax} = 0 unless $self->{plots}[$self->{ax}];
	#print "ax[a]: $self->{ax}\n";
	if ( $imgs->{$self->win_name} ){
		#print "img: read: ".$self->win_name."\n";
		$imgs->{$self->win_name}->read($self->{plots}[$self->{ax}]->path);
	} else {
		#print "img: new\n";
		$imgs->{$self->win_name} = 
			$win->Photo('photo_'.$self->win_name,
				-file => $self->{plots}[$self->{ax}]->path,
			);
	}
	
	# 画像サイズをチェック
	$self->{img_height} = $imgs->{$self->win_name}->height;
	$self->{img_width}  = $imgs->{$self->win_name}->width;
	my $size = $imgs->{$self->win_name}->height;
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
	$self->{photo_pane_height} = $size;

	# 画像表示用ペイン
	my $fp = $win->Frame(
		-borderwidth => 2,
		-relief      => 'sunken',
	)->pack(
		-anchor => 'c',
		-fill   => 'both',
		-expand => 1,
	);

	$self->{photo_pane} = $fp->Scrolled(
		'Pane',
		-scrollbars  => 'osoe',
		-width       => $self->photo_pane_width,
		-height      => $self->photo_pane_height,
		-background  => 'white',
		-borderwidth => 0,
	)->pack(
		-anchor => 'c',
		-fill   => 'both',
		-expand => 1,
	);
	
	# Clickableにする場合はcanvas
	if ( $self->{coord} ) {
		$self->{canvas} = $self->{photo_pane}->Canvas(
			-width  => $self->{img_width},
			-height => $self->{img_height},
			-background  => 'white',
			-borderwidth => 0,
			-highlightthickness => 0,
			#-cursor      => $cursor,
		)->pack(
			-anchor => 'c',
			-fill   => 'both',
			-expand => 1,
		);
		
		my $image_id = $self->{canvas}->createImage(
			int( $self->{img_width} / 2 ),
			int( $self->{img_height} / 2 ),
			-image => $gui_window::r_plot::imgs->{$self->win_name},
		);
		#print "image_id: $image_id\n";

		# 画像のドラッグ
		( $self->{xscroll}, $self->{yscroll} ) =
			$self->{photo_pane}->Subwidget( 'xscrollbar', 'yscrollbar' );
		$self->{canvas}->CanvasBind(
			'<Button1-ButtonRelease>' => sub {
				undef $self->{last_x};
			}
		);
		$self->{canvas}->CanvasBind(
			'<Button1-Motion>' => [
				\&drag, $self, Ev('X'), Ev('Y')
			]
		);
	}
	# Clickableにしない場合はlabel
	else {
		$self->{photo} = $self->{photo_pane}->Label(
			-image       => $imgs->{$self->win_name},
			-cursor      => $cursor,
			-background  => "white",
			-borderwidth => 0,
		)->pack(
			-expand => 1,
			-fill   => 'both',
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
	}

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

	my $f1 = $win->Frame()->pack(
		-expand => 0,
		-fill   => 'x',
		-pady   => 2,
		-padx   => 2,
		-anchor => 's',
	);

	my $chk_n = @{$self->option1_options};
	if ($chk_n > 1){
		$f1->Label(
			-text => $self->gui_jchar($self->option1_name),
			-font => "TKFN",
		)->pack(-side => 'left');

		my @opt = ();
		my $n = 0;
		foreach my $i (@{$self->option1_options}){
			push @opt, [$self->gui_jchar($i),$n];
			++$n;
		}

		$self->{optmenu} = gui_widget::optmenu->open(
			parent  => $f1,
			pack    => {-side => 'left', -padx => 2},
			options => \@opt,
			variable => \$self->{ax},
			command  => sub {$self->renew;},
		);
		$self->{optmenu}->set_value($self->{ax});
		#print "ax[b]: $self->{ax}\n";

		$self->win_obj->bind(
			'<Key-l>',
			sub{
				$self->{optmenu}->{win_obj}->menu->Post(
					$self->{optmenu}->{win_obj}->rootx,
					$self->{optmenu}->{win_obj}->rooty,
					#$self->{ax}
				);
			}
		);
	}

	$self->{button_config} = $f1->Button(
		-text => kh_msg->get('options'), # 調整
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {$self->open_config;},
	)->pack(-side => 'left', -padx => 2);

	$self->win_obj->bind(
		'<Key-c>',
		sub{
			$self->{button_config}->invoke;
		}
	);

	if (length($self->{msg})){
		my $info_label = $f1->Label(
			-text => $self->gui_jchar($self->{msg})
		)->pack(-side => 'left');

		if ( length($self->{msg_long}) ){
			$self->{blhelp} = $mw->Balloon();
			$self->{blhelp}->attach( $info_label,
				-balloonmsg => $self->gui_jchar($self->{msg_long}),
				-font       => "TKFN"
			);
		}
	}

	$f1->Button(
		-text => kh_msg->gget('close'), # 閉じる
		-font => "TKFN",
		-width => 8,
		-borderwidth => '1',
		-command => sub {
			$self->close();
		}
	)->pack(-side => 'right');

	$f1->Button(
		-text => kh_msg->gget('save'), # 保存
		-font => "TKFN",
		#-width => 8,
		-borderwidth => '1',
		-command => sub {
			$self->save();
		}
	)->pack(-side => 'right',-padx => 4);

	$self->win_obj->bind(
		'<Key-s>',
		sub{ $self->save; }
	);
	
	$self->{bottom_frame} = $f1;
	return $self;
}

sub open_config{
	my $self = shift;
	my $base_name = 'gui_window::r_plot_opt::'.$self->base_name;
	
	$self->{child} = $base_name->open(
		command_f => $self->{plots}[$self->{ax}]->command_f,
		font_size => $self->{plots}[$self->{ax}]->{font_size} * 100,
		size      => $self->original_plot_size,
		ax        => $self->{ax},
		$self->extra_param_4config,
	);
	return $self;
}

sub extra_param_4config{
	return ();
}

sub drag {
	my( $w, $self, $x, $y ) = @_;
	if ( defined $self->{last_x} )
	{
		my( $dx, $dy ) = ( $x - $self->{last_x}, $y - $self->{last_y} );
		my( $xf1, $xf2 ) = $self->{xscroll}->get;
		my( $yf1, $yf2 ) = $self->{yscroll}->get;
		my( $iw, $ih ) = ( $self->img_width, $self->img_height );
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

	$imgs->{$self->win_name}->blank;
	$imgs->{$self->win_name}->read($self->{plots}[$self->{ax}]->path);
	$imgs->{$self->win_name}->update;

	$self->renew_command;
}


sub renew_command{}

sub dont_close_child{
	my $self = shift;
	my $new = shift;
	if (defined($new)){
		$self->{dont_close_child} = $new;
	}
	return $self->{dont_close_child};
}

sub end{
	my $self = shift;

	# 調整Windowを閉じる
	if ( ($self->{child}) and not ($self->dont_close_child) ){
		print "Closing child: ", ref $self->{child}, "\n";
		if ( Exists($self->{child}->{win_obj}) ){
			$self->{child}->close;
		}
	}

	#--------------------------------#
	#   以下メモリ・リークの防止用   #

	# バルーンヘルプ
	if ( $self->{blhelp} ){
		 $self->{blhelp}->destroy;
	}

	# Rのプロット・オブジェクト
	$self->{plots} = undef;

	# Imageオブジェクトのクリア
	$imgs->{$self->win_name}->delete;
	$imgs->{$self->win_name}->destroy;
	$imgs->{$self->win_name} = undef;

	#my @n = $self->{win_obj}->imageNames;
	#print "images: ", $#n + 1, "\n";

}

sub save{
	my $self = shift;

	# 保存先の参照
	my @types = (
		[ "Encapsulated PostScript",[qw/.eps/] ],
		[ "PNG",[qw/.png/] ],
	);
	
	@types = (
		@types,
		$self->extra_save_types,
		[ "R Source",[qw/.r/] ],
	);
	
	if ($::config_obj->os eq 'win32'){
		@types = (
			[ "Enhanced Metafile",[qw/.emf/] ],
			[ "SVG",[qw/.svg/] ],
			[ "PDF",[qw/.pdf/] ],
			@types,
		);
	} elsif ($^O eq 'darwin') {
		@types = (
			[ "PDF",[qw/.pdf/] ],
			@types,
		);
	} else {
		@types = (
			[ "PDF",[qw/.pdf/] ],
			[ "SVG",[qw/.svg/] ],
			@types,
		);
	}

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.pdf',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('saving')), # プロットを保存
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	$self->{plots}[$self->{ax}]->save($path) if $path;

	return 1;
}

sub extra_save_types{
	return ();
}

sub img_height{
	my $self = shift;
	return $self->{img_height};
}
sub img_width{
	my $self = shift;
	return $self->{img_width};
}

sub photo_pane_height{
	my $self = shift;
	return $self->{photo_pane_height};
}

sub photo_pane_width{
	my $self = shift;
	return $self->{photo_pane_height};
}

sub original_plot_size{
	my $self = shift;
	
	if ($self->{original_plot_size}){
		return $self->{original_plot_size};
	} else {
		#return $self->{photo}->cget(-image)->height;
		return $self->{img_height};
	}
}


sub show_kwic{
	my $self = shift;
	my $id = shift;

	# コンコーダンスの呼び出し
	my $conc = gui_window::word_conc->open;
	$conc->entry->delete(0,'end');
	$conc->entry4->delete(0,'end');
	$conc->entry2->delete(0,'end');
	
	my $word = $self->{coordin}{$id}{name};
	my $pos;
	if ($word =~ /([^ ]+) \[([^ ]+)\]$/){
		$word   = $1;
		$pos = $2;
		$conc->entry4->insert('end', $pos);
	}
	
	$conc->entry->insert('end', $word);
	$conc->search;
	
	$self->{win_obj}->focus unless $::config_obj->os eq 'win32';
}

sub clear_clickablemap{
	my $self = shift;
	
	return 0 unless defined( $self->{coordin} );
	return 0 unless $self->{coordin};
	return 0 unless $self->{canvas};
	
	$self->undecorate;
	
	foreach my $i (keys %{$self->{coordin}}) {
		$self->{canvas}->delete( $i );
	}
	
	$self->{coordin} = ();
	return 1;
}

sub decorate{
	my $self = shift;
	my $id = shift;
	
	#print "decorate: $id, $self->{coordin}{$id}{x1}\n";
	
	return 1 if $self->{coordin}{$id}{did};
	
	# show
	$self->{coordin}{$id}{did} = $self->{canvas}->createRectangle(
		$self->{coordin}{$id}{x1} -1,
		$self->{coordin}{$id}{y1} +1,
		$self->{coordin}{$id}{x2} +1,
		$self->{coordin}{$id}{y2} -1,
		-outline => '#778899',
		-width   => 1,
	);
	
	# unshow others
	foreach my $i (@{$self->{coordin}{decorated}}){
		if ($i == $id) {
			next;
		}
		if ( $self->{coordin}{$i}{did} ){
			$self->{canvas}->delete( $self->{coordin}{$i}{did} );
			$self->{coordin}{$i}{did} = undef;
		}
	}
	@{$self->{coordin}{decorated}} = ();
	
	push @{$self->{coordin}{decorated}}, $id;
}

sub undecorate{
	my $self = shift;
	
	#print "undecorate\n";
	
	foreach my $i (@{$self->{coordin}{decorated}}){
		if ( $self->{coordin}{$i}{did} ){
			$self->{canvas}->delete( $self->{coordin}{$i}{did} );
			$self->{coordin}{$i}{did} = undef;
		}
	}
	@{$self->{coordin}{decorated}} = ();

}


1;
