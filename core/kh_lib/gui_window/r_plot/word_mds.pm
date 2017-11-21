package gui_window::r_plot::word_mds;
use base qw(gui_window::r_plot);

sub option1_options{
	return [
		kh_msg->get('gui_window::r_plot::word_corresp->d_l'), # 'ドットとラベル',
		kh_msg->get('gui_window::r_plot::word_corresp->d'), # 'ドットのみ',
	];
}

sub start{
	my $self = shift;
	
	return 1 if $::config_obj->web_if;
	
	# read coordinates
	return 0 unless -e $self->{coord};
	@{$self->{coordi}} = ();
	open(my $fh, '<:encoding(utf8)', $self->{coord}) or die("file: $self->{coord}");
	while (<$fh>) {
		chomp;
		push @{$self->{coordi}}, [split /\t/, $_];
	}
	close $fh;

	# make clickable image map
	my ($mag, $xmag, $xo, $yo, $tw, $th) = (1.07, 1.04, 46, 36, 30, 11);
	$xo = $xo * $self->{img_height} / 640;
	$yo = $yo * $self->{img_height} / 640;
	$tw = $tw * $self->{img_height} / 640;
	$th = $th * $self->{img_height} / 640;
	
	$self->{coordin} = {};
	foreach my $i (@{$self->{coordi}}){
		my $x1 = $i->[1] * $self->{img_height} / $xmag + $xo - $tw;
		my $y1 = $self->{img_height} - ($i->[2] * $self->{img_height} / $mag  + $yo + $th);
		my $x2 = $i->[1] * $self->{img_height} / $xmag + $xo + $tw;
		my $y2 = $self->{img_height} - ($i->[2] * $self->{img_height} / $mag + $yo - $th);
		
		$x1 = int($x1);
		$x2 = int($x2);
		$y1 = int($y1);
		$y2 = int($y2);
		
		my $id = $self->{canvas}->createRectangle(
			$x1,$y1, $x2, $y2,
			-outline => ""
		);
		
		$self->{canvas}->bind(
			$id,
			"<Enter>",
			sub { $self->decorate($id); }
		);
		$self->{canvas}->bind(
			$id,
			"<Button-1>",
			sub { $self->show_kwic($id); }
		);
		$self->{canvas}->bind(
			1,
			"<Button-1>",
			sub { $self->undecorate; }
		);
		
		$self->{coordin}{$id} = {
			'x1' => $x1,
			'x2' => $x2,
			'y1' => $y1,
			'y2' => $y2,
			'name' => $i->[0],
		};
	}
}

sub save{
	my $self = shift;

	# 保存先の参照
	my @types = (
		[ "PDF",[qw/.pdf/] ],
		[ "Encapsulated PostScript",[qw/.eps/] ],
		[ "SVG",[qw/.svg/] ],
		[ "PNG",[qw/.png/] ],
		[ "CSV",[qw/.csv/] ],
		[ "R Source",[qw/.r/] ],
	);
	@types = ([ "Enhanced Metafile",[qw/.emf/] ], @types)
		if $::config_obj->os eq 'win32';

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.pdf',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('gui_window::r_plot->saving')), # プロットを保存
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	$self->{plots}[$self->{ax}]->save($path) if $path;

	return 1;
}

sub option1_name{
	return kh_msg->get('gui_window::r_plot::word_corresp->view'); # ' 表示：';
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・多次元尺度法
}

sub win_name{
	return 'w_word_mds_plot';
}


sub base_name{
	return 'word_mds';
}

1;