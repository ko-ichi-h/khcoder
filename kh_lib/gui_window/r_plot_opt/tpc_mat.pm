package gui_window::r_plot_opt::tpc_mat;
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

	# OK, Cancel
	$self->{win_obj}->Button(
		-text => kh_msg->gget('cancel'),
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

	my $left  = $lf->Frame()->pack(-side => 'left', -fill => 'both', -expand => 1);
	my $right = $lf->Frame()->pack(-side => 'right', -fill => 'both');

	# 共通のパラメーター
	my @code_names = ();
	if ( $self->{command_f} =~ /colnames\(d\) <\- c\((.+)\)\n/ ){
		use Unicode::Escape;
		my $u = Unicode::Escape::unescape($1);
		$u = Encode::decode('UTF-8', $u);
		@code_names = eval( "($u)" );
	}
	
	my %selected = ();
	if ( $self->{command_f} =~ /d <\- as\.matrix\(d\[,c\((.+)\)\]\)\n/ ){
		#print "code selection: found!\n";
		my @selecteda = eval( "($1)" );
		foreach my $i (@selecteda){
			$selected{$i - 1} = 1;
		}
	} else {
		print "code selection: all\n";
		my $n = 0;
		foreach my $i (@code_names){
			$selected{$n} = 1;
			++$n;
		}
	}


	# 共通のGUI
	my $rf = $left->LabFrame(
		-label => kh_msg->get('gui_window::r_plot_opt::cod_mat->common'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	$rf->Label(
		-text => kh_msg->get('gui_window::r_plot_opt::tpc_mat_line->select_topics'),
	)->pack(-anchor => 'nw', -padx => 2, -pady => 0);

	my $rf2 = $rf->Frame()->pack(
		-fill   => 'both',
		-expand => 1,
		-padx   => 2,
		-pady   => 2
	);

	$rf2->Label(
		-text => '    ',
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);

	my $rf2_1 = $rf2->Frame(
		-borderwidth        => 2,
		-relief             => 'sunken',
	)->pack(
			-anchor => 'w',
			-side   => 'left',
			-pady   => 2,
			-padx   => 2,
			-fill   => 'both',
			-expand => 1
	);

	# コード選択用HList
	$self->{hlist} = $rf2_1->Scrolled(
		'HList',
		-scrollbars         => 'osoe',
		#-relief             => 'sunken',
		-font               => 'TKFN',
		-selectmode         => 'none',
		-indicator => 0,
		-highlightthickness => 0,
		-columns            => 1,
		-borderwidth        => 0,
		-height             => 12,
	)->pack(
		-fill   => 'both',
		-expand => 1
	);

	my $rf2_2 = $rf2->Frame()->pack(
		-fill   => 'x',
		-expand => 0,
		-side   => 'left'
	);
	$rf2_2->Button(
		-text => kh_msg->gget('all'), # すべて
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->select_all;}
	)->pack(-pady => 3);
	$rf2_2->Button(
		-text => kh_msg->gget('clear'), # クリア
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->select_none;}
	)->pack();

	# コードのリストアップ
	my $wleft = $self->{hlist}->ItemStyle('window',-anchor => 'w');

	my $row = 0;
	$self->{checks} = undef;
	foreach my $i (@code_names){
		if ($selected{$row}){
			$self->{checks}[$row]{check} = 1;
		} else {
			$self->{checks}[$row]{check} = 0;
		}
		
		$self->{checks}[$row]{name}  = $i;
		
		my $c = $self->{hlist}->Checkbutton(
			-text     => gui_window->gui_jchar($i),
			-variable => \$self->{checks}[$row]{check},
			-anchor => 'w',
		);
		
		$self->{checks}[$row]{widget} = $c;
		
		$self->{hlist}->add($row,-at => "$row");
		$self->{hlist}->itemCreate(
			$row,0,
			-itemtype  => 'window',
			-style     => $wleft,
			-widget    => $c,
		);
		++$row;
	}

	# フォントサイズ
	my $rf3 = $rf->Frame()->pack(
		-fill   => 'x',
		-expand => 0,
		-padx   => 2,
		-pady   => 2
	);

	$rf3->Label(
		-text => kh_msg->get('gui_widget::r_font->font_size'),
	)->pack(-side => 'left');

	$self->{entry_font_size} = $rf3->Entry(
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left');
	gui_window->config_entry_focusin($self->{entry_font_size});
	$self->{entry_font_size}->bind("<Key-Return>", sub {$self->calc});
	$self->{entry_font_size}->bind("<KP_Enter>", sub {$self->calc});
	
	$self->{entry_font_size}->insert(0,$self->{font_size});

	$rf3->Label(
		-text => '%',
	)->pack(-side => 'left');

	# ヒートマップのパラメーター
	if ( $self->{command_f} =~ /\ndendro_c <\- ([0-9]+)\n/ ){
		$self->{heat_dendro_c} = $1;
	}

	if ( $self->{command_f} =~ /\ndendro_v <\- ([0-9]+)\n/ ){
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

	if ( $self->{command_f} =~ /color_rsd <\- (.+)\n/ ){
		$self->{color_rsd} = $1;
	}

	my $breaks = '';
	if ( $self->{command_f} =~ /# breaks: (.+)\n/ ){
		$breaks = $1;
	}
	$self->{command_f} =~ s/\n# breaks: (.+)\n//;

	if ( $self->{command_f} =~ /color_gry <\- (.+)\n/ ){
		$self->{color_gry} = $1;
	}

	$self->{color_maxv} = 10;
	if ( $self->{command_f} =~ /\nmaxv <\- (.+)\n/ ){
		$self->{color_maxv} = $1;
	}

	$self->{color_fix} = 0;
	if ( $self->{command_f} =~ /\ncolor_fix <\- (.+)\n/ ){
		$self->{color_fix} = $1;
	}

	# ヒートマップのGUI
	my $lf_h = $right->LabFrame(
		-label => kh_msg->get('gui_window::r_plot::cod_mat->heat'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0, -anchor => 'nw');

	$lf_h->Checkbutton(
		-variable => \$self->{heat_cellnote},
		-text     => kh_msg->get('gui_window::r_plot_opt::cod_mat->cellnote'), 
	)->pack(-anchor => 'w');

	$lf_h->Checkbutton(
		-variable => \$self->{heat_dendro_c},
		-text     => kh_msg->get('dendro_c'), 
	)->pack(-anchor => 'w');

	$lf_h->Checkbutton(
		-variable => \$self->{heat_dendro_v},
		-text     => kh_msg->get('gui_window::r_plot_opt::cod_mat->dendro_v'), 
	)->pack(-anchor => 'w');

	my $f_h1 = $lf_h->Frame()->pack(-fill=>'x',-expand=>0); # プロット高さ
	$f_h1->Label(
		-text => kh_msg->get('gui_window::r_plot_opt::cod_mat->plot_size_heat'),
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
	if (0) {
	
	my $lf_f = $right->LabFrame(
		-label => kh_msg->get('gui_window::r_plot::cod_mat->fluc'),
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0, -anchor => 'nw');
	
	my $f_f1 = $lf_f->Frame()                               # バブルの大きさ
		->pack(-fill=>'x',-expand=>0, -pady => 2);
	$f_f1->Label(
		-text => kh_msg->get('gui_window::r_plot_opt::cod_mat->bubble_size'),
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
		-text => kh_msg->get('gui_window::r_plot_opt::cod_mat->bubble_shape'),
	)->pack(-side => 'left');

	$f_f3->Radiobutton(
		-text     => kh_msg->get('gui_window::r_plot_opt::cod_mat->square'),# 正方形
		-variable => \$self->{bubble_shape},
		-value    => 0,
	)->pack(-side => 'left');

	$f_f3->Radiobutton(
		-text     => kh_msg->get('gui_window::r_plot_opt::cod_mat->circle'),# 円
		-variable => \$self->{bubble_shape},
		-value    => 1,
	)->pack(-side => 'left');

	# breaks
	my $frm_breaks = $lf_f->Frame()->pack(
		-fill => 'x',
		-expand => 1,
	);
	
	$self->{lab_breaks} = $frm_breaks->Label(
		-text => kh_msg->get('gui_widget::bubble->breaks'),
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');
	
	$self->{ent_breaks} = $frm_breaks->Entry(
		-font       => "TKFN",
		-width      => 15,
		-background => 'white',
	)->pack(-side => 'left', -fill => 'x', -expand => 1, -padx => 2, -pady => 2);
	
	$self->{ent_breaks}->insert(0,$breaks);
	
	$self->{ent_breaks}->bind("<Key-Return>", sub{ $self->calc; });
	$self->{ent_breaks}->bind("<KP_Enter>",   sub{ $self->calc; });

	$lf_f->Checkbutton(                                     # 残差による色分け
		-variable => \$self->{color_rsd},
		-text     => kh_msg->get('gui_window::r_plot_opt::cod_mat->color_rsd'),
		-command  => sub {$self->color_widgets;}
	)->pack(-anchor => 'w');

	my $f_f4 = $lf_f->Frame()
		->pack(-fill=>'x',-expand=>0, -pady => 2)
	;

	$f_f4->Label(
		-text     => '  ',
	)->pack(-side => 'left');

	$self->{widget_color_col1} = $f_f4->Radiobutton( # カラー1
		-text     => kh_msg->get('gui_window::r_plot_opt::cod_mat->col1'),
		-variable => \$self->{color_gry},
		-value    => 0,
	)->pack(-side => 'left');

	#$self->{widget_color_col2} = $f_f4->Radiobutton( # カラー2
	#	-text     => kh_msg->get('col2'),
	#	-variable => \$self->{color_gry},
	#	-value    => -1,
	#)->pack(-side => 'left');

	$self->{widget_color_gry} = $f_f4->Radiobutton( # グレー
		-text     => kh_msg->get('gui_window::r_plot_opt::cod_mat->gray'),
		-variable => \$self->{color_gry},
		-value    => 1,
	)->pack(-side => 'left');

	$self->color_widgets;

	my $f_f5 = $lf_f->Frame()
		->pack(-fill=>'x',-expand=>0, -pady => 2)
	;

	$f_f5->Label(
		-text     => '  ',
	)->pack(-side => 'left');

	$f_f5->Checkbutton(                                     # カラースケール固定
		-variable => \$self->{color_fix},
		-text     => kh_msg->get('gui_window::r_plot_opt::cod_mat->color_fix'),
		-command  => sub {$self->color_fix;}
	)->pack(-anchor => 'w', -side => 'left');

	$self->{entry_color_fix} = $f_f5->Entry(
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left');
	gui_window->config_entry_focusin($self->{entry_color_fix});
	$self->{entry_color_fix}->bind("<Key-Return>", sub {$self->calc});
	$self->{entry_color_fix}->bind("<KP_Enter>", sub {$self->calc});
	$self->{entry_color_fix}->insert(0,$self->{color_maxv});
	$self->color_fix;

	my $f_f2 = $lf_f->Frame()                               # プロットの幅
		->pack(-fill=>'x',-expand=>0, -pady => 2);
	$f_f2->Label(
		-text => kh_msg->get('gui_window::r_plot_opt::cod_mat->plot_size_mapw'),
	)->pack(-side => 'left');
	
	$self->{entry_plot_size_mapw} = $f_f2->Entry(
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left');
	gui_window->config_entry_focusin($self->{entry_plot_size_mapw});
	$self->{entry_plot_size_mapw}->bind("<Key-Return>", sub {$self->calc});
	$self->{entry_plot_size_mapw}->bind("<KP_Enter>",   sub {$self->calc});
	
	$self->{entry_plot_size_mapw}->insert(0,$self->{plot_size_mapw});

	$f_f2->Label(                                            # プロットの高さ
		-text => kh_msg->get('gui_window::r_plot_opt::cod_mat->plot_size_maph'),
	)->pack(-side => 'left');
	
	$self->{entry_plot_size_maph} = $f_f2->Entry(
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left');
	gui_window->config_entry_focusin($self->{entry_plot_size_maph});
	$self->{entry_plot_size_maph}->bind("<Key-Return>", sub {$self->calc});
	$self->{entry_plot_size_maph}->bind("<KP_Enter>", sub {$self->calc});
	
	$self->{entry_plot_size_maph}->insert(0,$self->{plot_size_maph});
	
	}

	return $self;
}

sub color_fix{
	my $self = shift;
	
	if ($self->{color_fix}){
		$self->{entry_color_fix}->configure(-state => 'normal');
	} else {
		$self->{entry_color_fix}->configure(-state => 'disabled');
	}
	
	return 1;
}

sub color_widgets{
	my $self = shift;
	
	if ($self->{color_rsd}){
		$self->{widget_color_col1}->configure(-state => 'normal');
		#$self->{widget_color_col2}->configure(-state => 'normal');
		$self->{widget_color_gry}->configure(-state => 'normal');
	} else {
		$self->{widget_color_col1}->configure(-state => 'disabled');
		#$self->{widget_color_col2}->configure(-state => 'disabled');
		$self->{widget_color_gry}->configure(-state => 'disabled');
	}
	
	return 1;
}

sub calc{
	my $self = shift;
	$self->_configure_mother;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
		#print "chk: $r_command\n";
		#$r_command = Jcode->new($r_command)->euc
		#	if $::config_obj->os eq 'win32';
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

	my @selection = ();
	my $n = 1;
	foreach my $i (@{$self->{checks}}){
		push @selection, $n if $i->{check};
		++$n;
	}
	unless ($#selection > -1){
		gui_errormsg->open(
			type   => 'msg',
			window  => \$self->win_obj,
			msg    => kh_msg->get('select_1'), # 'コードを1つ以上選択してください。'
		);
		return 0;
	}

	my $wait_window = gui_wait->start;
	use plotR::code_mat;
	my $plot = plotR::code_mat->new(
		r_command      => $r_command,

		heat_dendro_c  => $self->gui_jg( $self->{heat_dendro_c} ),
		heat_dendro_v  => $self->gui_jg( $self->{heat_dendro_v} ),
		heat_cellnote  => $self->gui_jg( $self->{heat_cellnote} ),
		plot_size_heat => $self->gui_jgn( $self->{entry_plot_size_heat}->get ),
		
		#bubble_size    => $self->gui_jgn( $self->{entry_bubble_size}->get) /100,
		#bubble_shape   => $self->gui_jg( $self->{bubble_shape} ),
		#breaks         => $self->gui_jg( $self->{ent_breaks}->get ),
		#color_rsd      => $self->gui_jg( $self->{color_rsd} ),
		#color_gry      => $self->gui_jg( $self->{color_gry} ),
		#plot_size_mapw => $self->gui_jgn( $self->{entry_plot_size_mapw}->get ),
		#plot_size_maph => $self->gui_jgn( $self->{entry_plot_size_maph}->get ),
		
		#color_fix      => $self->gui_jg( $self->{color_fix} ),
		#color_maxv     => $self->gui_jgn( $self->{entry_color_fix}->get ),
		
		selection      => \@selection,
		font_size      => $self->gui_jgn( $self->{entry_font_size}->get) /100,
		plotwin_name   => 'tpc_mat',
		toppic_model   => 1,
	);
	$wait_window->end(no_dialog => 1);

	if ($::main_gui->if_opened('w_tpc_mat_plot')){
		$::main_gui->get('w_tpc_mat_plot')->close;
	}

	return 0 unless $plot;

	use gui_window::r_plot::tpc_mat;
	gui_window::r_plot::tpc_mat->open(
		plots       => $plot->{result_plots},
		ax          => $self->{ax},
		var   => $self->{var},
		tani  => $self->{tani},
	);

	$plot = undef;

	$self->close;

	return 1;
}


# すべて選択
sub select_all{
	my $self = shift;
	foreach my $i (@{$self->{checks}}){
		$i->{widget}->select;
	}
	return $self;
}

# クリア
sub select_none{
	my $self = shift;
	foreach my $i (@{$self->{checks}}){
		$i->{widget}->deselect;
	}
	return $self;
}


sub win_title{
	return kh_msg->get('win_title'); # コーディング・多次元尺度法：調整
}

sub win_name{
	return 'w_cod_mat_plot_opt';
}

1;