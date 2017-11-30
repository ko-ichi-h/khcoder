package gui_widget::r_som;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;

	my $win = $self->parent->Frame();

	$self->{n_nodes} = 20   unless defined $self->{n_nodes};
	$self->{if_cls}  =  1   unless defined $self->{if_cls};
	$self->{n_cls}   =  8   unless defined $self->{n_cls};
	$self->{p_topo}  = 'hx' unless defined $self->{p_topo};
	$self->{rlen1}   = 1000 unless defined $self->{rlen1};
	$self->{rlen2}   = 'Auto' unless defined $self->{rlen2};

	if ( length($self->{r_cmd}) ){
		if ( $self->{r_cmd} =~ /n_cls <- ([0-9]+)\n/ ){
			$self->{n_cls} = $1;
		}

		if ( $self->{r_cmd} =~ /if_cls <- ([0-9]+)\n/ ){
			$self->{if_cls} = $1;
		}

		if ( $self->{r_cmd} =~ /n_nodes <- ([0-9]+)\n/ ){
			$self->{n_nodes} = $1;
		}

		if ( $self->{r_cmd} =~ /rlen1 <- ([0-9]+)\n/ ){
			$self->{rlen1} = $1;
		}

		if ( $self->{r_cmd} =~ /rlen2 <- ([0-9]+)\n/ ){
			$self->{rlen2} = $1;
		}

		if ( $self->{r_cmd} =~ /if_plothex <- ([01])\n/ ){
			if ($1 == 1){
				$self->{p_topo} = 'hx';
			} else {
				$self->{p_topo} = 'sq';
			}
		}

		$self->{r_cmd} = undef;
	}

	# ノード数
	my $f5 = $win->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$self->{cd_l1} = $f5->Label(
		-text => kh_msg->get('n_nodes1'), # 1辺のノード数：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_n_nodes} = $f5->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_n_nodes}->insert(0,$self->{n_nodes});
	$self->{entry_n_nodes}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_n_nodes}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_n_nodes});

	$f5->Label(
		-text => ' ',
		-font => "TKFN",
	)->pack(-side => 'left');

	# 描画の形状
	$f5->Label(
		-text => kh_msg->get('p_nodes'), # 描画の形状：
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget = gui_widget::optmenu->open(
		parent  => $f5,
		pack    => {-side => 'left'},
		options =>
			[
				[kh_msg->get('hex'),'hx'],
				[kh_msg->get('sq'), 'sq'],
			],
		variable => \$self->{p_topo},
	);

	# クラスター化
	$win->Checkbutton(
			-text     => kh_msg->get('cluster_color'), # ノードのクラスター化
			-variable => \$self->{if_cls},
			-command  => sub{$self->refresh_cls},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	my $fcls1 = $win->Frame()->pack(
		-fill => 'x',
		-pady => 2,
	);

	$fcls1->Label(
		-text => '    ',
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{label_cls1} = $fcls1->Label(
		-text => kh_msg->get('cls_num'), # クラスター数：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_cls_num} = $fcls1->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_cls_num}->insert(0,$self->{n_cls});
	$self->{entry_cls_num}->bind("<Key-Return>", $self->{command})
		if defined( $self->{command} );
	$self->{entry_cls_num}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_cls_num});

	#$self->{label_cls2} = $fcls1->Label(
	#	-text => kh_msg->get('2_12'), # （2から12まで）
	#	-font => "TKFN",
	#)->pack(-side => 'left');

	$self->refresh_cls;

	# 学習回数
	my $f4 = $win->Frame()->pack( -fill => 'x', -pady => 2);
	$self->{cd_l2} = $f4->Label(
		-text => kh_msg->get('rlen'), # 学習回数
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_rlen1} = $f4->Entry(
		-font       => "TKFN",
		-width      => 5,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_rlen1}->insert(0,$self->{rlen1});
	$self->{entry_rlen1}->bind("<Key-Return>", $self->{command})
		if defined( $self->{command} );
	$self->{entry_rlen1}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_rlen1});

	$self->{cd_l3} = $f4->Label(
		-text => ', ',
	)->pack(-side => 'left');

	$self->{entry_rlen2} = $f4->Entry(
		-font       => "TKFN",
		-width      => 7,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_rlen2}->insert(0,$self->{rlen2});
	$self->{entry_rlen2}->bind("<Key-Return>", $self->{command})
		if defined( $self->{command} );
	$self->{entry_rlen2}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_rlen2});

	if ( $self->{reuse} ){
		$self->{cd_l1}         ->configure(-state => 'disable');
		$self->{entry_n_nodes} ->configure(-state => 'disable');
		$self->{cd_l2}         ->configure(-state => 'disable');
		$self->{entry_rlen1}   ->configure(-state => 'disable');
		$self->{entry_rlen2}   ->configure(-state => 'disable');
	}

	$self->{win_obj} = $win;
	return $self;
}

sub refresh_cls{
	my $self = shift;
	if ($self->{if_cls}){
		$self->{label_cls1}     ->configure(-state => 'normal');
		#$self->{label_cls2}     ->configure(-state => 'normal');
		$self->{entry_cls_num}  ->configure(-state => 'normal');
		#$self->{check_cls_raw_w}->configure(-state => 'normal');
	} else {
		$self->{label_cls1}     ->configure(-state => 'disable');
		#$self->{label_cls2}     ->configure(-state => 'disable');
		$self->{entry_cls_num}  ->configure(-state => 'disable');
		#$self->{check_cls_raw_w}->configure(-state => 'disable');
	}
	
	return $self;
}

#----------------------#
#   設定へのアクセサ   #

sub rlen2{
	my $self = shift;
	my $r = gui_window->gui_jg( $self->{entry_rlen2}->get );
	if ($r =~ /auto/i){
		$r = gui_window->gui_jg( $self->{entry_n_nodes}->get );
		$r = $r * $r * 500;
	}
	#print "rlen2: $r\n";
	return $r;
}

sub params{
	my $self = shift;
	return (
		n_nodes => gui_window->gui_jg( $self->{entry_n_nodes}->get ),
		if_cls  => gui_window->gui_jg( $self->{if_cls} ),
		n_cls   => gui_window->gui_jg( $self->{entry_cls_num}->get ),
		p_topo  => gui_window->gui_jg( $self->{p_topo} ),
		rlen1   => gui_window->gui_jg( $self->{entry_rlen1}->get ),
		rlen2   => $self->rlen2,
	);
}

1;