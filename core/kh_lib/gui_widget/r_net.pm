package gui_widget::r_net;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	$self->{type} = '' unless defined( $self->{type} );

	my $lf = $self->parent->Frame();

	$self->{radio}                     = 'n'
		unless defined $self->{radio};
	$self->{edges_number}              = 60
		unless defined $self->{edges_number};
	$self->{edges_jac}                 = 0.2
		unless defined $self->{edges_jac};
	$self->{check_use_weight_as_width} = 0
		unless $self->{check_use_weight_as_width};
	$self->{check_use_freq_as_size}    = 0
		unless defined $self->{check_use_freq_as_size};
	$self->{check_use_freq_as_fsize}   = 0
		unless defined $self->{check_use_freq_as_fsize};
	$self->{check_smaller_nodes}       = 0
		unless defined $self->{check_smaller_nodes};

	if ( length($self->{r_cmd}) ){
		my ($edges);
		if ($self->{r_cmd} =~ /edges <- ([0-9\.]+)\n/){
			$edges = $1;
		} else {
			die("cannot get configuration: edges");
		}
		if ($self->{r_cmd} =~ /th <- ([0-9\.]+)\n/){
			$self->{edges_jac} = $1;
		} else {
			die("cannot get configuration: th");
		}
		if ($self->{r_cmd} =~ /use_freq_as_size <- ([01])\n/){
			$self->{check_use_freq_as_size} = $1;
		} else {
			die("cannot get configuration: use_freq_as_size");
		}
		if ($self->{r_cmd} =~ /use_freq_as_fontsize <- ([01])\n/){
			$self->{check_use_freq_as_fsize} = $1;
		} else {
			die("cannot get configuration: use_freq_as_fsize");
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
		} else {
			die("cannot get configuration: min_sp_tree");
		}

		if ($edges == 0){
			$self->{radio} = 'j';
			if ($self->{r_cmd} =~ /# edges: ([0-9]+)\n/){
				$edges = $1;
			} else {
				die("cannot get configuration: edges 2A");
			}
		} else {
			$self->{radio} = 'n';
			$self->{edges_number}= $edges;
			if ($self->{r_cmd} =~ /# min. jaccard: ([0-9\.]+)\n/){
				$self->{edges_jac} = $1;
			} else {
				die("cannot get configuration: edges 2B");
			}
		}

		$self->{r_cmd} = undef;
	}

	# Edge選択
	$lf->Label(
		-text => kh_msg->get('filter_edges'), # 描画する共起関係（edge）の絞り込み
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
	$self->{entry_edges_number}->bind("<Return>",$self->{command})
		if defined( $self->{command} )
	;
	$self->{entry_edges_number}->bind("<KP_Enter>",$self->{command})
		if defined( $self->{command} )
	;
	
	gui_window->config_entry_focusin($self->{entry_edges_number});

	$f4->Radiobutton(
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
	gui_window->config_entry_focusin($self->{entry_edges_jac});

	$f4->Label(
		-text => kh_msg->get('or_more'), # 以上
		-font => "TKFN",
	)->pack(-anchor => 'w', -side => 'left');

	# Edgeの太さ・Nodeの大きさ
	my $msg;
	if ($self->{type} eq 'codes'){
		$msg = kh_msg->get('larger_c');
	} else {
		$msg = kh_msg->get('larger');
	}
	
	$lf->Checkbutton(
			-text     => kh_msg->get('thicker'),
			-variable => \$self->{check_use_weight_as_width},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$self->{wc_use_freq_as_size} = $lf->Checkbutton(
			-text     => $msg, # 出現数の多い語ほど大きい円で描画','euc
			-variable => \$self->{check_use_freq_as_size},
			-anchor   => 'w',
			-command  => sub{
				$self->{check_smaller_nodes} = 0;
				$self->refresh(3);
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
	
	$self->{wc_use_freq_as_fsize} = $fontsize_frame->Checkbutton(
			-text     => kh_msg->get('larger_font'), # フォントも大きく ※EMFやEPSでの出力・印刷向け','euc
			-variable => \$self->{check_use_freq_as_fsize},
			-anchor => 'w',
			-state => 'disabled',
	)->pack(-anchor => 'w');

	$self->{wc_smaller_nodes} = $lf->Checkbutton(
			-text     => kh_msg->get('smaller'), # すべての語を小さめの円で描画','euc
			-variable => \$self->{check_smaller_nodes},
			-anchor   => 'w',
			-command  => sub{
				$self->{check_use_freq_as_size} = 0;
				$self->refresh(3);
			},
	)->pack(-anchor => 'w');

	$self->{check_min_sp_tree} = 0 unless defined($self->{check_min_sp_tree});
	$lf->Checkbutton(
			-text     => kh_msg->get('min_sp_tree'),
			-variable => \$self->{check_min_sp_tree},
			-anchor => 'w',
			#-state => 'disabled',
	)->pack(-anchor => 'w');

	$self->refresh(3);
	$self->{win_obj} = $lf;
	return $self;
}

sub refresh{
	my $self = shift;

	my (@dis, @nor);
	if ($self->{radio} eq 'n'){
		push @nor, $self->{entry_edges_number};
		push @dis, $self->{entry_edges_jac};
	} else {
		push @nor, $self->{entry_edges_jac};
		push @dis, $self->{entry_edges_number};
	}

	if ($self->{check_use_freq_as_size}){
		push @nor, $self->{wc_use_freq_as_fsize};
		push @dis, $self->{wc_smaller_nodes};
	} else {
		push @dis, $self->{wc_use_freq_as_fsize};
		push @nor, $self->{wc_smaller_nodes};
	}

	if ($self->{check_smaller_nodes}){
		push @dis, $self->{wc_use_freq_as_size};
		push @dis, $self->{wc_use_freq_as_fsize};
	} else {
		push @nor, $self->{wc_use_freq_as_size};
	}

	foreach my $i (@nor){
		$i->configure(-state => 'normal');
	}

	foreach my $i (@dis){
		$i->configure(-state => 'disabled');
	}
	
	$nor[0]->focus unless $_[0] == 3;
}

#----------------------#
#   設定へのアクセサ   #

sub n_or_j{
	my $self = shift;
	return gui_window->gui_jg( $self->{radio} );
}

sub edges_num{
	my $self = shift;
	return gui_window->gui_jg( $self->{entry_edges_number}->get );
}

sub edges_jac{
	my $self = shift;
	return gui_window->gui_jg( $self->{entry_edges_jac}->get );
}

sub use_freq_as_size{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_use_freq_as_size} );
}

sub use_freq_as_fsize{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_use_freq_as_fsize} );
}

sub min_sp_tree{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_min_sp_tree} );
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