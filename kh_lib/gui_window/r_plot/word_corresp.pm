package gui_window::r_plot::word_corresp;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;

	if (@{$self->{plots}} == 2){
		return [
			kh_msg->get('d_l'), # ドットとラベル
			kh_msg->get('d'), # ドットのみ
		] ;
	} else {
		return [
			kh_msg->get('col'), # カラー
			kh_msg->get('gray'), # グレースケール
			kh_msg->get('var'), # 変数のみ
			kh_msg->get('d'), # ドットのみ
		] ;
	}
}

sub start{
	my $self = shift;
	
	return 1 if $::config_obj->web_if;
	
	$self->renew_command;
}

sub renew_command{
	my $self = shift;
	$self->clear_clickablemap;
	
	
	my $n = @{$self->{plots}};
	#print "ax: $self->{ax}\n";
	#print "n: $n\n";
	return 0 unless $self->{ax} == 0 || $self->{ax} == 1;
	return 0 if $n == 2 && $self->{ax} == 1;
	
	
	
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
	my ($mag, $xmag, $xo, $yo, $tw, $th) = (1.07, 1.09, 50, 36, 30, 11);
	$xo = $xo * $self->{img_height} / 640;
	$yo = $yo * $self->{img_height} / 640;
	$tw = $tw * $self->{img_height} / 640;
	$th = $th * $self->{img_height} / 640;

	# adjustments for font size (dpi value) 
	#my $nxo = $xo * $self->{plots}[$self->{ax}]->{font_size};
	#my $nyo = $yo * $self->{plots}[$self->{ax}]->{font_size};
	
	# Using "1" as the font size because the axis font size is currently fixed
	my $nxo = $xo * 1;
	my $nyo = $yo * 1;
	
	$xmag = $xmag / (( $self->{img_height} - ($nxo) ) / ( $self->{img_height} - ($xo) ));
	$mag = $mag / (( $self->{img_height} - ($nyo) ) / ( $self->{img_height} - ($yo) ));
	#print "$xmag, $mag\n";
	$xo = $nxo;
	$yo = $nyo;
	
	# adjustments for X-Y ratio
	if ($self->{ratio}) {
		print "ratio: $self->{ratio}\n";
		if ($self->{ratio} > 1.01 ) { # width is longer
			if ($self->{ratio} < 1) {
				$self->{ratio} = 1;
			}
			$yo = $yo +
				( ( $self->{img_height} - $yo ) / $mag ) * ( 1 -  1 / $self->{ratio} ) / 2;
			$mag = $mag * $self->{ratio};
			$yo = $yo * 1.06; # umm...
			$mag = $mag * 1.02 if $self->{ratio} > 1; # umm...
		}
		elsif ($self->{ratio} < 0.99 ){ # height is longer
			$xo = $xo +
				( ( $self->{img_height} - $xo ) / $mag ) * ( 1 - $self->{ratio} ) / 2;
			$xmag = $xmag / $self->{ratio};
			#$xo = $xo * 1.00; # umm...
			$xmag = $xmag * 0.98; # umm...
		}
		#print "$xo, $yo, $mag, $xmag\n";
	}
	
	
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
	#SCREEN Plugin
	use screen_code::r_plot_multiselect;
	&screen_code::r_plot_multiselect::bind_multiselect($self);
}

sub extra_save_types{
	return (
		[ "CSV",[qw/.csv/] ],
	);
}

sub option1_name{
	return kh_msg->get('view'); #  表示：
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・対応分析
}

sub win_name{
	return 'w_word_corresp_plot';
}

sub base_name{
	return 'word_corresp';
}

1;