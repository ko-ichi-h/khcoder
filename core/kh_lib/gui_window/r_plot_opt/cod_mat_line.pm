package gui_window::r_plot_opt::cod_mat_line;
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
	
	my $lf = $self->{win_obj}->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
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

	# 共通のパラメーター
	my @code_names = ();
	if ( $self->{command_f} =~ /colnames\(d\) <\- c\((.+)\)\n/ ){
		@code_names = eval( "($1)" );
	}
	#if ( $self->{command_f} =~ /cex <\- (.+)\n/ ){
	#	$self->{font_size} = $1;
	#}
	
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

	$lf->Label(
		-text => kh_msg->get('gui_window::cod_corresp->select_codes'),
	)->pack(-anchor => 'nw', -padx => 2, -pady => 0);

	my $lf2 = $lf->Frame()->pack(
		-fill   => 'both',
		-expand => 1,
		-padx   => 2,
		-pady   => 2
	);

	$lf2->Label(
		-text => '    ',
		-font => "TKFN"
	)->pack(
		-anchor => 'w',
		-side   => 'left',
	);

	my $lf2_1 = $lf2->Frame(
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
	$self->{hlist} = $lf2_1->Scrolled(
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

	my $lf2_2 = $lf2->Frame()->pack(
		-fill   => 'x',
		-expand => 0,
		-side   => 'left'
	);
	$lf2_2->Button(
		-text => kh_msg->gget('all'), # すべて
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{$self->select_all;}
	)->pack(-pady => 3);
	$lf2_2->Button(
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
	my $lf3 = $lf->Frame()->pack(
		-fill   => 'x',
		-expand => 0,
		-padx   => 2,
		-pady   => 2
	);

	$lf3->Label(
		-text => kh_msg->get('gui_widget::r_font->font_size'),
	)->pack(-side => 'left');

	$self->{entry_font_size} = $lf3->Entry(
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left');
	gui_window->config_entry_focusin($self->{entry_font_size});
	$self->{entry_font_size}->bind("<Key-Return>", sub {$self->calc});
	$self->{entry_font_size}->bind("<KP_Enter>", sub {$self->calc});
	
	$self->{entry_font_size}->insert(0,$self->{font_size} );

	$lf3->Label(
		-text => '%',
	)->pack(-side => 'left');

	return $self;
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
	my $plot = plotR::code_mat_line->new(
		r_command      => $r_command,
		#font_size      => $self->{font_obj}->font_size,
		font_size      => $self->gui_jg( $self->{entry_font_size}->get) /100,
		selection      => \@selection,
		plotwin_name   => 'code_mat_line',
	);
	$wait_window->end(no_dialog => 1);

	if ($::main_gui->if_opened('w_cod_mat_line')){
		$::main_gui->get('w_cod_mat_line')->close;
	}

	return 0 unless $plot;

	use gui_window::r_plot::cod_mat_line;
	gui_window::r_plot::cod_mat_line->open(
		plots       => $plot->{result_plots},
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
	return kh_msg->get('win_title');
}

sub win_name{
	return 'w_cod_mat_plot_line_opt';
}

1;