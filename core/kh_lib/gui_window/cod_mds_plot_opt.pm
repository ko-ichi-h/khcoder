package gui_window::cod_mds_plot_opt;
use base qw(gui_window);

sub _new{
	my $self = shift;
	my %args = @_;
	
	$self->{command_f} = $args{command_f};
	
	$self->{win_obj}->title($self->gui_jt('多次元尺度法（コード）の調整'));
	
	my $lf = $self->{win_obj}->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0);
	
	
	# 方法
	my $fd = $lf->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 4,
	);

	$fd->Label(
		-text => $self->gui_jchar('方法：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget = gui_widget::optmenu->open(
		parent  => $fd,
		pack    => {-side => 'left'},
		options =>
			[
				['Classical', 'C'],
				['Kruskal',   'K'],
				['Sammon',    'S'],
			],
		variable => \$self->{method_opt},
	);
	$widget->set_value('K');

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
	$self->{entry_font_size}->insert(0,'80');
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
	$self->{entry_plot_size}->insert(0,'480');
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

	# アルゴリズム別のコマンド
	my $r_command_d = '';
	my $r_command_a = '';
	if ($self->{method_opt} eq 'K'){
		$r_command .= "library(MASS)\n";
		$r_command .= 'c <- isoMDS(dist(d, method = "binary"), k=2)'."\n";
		
		$r_command_d = $r_command;
		$r_command_d .=
			 'plot(c$points,pch=20,col="mediumaquamarine",'
				.'xlab="次元1",ylab="次元2")'."\n"
			."library(maptools)\n"
			.'pointLabel('
				.'x=c$points[,1], y=c$points[,2], labels=rownames(c$points),'
				."cex=$fontsize, offset=0)\n";
		;
		
		$r_command_a .= 
			 'plot(c$points,'
				.'xlab="次元1",ylab="次元2")'."\n"
		;
		$r_command .= $r_command_a;
	}
	elsif ($self->{method_opt} eq 'S'){
		$r_command .= "library(MASS)\n";
		$r_command .= 'c <- sammon(dist(d, method = "binary"), k=2)'."\n";
		
		$r_command_d = $r_command;
		$r_command_d .=
			 'plot(c$points,pch=20,col="mediumaquamarine",'
				.'xlab="次元1",ylab="次元2")'."\n"
			."library(maptools)\n"
			.'pointLabel('
				.'x=c$points[,1], y=c$points[,2], labels=rownames(c$points),'
				."cex=$fontsize, offset=0)\n";
		;
		
		$r_command_a .= 
			 'plot(c$points,'
				.'xlab="次元1",ylab="次元2")'."\n"
		;
		$r_command .= $r_command_a;
	}
	elsif ($self->{method_opt} eq 'C'){
		$r_command .= 'c <- cmdscale( dist(d, method = "binary") )'."\n";
		
		$r_command_d = $r_command;
		$r_command_d .=
			 'plot(c,pch=20,col="mediumaquamarine",'
				.'xlab="次元1",ylab="次元2")'."\n"
			."library(maptools)\n"
			.'pointLabel('
				.'x=c[,1], y=c[,2], labels=rownames(c),'
				."cex=$fontsize, offset=0)\n";
		;
		
		$r_command_a .=
			 'plot(c$points,'
				.'xlab="次元1",ylab="次元2")'."\n"
		;
		$r_command .= $r_command_a;
	}

	# プロット作成
	use kh_r_plot;
	my $plot1 = kh_r_plot->new(
		name      => 'codes_MDS',
		command_f => $r_command_d,
		width     => $self->gui_jg( $self->{entry_plot_size}->get ),
		height    => $self->gui_jg( $self->{entry_plot_size}->get ),
	) or return 0;
	my $plot2 = kh_r_plot->new(
		name      => 'codes_MDS_d',
		command_a => $r_command_a,
		command_f => $r_command,
		width     => $self->gui_jg( $self->{entry_plot_size}->get ),
		height    => $self->gui_jg( $self->{entry_plot_size}->get ),
	) or return 0;

	# ストレス値の取得
	my $stress;
	if ($self->{method_opt} eq 'K' or $self->{method_opt} eq 'S'){
		$::config_obj->R->send(
			 'str <- paste("khcoder",c$stress, sep = "")'."\n"
			.'print(str)'
		);
		$stress = $::config_obj->R->read;

		if ($stress =~ /"khcoder(.+)"/){
			$stress = $1;
			$stress /= 100 if $self->{method_opt} eq 'K';
			$stress = sprintf("%.3f",$stress);
		} else {
			$stress = undef;
		}
	}

	# プロットWindowを開く
	if ($::main_gui->if_opened('w_cod_mds_plot')){
		$::main_gui->get('w_cod_mds_plot')->close;
	}
	$self->close;
	gui_window::cod_mds_plot->open(
		plots       => [$plot1, $plot2],
		stress      => $stress,
		no_geometry => 1,
	);
	
	return 1;

}

sub win_name{
	return 'w_cod_mds_plot_opt';
}

1;