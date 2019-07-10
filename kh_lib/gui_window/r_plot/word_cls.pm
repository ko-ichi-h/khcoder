package gui_window::r_plot::word_cls;
use base qw(gui_window::r_plot);

sub renew_command{
	my $self = shift;
	$self->{photo_pane}->yview(moveto => 0);

	if ($::main_gui->if_opened('w_word_cls_height')){
		$::main_gui->get('w_word_cls_height')->renew(
			$self->{ax}
		);
	}
}

sub photo_pane_width{
	return 490;
}

sub option1_options{
	return [ 'nothing' ];
}

sub option1_name{
	return kh_msg->get('method'); #  方法：
}

sub start{
	my $self = shift;
	$self->{bottom_frame}->Button(
		-text => kh_msg->get('agglomer'), # 併合水準
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub {
			if ($::main_gui->if_opened('w_word_cls_height')){
				$::main_gui->get('w_word_cls_height')->renew(
					$self->{ax}
				);
			} else {
				gui_window::cls_height::word->open(
					plots => $self->{merges},
					type  => 0,
				);
			}
		}
	)->pack(-side => 'left',-padx => 2);

	return 1 if $::config_obj->web_if;

	# read coordinates
	return 0 unless defined($self->{coord});
	return 0 unless -e $self->{coord};
	@{$self->{coordi}} = ();
	open(my $fh, '<:encoding(utf8)', $self->{coord}) or die("file: $self->{coord}");
	while (<$fh>) {
		chomp;
		push @{$self->{coordi}}, [split /\t/, $_];
	}
	close $fh;
	
	# make clickable image map
	my $yo   = -10;
	my $yax  = 14;
	my $ymag = 0.999;
	my $th   = 11;
	$yax = $yax * $self->{img_width} / 480;
	$yo  = $yo * $self->{img_width} / 480;
	$th  = $th * $self->{img_width} / 480;
	
	my $n = @{$self->{coordi}};
	my $height_of_one_word = ( $self->{img_height} - $yax) / $n;
	
	if ($height_of_one_word > $th * 2) {
		print "one_word: $height_of_one_word, th: $th, yo: $yo\n";
		$yo = $yo - int( ($height_of_one_word - $th * 2) / 2 );
		print "yo: $yo\n";
	}
	
	# adjustments for font size (dpi value)
	#$yax = $yax * 1.00 * $self->{plots}[$self->{ax}]->{font_size};
	
	$self->{coordin} = {};
	foreach my $i (@{$self->{coordi}}){
		my $x1 = $self->{img_width} * 1 / 6;
		my $x2 = $self->{img_width} * $i->[1] ;
		my $y1 = ( $self->{img_height} - $yax) * $ymag * $i->[2] + $yo + $th;
		my $y2 = ( $self->{img_height} - $yax) * $ymag * $i->[2] + $yo - $th;
		
		$x1 = int($x1);
		$x2 = int($x2);
		$y1 = int($y1);
		$y2 = int($y2);
		
		$y1 = 0 if $y1 < 0;
		$y2 = 0 if $y2 < 0;
		
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

sub end{
	my $self = shift;
	
	if ($::main_gui->if_opened('w_word_cls_height')){
		$::main_gui->get('w_word_cls_height')->close;
	}
	
	&gui_window::r_plot::end($self);
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・クラスター分析
}

sub win_name{
	return 'w_word_cls_plot';
}


sub base_name{
	return 'word_cls';
}

1;