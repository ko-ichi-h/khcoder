package gui_widget::r_net;
use base qw(gui_widget);
use strict;
use Tk;
use utf8;

sub _new{
	my $self = shift;
	$self->{type} = '' unless defined( $self->{type} );

	my $lf = $self->parent->Frame();

	$self->{radio}                     = 'n'
		unless defined $self->{radio};
	unless ( defined $self->{edges_number} ){
		$self->{edges_number} = 60;
		if ($self->{from} && $self->{from} ne 'selected_netgraph'){
			if ( $self->{from}->win_name eq 'w_cod_netg'){
				$self->{edges_number} = 10;
			}
		}
	}
	$self->{edges_jac}                 = 0.2
		unless defined $self->{edges_jac};
	$self->{check_use_weight_as_width} = 0
		unless $self->{check_use_weight_as_width};
	$self->{check_use_freq_as_size}    = 1
		unless defined $self->{check_use_freq_as_size};
	$self->{check_smaller_nodes}       = 0
		unless defined $self->{check_smaller_nodes};
	$self->{standardize_coef}          = 1
		unless defined $self->{standardize_coef};
	$self->{edge_type}                 = "words"
		unless defined $self->{edge_type};

	my $num_size = 100;

	if ( length($self->{r_cmd}) ){
		my ($edges);
		if ($self->{r_cmd} =~ /edges <- ([0-9\.]+)\n/){
			$edges = $1;
		} else {
			die("cannot get configuration: edges");
		}
		if ($self->{r_cmd} =~ /th <- ([0-9\.eE\-\+]+)\n/){
			$self->{edges_jac} = $1;
		} else {
			die("cannot get configuration: th");
		}
		if ($self->{r_cmd} =~ /use_freq_as_size <- ([01])\n/){
			$self->{check_use_freq_as_size} = $1;
		} else {
			die("cannot get configuration: use_freq_as_size");
		}
		if ($self->{r_cmd} =~ /use_weight_as_width <- ([01])\n/){
			$self->{check_use_weight_as_width} = $1;
		} else {
			die("cannot get configuration: use_weight_as_width");
		}
		if ($self->{r_cmd} =~ /smaller_nodes <- ([01])\n/){
			$self->{check_smaller_nodes} = $1;
		} else {
			die("cannot get configuration: smaller_nodes");
		}
		if ($self->{r_cmd} =~ /com_method <\- "twomode/){
			$self->{edge_type} = "twomode";
		} else {
			$self->{edge_type} = "words";
		}
		if ($self->{r_cmd} =~ /min_sp_tree <- ([01])\n/){
			$self->{check_min_sp_tree} = $1;
		}
		if ($self->{r_cmd} =~ /min_sp_tree_only <- ([01])\n/){
			$self->{check_min_sp_tree_only} = $1;
		}
		if ($self->{r_cmd} =~ /use_alpha <- ([01])\n/){
			$self->{check_use_alpha} = $1;
		}
		if ($self->{r_cmd} =~ /gray_scale <- ([01])\n/){
			$self->{check_gray_scale} = $1;
		}
		if ($self->{r_cmd} =~ /fix_lab <- ([01])\n/){
			$self->{check_fix_lab} = $1;
		}
		if ($self->{r_cmd} =~ /view_coef <- ([01])\n/){
			$self->{view_coef} = $1;
		}
		if ($self->{r_cmd} =~ /cor_var <- ([01])\n/){
			$self->{check_cor_var} = $1;
		}
		if ($self->{r_cmd} =~ /cor_var_darker <- ([01])\n/){
			$self->{check_cor_var_darker} = $1;
		}
		if ($self->{r_cmd} =~ /method_coef <- "(.+)"\n/){
			$self->{method_coef} = $1;
		}
		if ($self->{r_cmd} =~ /standardize_coef <- ([01])\n/){
			$self->{standardize_coef} = $1;
		}

		# min coef. specified
		if ($edges == 0){
			$self->{radio} = 'j';
			if ($self->{r_cmd} =~ /# edges: ([0-9]+)\n/){
				$edges = $1;
			} else {
				die("cannot get configuration: edges 2A");
			}
		# number of edges specified
		} else {
			$self->{radio} = 'n';
			if ($self->{r_cmd} =~ /# min. jaccard: ([0-9\.eE\-\+]+)\n/){
				$self->{edges_jac} = $1;
			} else {
				die("cannot get configuration: edges 2B");
			}
		}
		$self->{edges_number}= $edges;

		if ( $self->{r_cmd} =~ /bubble_size <\- ([0-9]+)\n/ ){
			$num_size = $1;
		}

		$self->{r_cmd} = 1;
	}

	# Edge選択
	my $f5 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);
	
	$f5->Label(
		-text => kh_msg->get('filter_edges'), # 描画する共起関係（edge）の絞り込み
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left',);
	
	$self->{method_coef} = 'binary' unless $self->{method_coef};
	my $method_coef_wd = gui_widget::optmenu->open(
		parent  => $f5,
		pack    => {-anchor => 'w', -side => 'left'},
		options =>
			[
				['Jaccard', 'binary'],
				['Cosine',  'pearson'],
				['Euclid',  'euclid'],
			],
		variable => \$self->{method_coef},
	);
	
	if ( defined($self->{from}) && $self->{from} eq 'selected_netgraph') {
		$method_coef_wd->configure(-state => 'disabled');
	}
	
	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2,
	);

	$f4->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	$f4->Radiobutton(
		-text             => kh_msg->get('e_top_n'), # 描画数：
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
	$self->{entry_edges_number}->insert(0,$self->{edges_number});
	$self->{entry_edges_number}->bind("<Return>",   $self->{command})
		if defined( $self->{command} )
	;
	$self->{entry_edges_number}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} )
	;
	
	gui_window->config_entry_focusin($self->{entry_edges_number});

	$f4->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	$self->{widget_th1} = $f4->Radiobutton(
		-text             => kh_msg->get('e_jac'), # Jaccard係数：
		-font             => "TKFN",
		-variable         => \$self->{radio},
		-value            => 'j',
		-command          => sub{ $self->refresh;},
	)->pack(-anchor => 'w', -side => 'left');

	$self->{entry_edges_jac} = $f4->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_edges_jac}->insert(0,$self->{edges_jac});
	$self->{entry_edges_jac}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_edges_jac}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_edges_jac});

	$self->{widget_th2} = $f4->Label(
		-text => kh_msg->get('or_more'), # 以上
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	# coef. standardize
	if (
		!  ( $self->{r_cmd} )
		|| ( $self->{r_cmd} && $self->{edge_type} eq "twomode")
	) {
		my $f4a = $lf->Frame()->pack(
			-fill => 'x',
			-pady => 2,
		);
		$f4a->Label(
			-text => '  ',
			-font => "TKFN",
		)->pack(-anchor => 'w', -side => 'left');
		$self->{chkwid_standardize_coef} = $f4a->Checkbutton(
				-text     => kh_msg->get('standardize_coef'),
				-variable => \$self->{standardize_coef},
				-command  => sub{$self->refresh;},
				-anchor   => 'w',
		)->pack(-anchor => 'w', -side => 'left');
	}
	
	# Edgeの太さ
	my $edge_frame = $lf->Frame()->pack(-anchor => 'w');
	$edge_frame->Checkbutton(
			-text     => kh_msg->get('thicker'),
			-variable => \$self->{check_use_weight_as_width},
			-anchor => 'w',
	)->pack(-anchor => 'w', -side => 'left');

	$edge_frame->Checkbutton(
			-text     => kh_msg->get('view_coef'),
			-variable => \$self->{view_coef},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	# Nodeの大きさ
	$self->{bubble_obj} = gui_widget::bubble->open(
		parent       => $lf,
		type         => 'mds',
		command2      => sub {$self->refresh(3);},
		command      => $self->{command},
		pack    => {
			-anchor   => 'w',
		},
		check_bubble    => $self->{check_use_freq_as_size},
		num_size        => $num_size,
	);

	$self->{wc_smaller_nodes} = $lf->Checkbutton(
			-text     => kh_msg->get('smaller'), # すべての語を小さめの円で描画
			-variable => \$self->{check_smaller_nodes},
			-anchor   => 'w',
			-command  => sub{
				$self->{check_use_freq_as_size} = 0;
				$self->refresh(3);
			},
	)->pack(-anchor => 'w');

	$self->{check_min_sp_tree} = 0 unless defined($self->{check_min_sp_tree});
	if ($self->{r_cmd}){
		$lf->Checkbutton(
				-text     => kh_msg->get('min_sp_tree'),
				-variable => \$self->{check_min_sp_tree},
				-anchor => 'w',
				#-state => 'disabled',
		)->pack(-anchor => 'w');
	}

	$self->{check_min_sp_tree_only} = 0
		unless defined($self->{check_min_sp_tree_only})
	;
	$lf->Checkbutton(
			-text     => kh_msg->get('min_sp_tree_only'),
			-variable => \$self->{check_min_sp_tree_only},
			-anchor => 'w',
			#-state => 'disabled',
	)->pack(-anchor => 'w');

	# Coloring by Correlation
	if ($self->{r_cmd}) {
		# "configure" button screen
		if ( $self->{check_cor_var} ){
			$lf->Checkbutton(
					-text     => kh_msg->get('cor_var_darker'),
					-variable => \$self->{check_cor_var_darker},
					-anchor => 'w',
			)->pack(-anchor => 'w');
		}
	} else {
		# initial option screen
		$self->{check_cor_var} = 0
			unless defined($self->{check_cor_var})
		;
		$self->{wd_check_cor_var} = $lf->Checkbutton(
				-text     => kh_msg->get('cor_var'),
				-variable => \$self->{check_cor_var},
				-command  => sub{ $self->refresh;},
				-anchor => 'w',
		)->pack(-anchor => 'w');

		my $f7 = $lf->Frame()->pack(
			-fill => 'x',
			-pady => 1
		);
		
		$f7->Label(
			-text => '  ',
			-font => "TKFN",
		)->pack(-anchor => 'w', -side => 'left');

		$self->{var_obj2} = gui_widget::select_a_var->open(
			parent        => $f7,
			tani          => $self->{from}->tani,
			show_headings => 1,
			add_position  => 1,
			#pack          => {-anchor => 'center'},
		);
	}

	$self->{check_fix_lab} = 1 unless defined($self->{check_fix_lab});
	if ($self->{r_cmd}) {
		$lf->Checkbutton(
				-text     => kh_msg->get('fix_lab'),
				-variable => \$self->{check_fix_lab},
				-anchor => 'w',
		)->pack(-anchor => 'w');
	}

	$self->{check_use_alpha} = 1 unless defined($self->{check_use_alpha});
	$lf->Checkbutton(
			-text     => kh_msg->get('gui_window::word_mds->r_alpha'),
			-variable => \$self->{check_use_alpha},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$self->{check_gray_scale} = 0 unless defined($self->{check_gray_scale});
	#if ($self->{r_cmd}){
		$lf->Checkbutton(
				-text     => kh_msg->get('gray_scale'),
				-variable => \$self->{check_gray_scale},
				-anchor => 'w',
		)->pack(-anchor => 'w');
	#}

	$self->refresh(3);
	$self->{win_obj} = $lf;
	return $self;
}

sub refresh{
	my $self = shift;
	return unless $self->{wc_smaller_nodes};
	
	my (@dis, @nor);

	if ($self->{edge_type} eq 'twomode'){
		if ( $self->{standardize_coef} ){
			$self->{radio} = 'n';
			push @dis, $self->{widget_th1};
			push @dis, $self->{widget_th2};
		} else {
			push @nor, $self->{widget_th1};
			push @nor, $self->{widget_th2};
		}
	} else {
		push @nor, $self->{widget_th1};
		push @nor, $self->{widget_th2};
	}

	if ($self->{radio} eq 'n'){
		push @nor, $self->{entry_edges_number};
		push @dis, $self->{entry_edges_jac};
	} else {
		push @nor, $self->{entry_edges_jac};
		push @dis, $self->{entry_edges_number};
	}

	if ($self->{bubble_obj}->check_bubble){
		push @nor, $self->{bubble_obj}{chkw_main};
		push @dis, $self->{wc_smaller_nodes};
	} else {
		#push @dis, $self->{bubble_obj}{chkw_main};;
		push @nor, $self->{wc_smaller_nodes};
	}

	if ($self->{check_smaller_nodes}){
		push @dis,  $self->{bubble_obj}{chkw_main};
	} else {
		push @nor,  $self->{bubble_obj}{chkw_main};
	}

	unless ($self->{r_cmd}) {
		if ( $self->{from}{radio_type} eq "twomode" ){
			push @dis, $self->{wd_check_cor_var};
			push @nor, $self->{chkwid_standardize_coef};
			$self->{var_obj2}->disable;
		} else {
			push @nor, $self->{wd_check_cor_var};
			push @dis, $self->{chkwid_standardize_coef};
			if ($self->{check_cor_var}){
				$self->{var_obj2}->enable;
			} else {
				$self->{var_obj2}->disable;
			}
		}
	}
	


	foreach my $i (@nor){
		$i->configure(-state => 'normal') if $i;
	}

	foreach my $i (@dis){
		$i->configure(-state => 'disabled') if $i;
	}
	
	#$nor[0]->focus unless $_[0] == 3;
}

#----------------------#
#   設定へのアクセサ   #

sub params{
	my $self = shift;
	return (
		n_or_j              => $self->n_or_j,
		edges_num           => $self->edges_num,
		edges_jac           => $self->edges_jac,
		use_freq_as_size    => $self->{bubble_obj}->check_bubble,
		bubble_size         => $self->{bubble_obj}->size,
		#use_freq_as_fsize   => $self->use_freq_as_fsize,
		smaller_nodes       => $self->smaller_nodes,
		use_weight_as_width => $self->use_weight_as_width,
		min_sp_tree         => $self->min_sp_tree,
		min_sp_tree_only    => $self->min_sp_tree_only,
		use_alpha           => $self->use_alpha,
		gray_scale          => $self->gray_scale,
		edge_type           => $self->{edge_type},
		fix_lab             => $self->fix_lab,
		view_coef           => gui_window->gui_jg( $self->{view_coef} ),
		method_coef         => gui_window->gui_jg( $self->{method_coef} ),
		cor_var             => $self->cor_var,
		cor_var_darker      => gui_window->gui_jg( $self->{check_cor_var_darker} ),
		standardize_coef    => $self->{standardize_coef},
	);
}

sub cor_var{
	my $self = shift;
	
	# return 0 if "twomode" is selected
	if ( ref ( $self->{from} ) ){
		if ($self->{from}{radio_type} eq "twomode"){
			return 0;
		}
	}
	
	if ( defined( $self->{check_cor_var} ) ) {
		return $self->{check_cor_var};
	} else {
		return 0;
	}
}

sub n_or_j{
	my $self = shift;
	return gui_window->gui_jg( $self->{radio} );
}

sub edges_num{
	my $self = shift;
	return gui_window->gui_jgn( $self->{entry_edges_number}->get );
}

sub edges_jac{
	my $self = shift;
	my $n = $self->{entry_edges_jac}->get;
	$n =~ tr/。．、，,０-９/.....0-9/;
	return gui_window->gui_jg( $n );
}

sub use_alpha{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_use_alpha} );
}

sub gray_scale{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_gray_scale} );
}

sub fix_lab{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_fix_lab} );
}

sub use_freq_as_size{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_use_freq_as_size} );
}

sub min_sp_tree{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_min_sp_tree} );
}

sub min_sp_tree_only{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_min_sp_tree_only} );
}

sub smaller_nodes{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_smaller_nodes} );
}

sub use_weight_as_width{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_use_weight_as_width} );
}

sub edge_type{
	my $self = shift;
	return $self->{edge_type};
}

1;