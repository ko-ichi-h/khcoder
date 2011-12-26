package gui_widget::r_mds;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	my $f4  = $win->Frame()->pack(-fill => 'x');

	$self->{method_opt}  = 'K'      unless defined $self->{method_opt};
	$self->{method_dist} = 'binary' unless defined $self->{method_dist};
	$self->{dim_number}  = 2        unless defined $self->{dim_number};

	if ( length($self->{r_cmd}) ){
		if ($self->{r_cmd} =~ /isoMDS/){
			$self->{method_opt} = 'K';
		}
		elsif ($self->{r_cmd} =~ /sammon/){
			$self->{method_opt} = 'S';
		} else {
			$self->{method_opt} = 'C';
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

		if ( $self->{r_cmd} =~ /k=([123])[\), ]/ ){
			$self->{dim_number} = $1;
		} else {
			$self->{dim_number} = 2;
		}

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
				['Classical', 'C'],
				['Kruskal',   'K'],
				['Sammon',    'S'],
			],
		variable => \$self->{method_opt},
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
	gui_window->config_entry_focusin($self->{entry_dim_number});

	$fnd->Label(
		-text => kh_msg->get('1_3'), # （1から3までの範囲で指定）
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{win_obj} = $win;
	return $self;
}

#----------------------#
#   設定へのアクセサ   #

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