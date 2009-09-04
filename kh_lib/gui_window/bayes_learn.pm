package gui_window::bayes_learn;
use base qw(gui_window);
use strict;
use Tk;

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt('外部変数から学習'));

	my $lf_w = $win->LabFrame(
		-label => 'Basic Settings',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	$self->{words_obj} = gui_widget::words_bayes->open(
		parent => $lf_w,
		verb   => '学習に使用',
	);

	my $lf_x = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x', -expand => 0);

	$self->{chkw_over} = $lf_x->Checkbutton(
			-text     => $self->gui_jchar('既存の学習結果ファイルに今回の内容を追加する','euc'),
			-variable => \$self->{check_overwrite},
			-anchor => 'w',
			-command => sub {$self->w_status;},
	)->pack(-anchor => 'w');

	my $fcv = $lf_x->Frame()->pack(-fill => 'x', -expand => 0);

	$self->{chkw_cross} = $fcv->Checkbutton(
			-text     => $self->gui_jchar('交差妥当化を行う','euc'),
			-variable => \$self->{check_cross},
			-anchor => 'w',
			-command => sub {$self->w_status;},
	)->pack(-anchor => 'w', -side => 'left');
	
	$self->{label_fold} = $fcv->Label(
		-text       => '  Folds:',
		#-foreground => 'gray',
	)->pack(-anchor => 'w', -side => 'left');
	
	$self->{entry_fold} = $fcv->Entry(
		-width      => 3,
		-state      => 'normal',
	)->pack(-anchor => 'w', -side => 'left');
	
	$self->{entry_fold}->insert(0,10);
	$self->{entry_fold}->configure(-state => 'disable');
	$self->{entry_fold}->bind("<Key-Return>",sub{$self->calc;});
	gui_window->config_entry_focusin( $self->{entry_fold} );

	$self->{chkw_savel} = $lf_x->Checkbutton(
			-text     => $self->gui_jchar('分類ログをファイルに保存','euc'),
			-variable => \$self->{check_savel},
			-anchor => 'w',
			-command => sub {$self->w_status;},
	)->pack(-anchor => 'w');

	$self->{chkw_savev} = $lf_x->Checkbutton(
			-text     => $self->gui_jchar('分類結果を外部変数に保存','euc'),
			-variable => \$self->{check_savev},
			-anchor => 'w',
			-command => sub {$self->w_status;},
	)->pack(-anchor => 'w');

	my $fcv2 = $lf_x->Frame()->pack(-fill => 'x', -expand => 0);
	$self->{label_vname} = $fcv2->Label(
		-text       => $self->gui_jchar('変数名：'),
		#-foreground => 'gray',
	)->pack(-anchor => 'w', -side => 'left');

	$self->{entry_vname} = $fcv2->Entry(
		-width      => 10,
		-state      => 'normal',
	)->pack(-anchor => 'w', -side => 'left', -fill => 'x', -expand => 1);
	$self->{entry_vname}->bind("<Key-Return>",sub{$self->calc;});

	$win->Button(
		-text    => $self->gui_jchar('キャンセル'),
		-font    => "TKFN",
		-width   => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text    => 'OK',
		-width   => 8,
		-font    => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->calc;});}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se');

	$self->w_status;
	return $self;
}

	sub w_status{
		my $self = shift;
		if ( $self->{check_cross} && $self->{check_savev} ){
			$self->{entry_fold}->configure(-state => 'normal');
			$self->{label_fold}->configure(-state => 'normal');
			$self->{chkw_savel}->configure(-state => 'normal');
			$self->{chkw_savev}->configure(-state => 'normal');
			$self->{label_vname}->configure(-state => 'normal');
			$self->{entry_vname}->configure(-state => 'normal');
		}
		elsif ( $self->{check_cross} ){
			$self->{entry_fold}->configure(-state => 'normal');
			$self->{label_fold}->configure(-state => 'normal');
			$self->{chkw_savel}->configure(-state => 'normal');
			$self->{chkw_savev}->configure(-state => 'normal');
			$self->{label_vname}->configure(-state => 'disable');
			$self->{entry_vname}->configure(-state => 'disable');
		} else {
			$self->{entry_fold}->configure(-state => 'disable');
			$self->{label_fold}->configure(-state => 'disable');
			$self->{chkw_savel}->configure(-state => 'disable');
			$self->{chkw_savev}->configure(-state => 'disable');
			$self->{label_vname}->configure(-state => 'disable');
			$self->{entry_vname}->configure(-state => 'disable');
		}
	}

