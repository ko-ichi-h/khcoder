package gui_window::word_cls_plot_opt;
use base qw(gui_window);

sub _new{
	my $self = shift;
	my %args = @_;
	
	$self->{command_f} = $args{command_f};
	
	$self->{win_obj}->title($self->gui_jt('クラスター分析（抽出語）の調整'));
	
	my $lf = $self->{win_obj}->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0);

	# クラスター数
	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 2
	);
	$f4->Label(
		-text => $self->gui_jchar('クラスター数：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_cluster_number} = $f4->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	if ( $args{command_f} =~ /rect\.hclust.+k=([0-9]+)[, \)]/ ){
		$self->{entry_cluster_number}->insert(0,$1);
	} else {
		$self->{entry_cluster_number}->insert(0,'0');
	}
	$self->{entry_cluster_number}->bind("<Key-Return>",sub{$self->calc;});

	# フォントサイズ
	my $ff = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 4,
	);

	$ff->Label(
		-text => $self->gui_jchar('フォントサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_font_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	
	if ($args{command_f} =~ /cex=([0-9\.]+)[, \)]/){
		my $cex = $1;
		$cex *= 100;
		$self->{entry_font_size}->insert(0,$cex);
	} else {
		$self->{entry_font_size}->insert(0,'80');
	}
	$self->{entry_font_size}->bind("<Key-Return>",sub{$self->calc;});

	$ff->Label(
		-text => $self->gui_jchar('%'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$ff->Label(
		-text => $self->gui_jchar('  プロットサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_plot_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	if ($args{size}){
		$self->{entry_plot_size}->insert(0,$args{size});
	} else {
		$self->{entry_plot_size}->insert(0,'480');
	}
	$self->{entry_plot_size}->bind("<Key-Return>",sub{$self->calc;});



	$self->{win_obj}->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $self->{win_obj}->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2, -pady => 2);

	$self->{win_obj}->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $self->{win_obj}->after(10,sub{$self->calc;});}
	)->pack(-side => 'right', -pady => 2);

	return $self;
}

sub calc{
	my $self = shift;

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
		#print "chk: $r_command\n";
		$r_command = Jcode->new($r_command)->euc
			if $::config_obj->os eq 'win32';
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => '調整に失敗しましました。',
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}

	$r_command .= "# END: DATA\n";

	my $cluster_number = $self->gui_jg( $self->{entry_cluster_number}->get );

	my $par = 
		"par(
			mai=c(0,0,0,0),
			mar=c(1,2,1,0),
			omi=c(0,0,0,0),
			oma=c(0,0,0,0) 
		)\n"
	;

	my $r_command_2a = 
		"$par"
		.'plot(hclust(dist(d,method="binary"),method="'
			.'single'
			.'"),labels=rownames(d), main="", sub="", xlab="",ylab="",'
			."cex=$fontsize, hang=-1)\n"
	;
	$r_command_2a .= 
		'rect.hclust(hclust(dist(d,method="binary"),method="'
			.'single'
			.'"), k='.$cluster_number.', border="#FF8B00FF")'
		if $cluster_number > 1;
	
	my $r_command_2 = $r_command.$r_command_2a;

	my $r_command_3a = 
		"$par"
		.'plot(hclust(dist(d,method="binary"),method="'
			.'complete'
			.'"),labels=rownames(d), main="", sub="", xlab="",ylab="",'
			."cex=$fontsize, hang=-1)\n"
	;
	$r_command_3a .= 
		'rect.hclust(hclust(dist(d,method="binary"),method="'
			.'complete'
			.'"), k='.$cluster_number.', border="#FF8B00FF")'
		if $cluster_number > 1;
	my $r_command_3 = $r_command.$r_command_3a;

	$r_command .=
		"$par"
		.'plot(hclust(dist(d,method="binary"),method="'
			.'average'
			.'"),labels=rownames(d), main="", sub="", xlab="",ylab="",'
			."cex=$fontsize, hang=-1)\n"
	;
	$r_command .= 
		'rect.hclust(hclust(dist(d,method="binary"),method="'
			.'average'
			.'"), k='.$cluster_number.', border="#FF8B00FF")'
		if $cluster_number > 1;

	# プロット作成
	use kh_r_plot;
	my $plot1 = kh_r_plot->new(
		name      => 'words_CLS1',
		command_f => $r_command,
		width     => $self->gui_jg( $self->{entry_plot_size}->get ),
		height    => 480,
	) or return 0;
	$plot1->rotate_cls;

	my $plot2 = kh_r_plot->new(
		name      => 'words_CLS2',
		command_a => $r_command_2a,
		command_f => $r_command_2,
		width     => $self->gui_jg( $self->{entry_plot_size}->get ),
		height    => 480,
	) or return 0;
	$plot2->rotate_cls;

	my $plot3 = kh_r_plot->new(
		name      => 'words_CLS3',
		command_a => $r_command_3a,
		command_f => $r_command_3,
		width     => $self->gui_jg( $self->{entry_plot_size}->get ),
		height    => 480,
	) or return 0;
	$plot3->rotate_cls;

	# プロットWindowを開く
	if ($::main_gui->if_opened('w_word_cls_plot')){
		$::main_gui->get('w_word_cls_plot')->close;
	}
	$self->close;
	gui_window::word_cls_plot->open(
		plots       => [$plot1,$plot2,$plot3],
		no_geometry => 1,
	);

	return 1;
}

sub win_name{
	return 'w_word_cls_plot_opt';
}

1;