package gui_widget::r_som;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	my $f4  = $win->Frame()->pack(-fill => 'x');

	$self->{n_nodes} = 15 unless defined $self->{n_nodes};
	$self->{if_cls}  =  1 unless defined $self->{if_cls};
	$self->{n_cls}   =  8 unless defined $self->{n_cls};

	if ( length($self->{r_cmd}) ){
		if ( $self->{r_cmd} =~ /n_cls <- ([0-9]+)\n/ ){
			$self->{n_cls} = $1;
		}

		if ($self->{n_cls} > 0){
			$self->{if_cls} = 1;
		} else {
			$self->{if_cls} = 0;
		}

		if ( $self->{r_cmd} =~ /n_nodes <- ([0-9]+)\n/ ){
			$self->{n_nodes} = $1;
		}

		$self->{r_cmd} = undef;
	}

	# ノード数
	my $f5 = $win->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f5->Label(
		-text => kh_msg->get('n_nodes1'), # ノード数：
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
	gui_window->config_entry_focusin($self->{entry_n_nodes});

	$f5->Label(
		-text => kh_msg->get('n_nodes2'), # ^2
		-font => "TKFN",
	)->pack(-side => 'left');

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
		-text => '  ',
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
	gui_window->config_entry_focusin($self->{entry_cls_num});

	$self->{label_cls2} = $fcls1->Label(
		-text => kh_msg->get('2_12'), # （2から12まで）
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->refresh_cls;


	$self->{win_obj} = $win;
	return $self;
}

sub refresh_cls{
	my $self = shift;
	if ($self->{if_cls}){
		$self->{label_cls1}     ->configure(-state => 'normal');
		$self->{label_cls2}     ->configure(-state => 'normal');
		$self->{entry_cls_num}  ->configure(-state => 'normal');
		#$self->{check_cls_raw_w}->configure(-state => 'normal');
	} else {
		$self->{label_cls1}     ->configure(-state => 'disable');
		$self->{label_cls2}     ->configure(-state => 'disable');
		$self->{entry_cls_num}  ->configure(-state => 'disable');
		#$self->{check_cls_raw_w}->configure(-state => 'disable');
	}
	
	return $self;
}

#----------------------#
#   設定へのアクセサ   #

sub n{
	my $self = shift;
	if ( $self->{if_cls} ) {
		return gui_window->gui_jg( $self->{entry_cls_num}->get );
	} else {
		return 0;
	}
}

sub params{
	my $self = shift;
	return (
		n_nodes => gui_window->gui_jg( $self->{entry_n_nodes}->get ),
		n_cls   => $self->n,,
	);
}

1;