package gui_widget::r_cls;
use base qw(gui_widget);
use strict;
use Tk;
use utf8;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	my $f4  = $win->Frame()->pack(-fill => 'x');

	$self->{method_dist}    = 'binary' unless defined $self->{method_dist};
	$self->{check_color_cls}= 1        unless defined $self->{check_color_cls};
	$self->{cls_number}     = 'Auto'   unless defined $self->{cls_number};

	if ( length($self->{r_cmd}) ){
		if ( $self->{r_cmd} =~ /method_dist <\- \"(.+)\"/ ){
			$self->{method_dist} = $1;
		}
		else {
			$self->{method_dist} = 'binary';
		}

		if ( $self->{r_cmd} =~ /method_clst <\- \"(.+)\"/ ){
			$self->{method_mthd} = $1;
		}
		else {
			$self->{method_mthd} = 'ward';
		}

		if ( $self->{r_cmd} =~ /n_cls <- ([0-9]+)\n/ ){
			$self->{cls_number} = $1;
		} else {
			$self->{cls_number} = 0;
		}

		if ( $self->{r_cmd} =~ /ggplot2/ ){
			$self->{check_color_cls} = 1;
		} else {
			$self->{check_color_cls} = 0;
		}

		$self->{r_cmd} = undef;
	}

	# 方法
	$f4->Label(
		-text => kh_msg->get('method'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{method_mthd} = "ward" unless $self->{method_mthd};
	my $widget_method = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				[kh_msg->get('ward'),    'ward'    ],
				[kh_msg->get('average'), 'average' ],
				[kh_msg->get('complete'),'complete'],
			],
		variable => \$self->{method_mthd},
	);

	# 距離
	$f4->Label(
		-text => kh_msg->get('dist'), # 距離：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{method_dist} = 'binary' unless $self->{method_dist};
	my $widget_dist = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				['Jaccard', 'binary' ],
				['Dice',    'Dice'   ],
				['Simpson', 'Simpson' ],
				['Cosine',  'pearson'],
				['Euclid',  'euclid' ],
			],
		variable => \$self->{method_dist},
	);
	

	# クラスター数
	my $f5 = $win->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f5->Label(
		-text => kh_msg->get('n_cls'), # クラスター数：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_cluster_number} = $f5->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_cluster_number}->insert(0,$self->{cls_number});
	$self->{entry_cluster_number}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_cluster_number}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_cluster_number});

	$f5->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-side => 'left');

	# 色分け
	$f5->Checkbutton(
			-text     => kh_msg->get('color'), # クラスターの色分け
			-variable => \$self->{check_color_cls},
			-anchor => 'w',
	)->pack(-anchor => 'w', -side => 'left');

	$self->{win_obj} = $win;
	return $self;
}

#----------------------#
#   設定へのアクセサ   #

sub cluster_color{
	my $self = shift;
	return gui_window->gui_jg( $self->{check_color_cls} );
}

sub method_dist{
	my $self = shift;
	return gui_window->gui_jg( $self->{method_dist} );
}

sub method_mthd{
	my $self = shift;
	return gui_window->gui_jg( $self->{method_mthd} );
}

sub cluster_number{
	my $self = shift;
	return gui_window->gui_jgn( $self->{entry_cluster_number}->get );
}

sub params{
	my $self = shift;
	return (
		cluster_number => $self->cluster_number,
		cluster_color  => $self->cluster_color,
		method_dist    => $self->method_dist,
		method_mthd    => $self->method_mthd,
	);
}

1;