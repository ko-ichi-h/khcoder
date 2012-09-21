package gui_window::doc_cls_res_opt;
use base qw(gui_window);

sub _new{
	my $self = shift;
	my %args = @_;
	
	$self->{command_f} = $args{command_f};
	$self->{tani}      = $args{tani};
	
	$self->{win_obj}->title($self->gui_jt( $self->win_title ));
	
	my $lf = $self->{win_obj}->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0);
	
	$self->{labframe} = $lf;
	#$self->innner;

	# クラスター分析のオプション
	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f4->Label(
		-text => kh_msg->get('gui_widget::r_cls->method'), # 方法：
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget_method = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				[kh_msg->get('gui_widget::r_cls->ward'),     'ward'    ],
				[kh_msg->get('gui_widget::r_cls->average'),  'average' ],
				[kh_msg->get('gui_widget::r_cls->complete'), 'complete'],
				[kh_msg->get('gui_widget::r_cls->clara'),    'clara'   ],
			],
		variable => \$self->{method_method},
		command  => sub {$self->config_dist;},
	);
	if ( $self->{command_f} =~ /link=\"ward\"/ ){
		$widget_method->set_value('ward');
	}
	elsif ($self->{command_f} =~ /link=\"average\"/){
		$widget_method->set_value('average');
	}
	elsif ($self->{command_f} =~ /link=\"complete\"/){
		$widget_method->set_value('complete');
	}
	else {
		$widget_method->set_value('clara');
	}

	$f4->Label(
		-text => kh_msg->get('gui_widget::r_cls->dist'), # 距離：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{widget_dist} = gui_widget::optmenu->open(
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

	if ( $self->{command_f} =~ /method=\"euclid\"/ ){
		$self->{widget_dist}->set_value('euclid');
	}
	elsif ($self->{command_f} =~ /method=\"binary\"/){
		$self->{widget_dist}->set_value('binary');
	}
	else {
		$self->{widget_dist}->set_value('pearson');
	}
	$self->config_dist;

	my $f5 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f5->Label(
		-text => kh_msg->get('gui_widget::r_cls->n_cls'), #   クラスター数：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_cluster_number} = $f5->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	if ( $self->{command_f} =~ /cutree\(dcls,k=([0-9]+)\)/ ){
		$self->{entry_cluster_number}->insert(0,$1);
	} else {
		$self->{entry_cluster_number}->insert(0,'10');
	}
	$self->{entry_cluster_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->{entry_cluster_number}->bind("<KP_Enter>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_cluster_number});


	$self->{win_obj}->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
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

sub config_dist{
	my $self = shift;
	if ( $self->{method_method} eq 'clara' ){
		$self->{widget_dist}->configure(-state => 'disable');
	} else {
		$self->{widget_dist}->configure(-state => 'normal');
	}
}

sub calc{
	my $self = shift;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
		#print "chk: $r_command\n";
		$r_command = Jcode->new($r_command)->euc
			if $::config_obj->os eq 'win32';
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('r_net_msg_fail') # 調整に失敗しましました。
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}

	#if (
	#	   $self->gui_jg( $self->{entry_cluster_number}->get ) =~ /Auto/i
	#) {
	#	gui_errormsg->open(
	#		type => 'msg',
	#		msg  => "このWindowでは「Auto」指定はできません。数値を入力してください",
	#	);
	#	return 0;
	#}

	$r_command .= "# END: DATA\n";

	my $wait_window = gui_wait->start;

	my $cluster = &gui_window::doc_cls::calc_exec(
		base_win       => $self,
		cluster_number => $self->gui_jg( $self->{entry_cluster_number}->get ),
		r_command      => $r_command,
		method_dist    => $self->gui_jg( $self->{method_dist} ),
		method_method  => $self->gui_jg( $self->{method_method} ),
		tani           => $self->{tani},
	);

	$wait_window->end(no_dialog => 1);
	$self->close;

	if ($::main_gui->if_opened('w_doc_cls_res')){
		$::main_gui->get('w_doc_cls_res')->close;
	}

	$cluster->open_result_win;

	$self = undef;
	return 1;
}

sub win_title{
	return kh_msg->get('win_title'); # 文書・クラスター分析：調整
}

sub win_name{
	return 'w_doc_cls_res_opt';
}


1;