sub calc{
	my $self = shift;
	
	#------------------#
	#   入力チェック   #

	my $fold = $self->gui_jg( $self->{entry_fold}->get );
	if (
		   $fold =~ /[^0-9]/o
		|| $fold < 2
		|| $fold > 20
	){
		gui_errormsg->open(
			type => 'msg',
			msg  => 'Foldには2から20までの値を指定して下さい。',
		);
		return 0;
	}

	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}

	if ( $self->outvar == -1 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '外部変数の設定が不正です。。',
		);
		return 0;
	}

	my ($varname1, $varname2);
	if ($self->{check_savev}){
		$varname1 = $self->gui_jg( $self->{entry_vname}->get );
		$varname1 = Jcode->new($varname1,'sjis')->euc;
		unless (length($varname1)){
			gui_errormsg->open(
				type   => 'msg',
				msg    => '変数名を指定して下さい。',
				window => \$self->{win_obj},
			);
			return 0;
		}
		
		$varname2 = $varname1;
		$varname1 .= '-分類';
		$varname2 .= '-正否';
		foreach my $i ($varname1, $varname2){
			my $chk = mysql_outvar::a_var->new($i);
			if ( defined($chk->{id}) ){
				gui_errormsg->open(
					type   => 'msg',
					msg    => '指定された名前の変数がすでに存在します。',
					window => \$self->{win_obj},
				);
				return 0;
			}
		}
	}

	$self->{words_obj}->settings_save;

	my $ans = $self->win_obj->messageBox(
		-message => $self->gui_jchar
			(
			   "この処理には時間がかかることがあります。\n".
			   "続行しますか？"
			),
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	unless ($ans =~ /ok/i){ return 0; }

	# 保存先の参照
	my @types = (
		[ "KH Coder: Naive Bayes Moldels",[qw/.knb/] ],
		["All files",'*']
	);

	my $path;
	if ( $self->{check_overwrite} ){
		$path = $self->win_obj->getOpenFile(
			-defaultextension => '.knb',
			-filetypes        => \@types,
			-title            =>
				$self->gui_jt('今回の学習内容を追加するファイルを選択'),
			-initialdir       => $self->gui_jchar($::config_obj->cwd),
		);
	} else {
		$path = $self->win_obj->getSaveFile(
			-defaultextension => '.knb',
			-filetypes        => \@types,
			-title            =>
				$self->gui_jt('学習結果を新規ファイルに保存'),
			-initialdir       => $self->gui_jchar($::config_obj->cwd),
		);
	}

	unless ($path){
		return 0;
	}
	$path = gui_window->gui_jg_filename_win98($path);
	$path = gui_window->gui_jg($path);
	$path = $::config_obj->os_path($path);

	my $cross_path = '';
	if ( $self->{check_savel} ){
		@types = (
			[ "KH Coder: Naive Bayes logs",[qw/.nbl/] ],
			["All files",'*']
		);
		$cross_path = $self->win_obj->getSaveFile(
			-defaultextension => '.nbl',
			-filetypes        => \@types,
			-title            =>
				$self->gui_jt('分類ログをファイルに保存'),
			-initialdir       => $self->gui_jchar($::config_obj->cwd),
		);
		unless ($cross_path){
			return 0;
		}
		$cross_path = gui_window->gui_jg_filename_win98($cross_path);
		$cross_path = gui_window->gui_jg($cross_path);
		$cross_path = $::config_obj->os_path($cross_path);
	}

	#----------#
	#   実行   #

	unless ( $self->{words_obj}->check > 0 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '現在の設定内容では、使用できる語がありません。',
		);
		return 0;
	}

	use kh_nbayes;

	my $r = kh_nbayes->learn_from_ov(
		tani        => $self->tani,
		outvar      => $self->outvar,
		hinshi      => $self->hinshi,
		max         => $self->max,
		min         => $self->min,
		max_df      => $self->max_df,
		min_df      => $self->min_df,
		path        => $path,
		add_data    => $self->gui_jg( $self->{check_overwrite} ),
		cross_vl    => $self->gui_jg( $self->{check_cross} ),
		cross_fl    => $fold,
		cross_savel => $self->gui_jg( $self->{check_savel} ),
		cross_savev => $self->gui_jg( $self->{check_savev} ),
		cross_vn1   => $varname1,
		cross_vn2   => $varname2,
		cross_path  => $cross_path,
	);

	# 「外部変数リスト」を開く
	if ($self->{check_savev}){
		my $win_list = gui_window::outvar_list->open;
		$win_list->_fill;
	}

	my $msg = '';
	$msg .= "ナイーブベイズモデルの学習が完了しました。\n\n";
	$msg .= "今回学習した文書: $r->{instances}";
	if ($self->{check_overwrite}){
		$msg .= ", 文書の総数: $r->{instances_all}\n";
	} else {
		$msg .= "\n";
	}
	if ($self->{check_cross}){
		$msg .= "分類の正確さ: $r->{cross_vl_ok} / $r->{cross_vl_tested} (";
		$msg .= sprintf("%.1f",$r->{cross_vl_ok}/$r->{cross_vl_tested}*100);
		$msg .= "%),  ";
		$msg .= "Kappa: ";
		$msg .= sprintf("%.3f",$r->{kappa});
		
	}

	gui_errormsg->open(
		type => 'msg',
		msg  => $msg,
		icon => 'info',
	);

	$self->close;
	return 1;
}

#--------------#
#   アクセサ   #

sub min{
	my $self = shift;
	return $self->{words_obj}->min;
}
sub max{
	my $self = shift;
	return $self->{words_obj}->max;
}
sub min_df{
	my $self = shift;
	return $self->{words_obj}->min_df;
}
sub max_df{
	my $self = shift;
	return $self->{words_obj}->max_df;
}
sub tani{
	my $self = shift;
	return $self->{words_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{words_obj}->hinshi;
}
sub outvar{
	my $self = shift;
	return $self->{words_obj}->outvar;
}

sub win_name{
	return 'w_bayes_learn';
}

1;