package gui_window::doc_cls_res_sav;
use base qw(gui_window);

sub _new{
	my $self = shift;
	my %args = @_;
	
	$self->{var_from} = $args{var_from};
	
	$self->{win_obj}->title($self->gui_jt( $self->win_title ));
	
	my $lf = $self->{win_obj}->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0);
	
	$self->{labframe} = $lf;
	#$self->innner;

	$lf->Label(
		-text => kh_msg->get('desc'), # 分類結果を外部変数として保存します。
		-font => "TKFN",
	)->pack(-anchor => 'w');

	# クラスター数
	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f4->Label(
		-text => kh_msg->get('name'), # 変数名：
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_name} = $f4->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2, -fill => 'x', -expand => 1);

	$self->{entry_name}->bind("<Key-Return>",sub{$self->save;});
	$self->{entry_name}->bind("<KP_Enter>",sub{$self->save;});

	$self->{win_obj}->Button(
		-text => kh_msg->gget('cancel'), # キャンセル
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2, -pady => 2);

	$self->{win_obj}->Button(
		-text => kh_msg->gget('ok'),,
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->save;}
	)->pack(-side => 'right', -pady => 2);

	return $self;
}

sub save{
	my $self = shift;

	my $name =
		Jcode->new( $self->gui_jg( $self->{entry_name}->get ), 'sjis')->euc;
	
	unless ( length($name) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('specify_var'),# 変数名を指定してください
		);
		return 0;
	}

	my $var_obj = mysql_outvar::a_var->new($self->{var_from})->copy($name)
		or return 0;

	# 「外部変数リスト」を開く
	my $win_list = gui_window::outvar_list->open;
	$win_list->_fill;

	$self->close;
	return 1;
}

sub win_title{
	return kh_msg->get('win_title'); # 文書・クラスター分析：保存
}

sub win_name{
	return 'w_doc_cls_res_sav';
}


1;