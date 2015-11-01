package gui_widget::r_mds;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	my $f4  = $win->Frame()->pack(-fill => 'x');

	$self->{method_opt}         = 'K'      unless defined $self->{method_opt};
	$self->{method_dist}        = 'binary' unless defined $self->{method_dist};
	$self->{dim_number}         = 2        unless defined $self->{dim_number};
	$self->{check_random_start} = 0        unless defined $self->{check_random_start};

	if ( length($self->{r_cmd}) ){
		if ($self->{r_cmd} =~ /method_mds <\- "(.+)"\n/){
			$self->{method_opt} = $1;
		} else {
			$self->{method_opt} = 'K';
		}

		if ( $self->{r_cmd} =~ /dj .+euclid/ ){
			$self->{method_dist} = 'euclid';
		}
		elsif  ( $self->{r_cmd} =~ /dj .+binary/ ){
			$self->{method_dist} = 'binary';
		}
		else {
			$self->{method_dist} = 'pearson';
		}

		if ( $self->{r_cmd} =~ /dim_n <\- ([123])\n/ ){
			$self->{dim_number} = $1;
		} else {
			$self->{dim_number} = 2;
		}

		#if ( $self->{r_cmd} =~ /random_starts <\- 1/ ){
		#	$self->{check_random_start} = 1;
		#}

		$self->{r_cmd} = undef;
	}

	$f4->Label(
		-text => kh_msg->get('method'), # 方法：
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				['Classical', 'C' ],
				['Kruskal',   'K' ],
				['Sammon',    'S' ],
				['SMACOF',    'SM'],
			],
		variable => \$self->{method_opt},
		#command => sub{$self->check_rs_widget;},
	);

	$f4->Label(
		-text => kh_msg->get('dist'), #   距離：
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget_dist = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				['Jaccard', 'binary'],
				['Euclid',  'euclid'],
				['Cosine',  'pearson'],
			],
		variable => \$self->{method_dist},
	);

	# 次元の数
	my $fnd = $win->Frame()->pack(
		-fill => 'x',
		-pady => 4,
	);

	$fnd->Label(
		-text => kh_msg->get('dim'), # 次元：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_dim_number} = $fnd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_dim_number}->insert(0,$self->{dim_number});
	$self->{entry_dim_number}->bind("<Key-Return>",$self->{command})
		if defined( $self->{command} );
	$self->{entry_dim_number}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_dim_number});

	$fnd->Label(
		-text => kh_msg->get('1_3'), # （1から3までの範囲で指定）
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{win_obj} = $win;
	return $self;
}

#sub check_rs_widget{
#	my $self = shift;
#	if ( $self->{check_rs} ){
#		if (
#			   $self->{method_opt} eq 'K'
#			or $self->{method_opt} eq 'S'
#			or $self->{method_opt} eq 'SM'
#		){
#			$self->{check_rs}->configure(-state => 'normal');
#		 } else {
#			$self->{check_rs}->configure(-state => 'disable');
#		 }
#	}
#}

#----------------------#
#   設定へのアクセサ   #

sub params{
	my $self = shift;
	return (
		method        => $self->method,
		method_dist   => $self->method_dist,
		dim_number    => $self->dim_number,
		#random_starts => gui_window->gui_jg( $self->{check_random_start} ),
	);
}

sub dim_number{
	my $self = shift;
	return gui_window->gui_jg( $self->{entry_dim_number}->get );
}

sub method{
	my $self = shift;
	return gui_window->gui_jg( $self->{method_opt} );
}

sub method_dist{
	my $self = shift;
	return gui_window->gui_jg( $self->{method_dist} );
}

1;