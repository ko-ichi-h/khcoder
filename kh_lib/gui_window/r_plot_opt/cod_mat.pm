package gui_window::r_plot_opt::cod_mat;
use base qw(gui_window::r_plot_opt);

use strict;

sub _new{
	my $self = shift;
	my %args = @_;

	foreach my $key (keys %args){
		next if $key eq 'plot_size';
		$self->{$key} = $args{$key};
	}
	undef %args;

	$self->{ax} = 0 unless (length($self->{ax}));
	
	$self->{win_obj}->title($self->gui_jt( $self->win_title ));
	
	my $lf = $self->{win_obj}->Frame(
		#-label => 'Options',
		#-labelside => 'acrosstop',
		#-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);
	
	$self->{labframe} = $lf;
	$self->innner;

	# フォントサイズ
	#$self->{font_obj} = gui_widget::r_font->open(
	#	parent       => $lf,
	#	command      => sub{ $self->calc; },
	#	pack    => {
	#		-anchor   => 'w',
	#	},
	#	r_com     => $args{command_f},
	#	plot_size => $args{size},
	#);

	# OK, Cancel
	$self->{win_obj}->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2, -pady => 2);

	$self->{win_obj}->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2);

	return $self;
}


sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# ヒートマップのパラメーター
	if ( $self->{command_f} =~ /dendro_c <\- ([0-9]+)\n/ ){
		$self->{heat_dendro_c} = $1;
	}

	if ( $self->{command_f} =~ /dendro_v <\- ([0-9]+)\n/ ){
		$self->{heat_dendro_v} = $1;
	}

	if ( $self->{command_f} =~ /cellnote <\- ([0-9]+)\n/ ){
		$self->{heat_cellnote} = $1;
	}

	# バブルプロットのパラメーター
	if ( $self->{command_f} =~ /bubble_size <\- (.+)\n/ ){
		$self->{bubble_size} = $1;
	}
	$self->{bubble_size} *= 100;

	if ( $self->{command_f} =~ /bubble_shape <\- (.+)\n/ ){
		$self->{bubble_shape} = $1;
	}

	# ヒートマップのGUI
	my $lf_h = $lf->LabFrame(
		-label => kh_msg->get('gui_window::r_plot::cod_mat->heat'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	$lf_h->Checkbutton(
		-variable => \$self->{heat_cellnote},
		-text     => kh_msg->get('cellnote'), 
	)->pack(-anchor => 'w');

	$lf_h->Checkbutton(
		-variable => \$self->{heat_dendro_c},
		-text     => kh_msg->get('dendro_c'), 
	)->pack(-anchor => 'w');

	$lf_h->Checkbutton(
		-variable => \$self->{heat_dendro_v},
		-text     => kh_msg->get('dendro_v'), 
	)->pack(-anchor => 'w');

	my $f_h1 = $lf_h->Frame()->pack(-fill=>'x',-expand=>0); # プロット高さ
	$f_h1->Label(
		-text => kh_msg->get('plot_size_heat'),
	)->pack(-side => 'left');
	
	$self->{entry_plot_size_heat} = $f_h1->Entry(
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left');
	gui_window->config_entry_focusin($self->{entry_plot_size_heat});
	$self->{entry_plot_size_heat}->bind("<Key-Return>", sub {$self->calc});
	$self->{entry_plot_size_heat}->bind("<KP_Enter>", sub {$self->calc});
	
	$self->{entry_plot_size_heat}->insert(0,$self->{plot_size_heat});


	# バブルプロットのGUI
	my $lf_f = $lf->LabFrame(
		-label => kh_msg->get('gui_window::r_plot::cod_mat->fluc'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);
	
	my $f_f1 = $lf_f->Frame()                               # バブルの大きさ
		->pack(-fill=>'x',-expand=>0, -pady => 2);
	$f_f1->Label(
		-text => kh_msg->get('bubble_size'),
	)->pack(-side => 'left');
	
	$self->{entry_bubble_size} = $f_f1->Entry(
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left');
	gui_window->config_entry_focusin($self->{entry_bubble_size});
	$self->{entry_bubble_size}->bind("<Key-Return>", sub {$self->calc});
	$self->{entry_bubble_size}->bind("<KP_Enter>", sub {$self->calc});
	
	$self->{entry_bubble_size}->insert(0,$self->{bubble_size});

	$f_f1->Label(
		-text => '%',
	)->pack(-side => 'left');

	my $f_f3 = $lf_f->Frame()                               # バブル形状
		->pack(-fill=>'x',-expand=>0, -pady => 2)
	;
	$f_f3->Label(
		-text => kh_msg->get('bubble_shape'),
	)->pack(-side => 'left');

	$f_f3->Radiobutton(
		-text     => kh_msg->get('square'),# 正方形
		-variable => \$self->{bubble_shape},
		-value    => 22,
	)->pack(-side => 'left');

	$f_f3->Radiobutton(
		-text     => kh_msg->get('circle'),# 円
		-variable => \$self->{bubble_shape},
		-value    => 21,
	)->pack(-side => 'left');

	my $f_f2 = $lf_f->Frame()                               # プロットの幅
		->pack(-fill=>'x',-expand=>0, -pady => 2);
	$f_f2->Label(
		-text => kh_msg->get('plot_size_mapw'),
	)->pack(-side => 'left');
	
	$self->{entry_plot_size_mapw} = $f_f2->Entry(
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left');
	gui_window->config_entry_focusin($self->{entry_plot_size_mapw});
	$self->{entry_plot_size_mapw}->bind("<Key-Return>", sub {$self->calc});
	$self->{entry_plot_size_mapw}->bind("<KP_Enter>", sub {$self->calc});
	
	$self->{entry_plot_size_mapw}->insert(0,$self->{plot_size_mapw});

	$f_f2->Label(                                            # プロットの高さ
		-text => kh_msg->get('plot_size_maph'),
	)->pack(-side => 'left');
	
	$self->{entry_plot_size_maph} = $f_f2->Entry(
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left');
	gui_window->config_entry_focusin($self->{entry_plot_size_maph});
	$self->{entry_plot_size_maph}->bind("<Key-Return>", sub {$self->calc});
	$self->{entry_plot_size_maph}->bind("<KP_Enter>", sub {$self->calc});
	
	$self->{entry_plot_size_maph}->insert(0,$self->{plot_size_maph});

	return $self;
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
			msg  => kh_msg->gget('r_net_msg_fail'),
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}
	$r_command .= "# END: DATA\n";

	my $wait_window = gui_wait->start;
	use plotR::code_mat;
	my $plot = plotR::code_mat->new(
		r_command      => $r_command,
		#font_size      => $self->{font_obj}->font_size,

		heat_dendro_c  => $self->gui_jg( $self->{heat_dendro_c} ),
		heat_dendro_v  => $self->gui_jg( $self->{heat_dendro_v} ),
		heat_cellnote  => $self->gui_jg( $self->{heat_cellnote} ),
		plot_size_heat => $self->gui_jg( $self->{entry_plot_size_heat}->get ),
		
		bubble_size    => $self->gui_jg( $self->{entry_bubble_size}->get) /100,
		bubble_shape   => $self->gui_jg( $self->{bubble_shape} ),
		plot_size_mapw => $self->gui_jg( $self->{entry_plot_size_mapw}->get ),
		plot_size_maph => $self->gui_jg( $self->{entry_plot_size_maph}->get ),
		
		plotwin_name   => 'code_mat',
	);
	$wait_window->end(no_dialog => 1);

	if ($::main_gui->if_opened('w_cod_mat_plot')){
		$::main_gui->get('w_cod_mat_plot')->close;
	}

	return 0 unless $plot;

	use gui_window::r_plot::cod_mat;
	gui_window::r_plot::cod_mat->open(
		plots       => $plot->{result_plots},
		ax          => $self->{ax},
	);

	$plot = undef;

	$self->close;

	return 1;
}




sub win_title{
	return kh_msg->get('win_title'); # コーディング・多次元尺度法：調整
}

sub win_name{
	return 'w_cod_mat_plot_opt';
}

1;