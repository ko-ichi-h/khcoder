package gui_widget::cls4mds;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	
	my $win = $self->parent->Frame();

	$self->{check_cls} = 0 unless defined $self->{check_cls};
	$self->{check_nei} = 1 unless defined $self->{check_nei};
	$self->{cls_n}     = 7 unless defined $self->{cls_n};

	$win->Checkbutton(
			-text     => kh_msg->get('cluster_color'), # クラスター化と色分け
			-variable => \$self->{check_cls},
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
	$self->{entry_cls_num}->insert(0,$self->{cls_n});
	$self->{entry_cls_num}->bind("<Key-Return>", $self->{command})
		if defined( $self->{command} );
	$self->{entry_cls_num}->bind("<KP_Enter>", $self->{command})
		if defined( $self->{command} );
	gui_window->config_entry_focusin($self->{entry_cls_num});

	$self->{label_cls2} = $fcls1->Label(
		-text => kh_msg->get('2_12'), # （2から12まで）
		-font => "TKFN",
	)->pack(-side => 'left');

	my $fcls2 = $win->Frame()->pack(
		-fill => 'x',
		-pady => 2,
	);

	$fcls2->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-side => 'left');

	unless ( defined($self->{check_cls_raw}) ){
		$self->{check_cls_raw} = 1;
	}

	$self->{check_cls_raw_w} = $fcls2->Checkbutton(
			-text     => kh_msg->get('adj'), # 隣接クラスター
			-variable => \$self->{check_nei},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$self->refresh_cls;

	$self->{win_obj} = $win;
	return $self;
}

sub refresh_cls{
	my $self = shift;
	if ($self->{check_cls}){
		$self->{label_cls1}     ->configure(-state => 'normal');
		$self->{label_cls2}     ->configure(-state => 'normal');
		$self->{entry_cls_num}  ->configure(-state => 'normal');
		$self->{check_cls_raw_w}->configure(-state => 'normal');
	} else {
		$self->{label_cls1}     ->configure(-state => 'disable');
		$self->{label_cls2}     ->configure(-state => 'disable');
		$self->{entry_cls_num}  ->configure(-state => 'disable');
		$self->{check_cls_raw_w}->configure(-state => 'disable');
	}
	
	return $self;
}

#----------------------#
#   設定へのアクセサ   #

sub n{
	my $self = shift;
	if ( $self->{check_cls} ) {
		return gui_window->gui_jg( $self->{entry_cls_num}->get );
	} else {
		return 0;
	}
}

sub raw{
	my $self = shift;
	my $v = gui_window->gui_jg( $self->{check_nei} );
	if ($v){
		$v = 0;
	} else {
		$v = 1;
	}
	return $v;
}


1;