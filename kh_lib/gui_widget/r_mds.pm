package gui_widget::r_mds;
use base qw(gui_widget);
use strict;
use Tk;
use utf8;
use Jcode;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();
	my $f4  = $win->Frame()->pack(-fill => 'x');

	$self->{method_opt}         = 'K'      unless defined $self->{method_opt};
	$self->{method_dist}        = 'binary' unless defined $self->{method_dist};
	$self->{dim_number}         = 2        unless defined $self->{dim_number};
	$self->{check_random_start} = 0        unless defined $self->{check_random_start};
	$self->{use_alpha}          = 1        unless defined $self->{use_alpha};
	$self->{fix_asp}            = 0        unless defined $self->{fix_asp};
	$self->{cls_if}             = 1        unless defined $self->{cls_if};
	
	my ($check_bubble, $num_size) = (1,100);

	my $cls_n_d = 3;
	if (defined $self->{from} && $self->{from} eq 'w_word_mds') {
		$cls_n_d = 8;
	}
	$self->{cls_n} = $cls_n_d unless defined $self->{cls_n};
	
	my $breaks;
	if ( length($self->{r_cmd}) ){
		if ($self->{r_cmd} =~ /method_mds <\- "(.+)"\n/){
			$self->{method_opt} = $1;
		} else {
			$self->{method_opt} = 'K';
		}

		if ($self->{r_cmd} =~ /method_coef <- "(.+)"\n/){
			$self->{method_dist} = $1;
		}

		if ( $self->{r_cmd} =~ /dim_n <\- ([123])\n/ ){
			$self->{dim_number} = $1;
		} else {
			$self->{dim_number} = 2;
		}

		if ( $self->{r_cmd} =~ /use_alpha <\- ([0-9]+)\n/ ){
			$self->{use_alpha} = $1;
		}

		if ( $self->{r_cmd} =~ /fix_asp <\- ([0-9]+)\n/ ){
			$self->{fix_asp} = $1;
		}

		if ( $self->{r_cmd} =~ /random_starts <\- 1/ ){
			$self->{check_random_start} = 1;
		}

		if ( $self->{r_cmd} =~ /bubble_size <\- ([0-9]+)\n/ ){
			$num_size = $1;
		}

		if ( $self->{r_cmd} =~ /bubble <\- ([0-9]+)\n/ ){
			$check_bubble = $1;
		}

		if ( $self->{r_cmd} =~ /# breaks: (.+)\n/ ){
			$breaks = $1;
			print "r_mds, breaks: $breaks\n";
		}
		$self->{r_cmd} =~ s/\n# breaks: (.+)\n//;

		# クラスター化のパラメーター
		if ( $self->{r_cmd} =~ /n_cls <\- ([0-9]+)\n/ ){
			$self->{cls_if} = $1;
			if ( $self->{cls_if} ){
				$self->{cls_n} = $self->{cls_if};
				$self->{cls_if} = 1;
			} else {
				$self->{cls_n} = $cls_n_d;
			}
		} else {
			$self->{cls_if} = 1;
			$self->{cls_n}  = $cls_n_d;
		}
		if ( $self->{r_cmd} =~ /cls_raw <\- ([0-9]+)\n/ ){
			my $v = $1;
			if ($v == 1){
				$self->{cls_nei} = 0;
			} else {
				$self->{cls_nei} = 1;
			}
		}

		$self->{r_cmd} = 1;
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
				['Jaccard', 'binary' ],
				['Dice',    'Dice'   ],
				['Simpson', 'Simpson'],
				['Cosine',  'pearson'],
				['Euclid',  'euclid' ],
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

	# バブルプロット
	my $lf = $win->Frame()->pack(
		-fill => 'x',
		#-pady => 4,
	);
	
	$self->{bubble_obj} = gui_widget::bubble->open(
		parent       => $lf,
		type         => 'mds',
		command      => $self->{command},
		pack    => {
			-anchor   => 'w',
		},
		check_bubble    => $check_bubble,
		breaks          => $breaks,
		num_size        => $num_size,
		config          => length($self->{r_cmd}),
	);

	# クラスター化
	$self->{cls_obj} = gui_widget::cls4mds->open(
		parent       => $lf,
		command      => $self->{command},,
		pack    => {
			-anchor   => 'w',
		},
		check_cls    => $self->{cls_if},
		cls_n        => $self->{cls_n},
		check_nei    => $self->{cls_nei},
	);

	# 半透明の色
	$lf->Checkbutton(
		-variable => \$self->{use_alpha},
		-text     => kh_msg->get('gui_window::word_mds->r_alpha'), 
	)->pack(-anchor => 'w');

	# aspect ratio
	$lf->Checkbutton(
		-variable => \$self->{fix_asp},
		-text     => kh_msg->get('fix_asp'), 
	)->pack(-anchor => 'w');

	# random start
	$self->{check_rs} = $lf->Checkbutton(
		-text => kh_msg->get('random_start'), # 乱数による探索
		-variable => \$self->{check_random_start},
		-font => "TKFN",
		-justify => 'left',
		-anchor => 'w',
	)->pack(-anchor => 'w');
	
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
		method         => $self->method,
		method_dist    => $self->method_dist,
		dim_number     => $self->dim_number,
		bubble         => $self->{bubble_obj}->check_bubble,
		bubble_size    => $self->{bubble_obj}->size,
		n_cls          => $self->{cls_obj}->n,
		cls_raw        => $self->{cls_obj}->raw,
		fix_asp        => gui_window->gui_jg( $self->{fix_asp} ),
		use_alpha      => gui_window->gui_jg( $self->{use_alpha} ),
		random_starts  => gui_window->gui_jg( $self->{check_random_start} ),
		breaks         => $self->{bubble_obj}->breaks,
	);
}

sub dim_number{
	my $self = shift;
	my $n = gui_window->gui_jgn( $self->{entry_dim_number}->get );
	unless ($n =~ /\A[123]\Z/) {
		$n = 2
	}
	return $n;
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