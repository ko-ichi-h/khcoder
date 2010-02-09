package gui_window::r_plot_opt::word_netgraph;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# 情報の取得
	my ($edges, $th);
	if ($self->{command_f} =~ /edges <- ([0-9\.]+)\n/){
		$edges = $1;
	} else {
		die("cannot get configuration: edges");
	}
	if ($self->{command_f} =~ /th <- ([0-9\.]+)\n/){
		$th = $1;
	} else {
		die("cannot get configuration: th");
	}
	if ($self->{command_f} =~ /use_freq_as_size <- ([01])\n/){
		$self->{check_use_freq_as_size} = $1;
	} else {
		die("cannot get configuration: use_freq_as_size");
	}
	if ($self->{command_f} =~ /use_freq_as_fontsize <- ([01])\n/){
		$self->{check_use_freq_as_fsize} = $1;
	} else {
		die("cannot get configuration: use_freq_as_fsize");
	}
	if ($self->{command_f} =~ /use_weight_as_width <- ([01])\n/){
		$self->{check_use_weight_as_width} = $1;
	} else {
		die("cannot get configuration: $use_weight_as_width");
	}

	if ($edges == 0){
		$self->{radio} = 'j';
		if ($self->{command_f} =~ /# edges: ([0-9]+)\n/){
			$edges = $1;
		} else {
			die("cannot get configuration: edges 2");
		}
	} else {
		$self->{radio} = 'n';
		if ($self->{command_f} =~ /# min. jaccard: ([0-9\.]+)\n/){
			$th = $1;
		} else {
			die("cannot get configuration: edges 2");
		}
	}

	# edge選択
	$lf->Label(
		-text => $self->gui_jchar('描画する共起関係（edge）'),
		-font => "TKFN",
	)->pack(-anchor => 'w');

	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f4->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	$f4->Radiobutton(
		-text             => $self->gui_jchar('描画数：'),
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 'n',
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w', -side => 'left');

	$self->{entry_edges_number} = $f4->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_edges_number}->insert(0,$edges);
	$self->{entry_edges_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_edges_number});

	$f4->Radiobutton(
		-text             => $self->gui_jchar('Jaccard係数：'),
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 'j',
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w', -side => 'left');

	$self->{entry_edges_jac} = $f4->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_edges_jac}->insert(0,$th);
	$self->{entry_edges_jac}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_edges_jac});

	$f4->Label(
		-text => $self->gui_jchar('以上'),
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	# Edgeの太さ・Nodeの大きさ
	$lf->Checkbutton(
			-text     => $self->gui_jchar('強い共起関係ほど太い線で描画','euc'),
			-variable => \$self->{check_use_weight_as_width},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	my $w_use_freq_as_fsize;

	$lf->Checkbutton(
			-text     => $self->gui_jchar('出現数の多い語ほど大きい円で描画','euc'),
			-variable => \$self->{check_use_freq_as_size},
			-anchor => 'w',
			-command =>
				sub{
					return unless $w_use_freq_as_fsize;
					if ($self->{check_use_freq_as_size}){
						$w_use_freq_as_fsize->configure(-state, "normal");
					} else {
						$w_use_freq_as_fsize->configure(-state, "disabled");
					}
				},
	)->pack(-anchor => 'w');

	my $fontsize_frame = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 0,
		-padx => 0,
	);

	$fontsize_frame->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');
	
	$w_use_freq_as_fsize = $fontsize_frame->Checkbutton(
			-text     => $self->gui_jchar('フォントも大きく ※EMFやEPSの出力・印刷向き','euc'),
			-variable => \$self->{check_use_freq_as_fsize},
			-anchor => 'w',
			-state => 'disabled',
	)->pack(-anchor => 'w');

	$w_use_freq_as_fsize->configure(-state => 'normal')
		if $self->{check_use_freq_as_size};


	$self->refresh(3);
	return $self;
}

sub refresh{
	my $self = shift;
		
	my ($dis, $nor);
	if ($self->{radio} eq 'n'){
		$nor = $self->{entry_edges_number};
		$dis = $self->{entry_edges_jac};
	} else {
		$nor = $self->{entry_edges_jac};
		$dis = $self->{entry_edges_number};
	}

	$nor->configure(-state => 'normal' , -background => 'white');
	$dis->configure(-state => 'disable', -background => 'gray' );
	
	$nor->focus unless $_[0] == 3;
}

sub calc{
	my $self = shift;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
		#print "chk: $r_command\n";
		$r_command = Jcode->new($r_command)->euc
			if $::config_obj->os eq 'win32';
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => '調整に失敗しましました。',
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}

	$r_command .= "# END: DATA\n";

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	&gui_window::word_netgraph::make_plot(
		font_size      => $fontsize,
		plot_size      => $self->gui_jg( $self->{entry_plot_size}->get ),
		n_or_j         => $self->gui_jg( $self->{radio} ),
		edges_num      => $self->gui_jg( $self->{entry_edges_number}->get ),
		edges_jac      => $self->gui_jg( $self->{entry_edges_jac}->get ),
		use_freq_as_size => $self->gui_jg( $self->{check_use_freq_as_size} ),
		use_freq_as_fsize=> $self->gui_jg( $self->{check_use_freq_as_fsize} ),
		use_weight_as_width =>
			$self->gui_jg( $self->{check_use_weight_as_width} ),
		r_command      => $r_command,
		plotwin_name   => 'word_netgraph',
	);

	$self->close;
}

sub win_title{
	return '抽出語・共起ネットワーク：調整';
}

sub win_name{
	return 'w_word_netgraph_plot_opt';
}

1;