package gui_window::word_cls;
use base qw(gui_window);

use strict;

use Tk;

use gui_widget::tani;
use gui_widget::hinshi;
use mysql_crossout;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));

	my $lf = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	my $left = $lf->Frame()->pack(-fill => 'both', -expand => 1);

	# 集計単位の選択
	my $l1 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l1->Label(
		-text => $self->gui_jchar('・集計単位：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	my %pack = (
			-anchor => 'e',
			-pady   => 0,
			-side   => 'left'
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $l1,
		pack   => \%pack,
		#dont_remember => 1,
	);

	# 最小・最大出現数
	$left->Label(
		-text => $self->gui_jchar('・最小/最大 出現数による語の取捨選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);
	my $l2 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l2->Label(
		-text => $self->gui_jchar('　 　最小出現数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min} = $l2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min}->insert(0,'1');
	$self->{ent_min}->bind("<Key-Return>",sub{$self->check;});
	$self->config_entry_focusin($self->{ent_min});
	
	$l2->Label(
		-text => $self->gui_jchar('　 最大出現数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max} = $l2->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_max}->bind("<Key-Return>",sub{$self->check;});
	$self->config_entry_focusin($self->{ent_max});

	# 最小・最大文書数
	$left->Label(
		-text => $self->gui_jchar('・最小/最大 文書数による語の取捨選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);

	my $l3 = $left->Frame()->pack(-fill => 'x', -pady => 2);
	$l3->Label(
		-text => $self->gui_jchar('　 　最小文書数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_min_df} = $l3->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_min_df}->insert(0,'1');
	$self->{ent_min_df}->bind("<Key-Return>",sub{$self->check;});
	$self->config_entry_focusin($self->{ent_min_df});

	$l3->Label(
		-text => $self->gui_jchar('　 最大文書数：'),
		-font => "TKFN"
	)->pack(-side => 'left');
	$self->{ent_max_df} = $l3->Entry(
		-font       => "TKFN",
		-width      => 6,
		-background => 'white',
	)->pack(-side => 'left');
	$self->{ent_max_df}->bind("<Key-Return>",sub{$self->check;});
	$self->config_entry_focusin($self->{ent_max_df});

	# 品詞による単語の取捨選択
	$left->Label(
		-text => $self->gui_jchar('・品詞による語の取捨選択'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -pady => 2);
	my $l5 = $left->Frame()->pack(-fill => 'both',-expand => 1, -pady => 2);
	$l5->Label(
		-text => $self->gui_jchar('　　'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left',-fill => 'y',-expand => 1);
	%pack = (
			-anchor => 'w',
			-side   => 'left',
			-pady   => 1,
			-fill   => 'y',
			-expand => 1
	);
	$self->{hinshi_obj} = gui_widget::hinshi->open(
		parent => $l5,
		pack   => \%pack
	);
	my $l4 = $l5->Frame()->pack(-fill => 'x', -expand => 'y',-side => 'left');
	$l4->Button(
		-text => $self->gui_jchar('全て選択'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->{hinshi_obj}->select_all;});}
	)->pack(-pady => 3);
	$l4->Button(
		-text => $self->gui_jchar('クリア'),
		-width => 8,
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->{hinshi_obj}->select_none;});}
	)->pack();

	# チェック部分
	$lf->Label(
		-text => $self->gui_jchar('・現在の設定で分類される語の数：'),
		-font => "TKFN"
	)->pack(-anchor => 'w');

	my $cf = $lf->Frame()->pack(-fill => 'x', -pady => 2);

	$cf->Label(
		-text => $self->gui_jchar('　 　'),
		-font => "TKFN"
	)->pack(-anchor => 'w', -side => 'left');

	$cf->Button(
		-text => $self->gui_jchar('チェック'),
		-font => "TKFN",
		-borderwidth => 1,
		-command => sub{ $mw->after(10,sub{$self->check;});}
	)->pack(-side => 'left', -padx => 2);

	$self->{ent_check} = $cf->Entry(
		-font        => "TKFN",
		-background  => 'gray',
		-foreground  => 'black',
		-state       => 'disable',
	)->pack(-side => 'left', -fill => 'x', -expand => 1);
	$self->disabled_entry_configure($self->{ent_check});

	# クラスター数
	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f4->Label(
		-text => $self->gui_jchar('・距離：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget_dist = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				['Jaccard', 'binary'],
				['Euclid',  'euclid'],
			],
		variable => \$self->{method_dist},
	);
	$widget_dist->set_value('binary');


	$f4->Label(
		-text => $self->gui_jchar('  クラスター数：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_cluster_number} = $f4->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_cluster_number}->insert(0,'Auto');
	$self->{entry_cluster_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_cluster_number});

	# フォントサイズ
	my $ff = $lf->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 4,
	);

	$ff->Label(
		-text => $self->gui_jchar('・フォントサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_font_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_font_size}->insert(0,'80');
	$self->{entry_font_size}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_font_size});

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
	$self->{entry_plot_size}->insert(0,'Auto');
	$self->{entry_plot_size}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_plot_size});

	$win->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->calc;});}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se');


	return $self;
}

#--------------#
#   チェック   #
sub check{
	my $self = shift;
	
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}
	
	my $tani2 = '';
	if ($self->{radio} == 0){
		$tani2 = $self->gui_jg($self->{high});
	}
	elsif ($self->{radio} == 1){
		if ( length($self->{var_id}) ){
			$tani2 = mysql_outvar::a_var->new(undef,$self->{var_id})->{tani};
		}
	}
	
	my $check = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $tani2,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
	)->wnum;
	
	$self->{ent_check}->configure(-state => 'normal');
	$self->{ent_check}->delete(0,'end');
	$self->{ent_check}->insert(0,$check);
	$self->{ent_check}->configure(-state => 'disable');
}

#----------#
#   実行   #

sub calc{
	my $self = shift;
	
	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => '品詞が1つも選択されていません。',
		);
		return 0;
	}

	my $check_num = mysql_crossout::r_com->new(
		tani     => $self->tani,
		tani2    => $self->tani,
		hinshi   => $self->hinshi,
		max      => $self->max,
		min      => $self->min,
		max_df   => $self->max_df,
		min_df   => $self->min_df,
	)->wnum;
	
	$check_num =~ s/,//g;
	#print "$check_num\n";

	if ($check_num < 3){
		gui_errormsg->open(
			type => 'msg',
			msg  => '少なくとも3つ以上の抽出語を選択して下さい。',
		);
		return 0;
	}

	if ($check_num > 500){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					 '現在の設定では'.$check_num.'語が使用されます。'
					."\n"
					.'使用する語の数は200〜300程度におさえることを推奨します。'
					."\n"
					.'続行してよろしいですか？'
				),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder'
		);
		unless ($ans =~ /ok/i){ return 0; }
	}

	my $ans = $self->win_obj->messageBox(
		-message => $self->gui_jchar
			(
			   "この処理には時間がかかることがあります。\n".
			   "続行してよろしいですか？"
			),
		-icon    => 'question',
		-type    => 'OKCancel',
		-title   => 'KH Coder'
	);
	unless ($ans =~ /ok/i){ return 0; }

	#my $w = gui_wait->start;

	# データの取り出し
	my $r_command = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		rownames => 0,
	)->run;

	# クラスター分析を実行するためのコマンド
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	&make_plot(
		base_win       => $self,
		cluster_number => $self->gui_jg( $self->{entry_cluster_number}->get ),
		font_size      => $fontsize,
		plot_size      => $self->gui_jg( $self->{entry_plot_size}->get ),
		r_command      => $r_command,
		plotwin_name   => 'word_cls',
		data_number    => $check_num,
		method_dist    => $self->gui_jg( $self->{method_dist} ),
	);
}

sub make_plot{
	my %args = @_;

	my $fontsize = $args{font_size};
	my $r_command = $args{r_command};
	my $cluster_number = $args{cluster_number};

	if ($args{plot_size} =~ /auto/i){
		$args{plot_size} =
			int( ($args{data_number} * (28 * $fontsize) + 33) / 0.9344 );
		if ($args{plot_size} < 480){
			$args{plot_size} = 480;
		}
		elsif ($args{plot_size} < 640){
			$args{plot_size} = 640;
		}
	}

	if ($cluster_number =~ /auto/i){
		$cluster_number = int($args{data_number} / 10 + 0.5)
	}

	my $par = 
		"par(
			mai=c(0,0,0,0),
			mar=c(1,2,1,0),
			omi=c(0,0,0,0),
			oma=c(0,0,0,0) 
		)\n"
	;

	if ($args{method_dist} eq 'euclid'){
		$r_command .= "d <- t( scale( t(d) ) )\n";
		$r_command .= "dj <- dist(d,method=\"euclid\")^2\n";
	} else {
		$r_command .= "dj <- dist(d,method=\"binary\")\n";
	}

	my $r_command_2a = 
		"$par"
		.'hcl <- hclust(dj, method="average")'."\n"
		."plot(hcl,ann=0,cex=$fontsize, hang=-1)\n"
	;
	$r_command_2a .= 
		"rect.hclust(hcl, k=$cluster_number, border=\"#FF8B00FF\")\n"
		if $cluster_number > 1;
	
	my $r_command_2 = $r_command.$r_command_2a;

	my $r_command_3a = 
		"$par"
		.'hcl <- hclust(dj, method="complete")'."\n"
		."plot(hcl,ann=0,cex=$fontsize, hang=-1)\n"
	;
	$r_command_3a .= 
		"rect.hclust(hcl, k=$cluster_number, border=\"#FF8B00FF\")\n"
		if $cluster_number > 1;
	my $r_command_3 = $r_command.$r_command_3a;

	$r_command .=
		"$par"
		.'hcl <- hclust(dj, method="ward")'."\n"
		."plot(hcl,ann=0,cex=$fontsize, hang=-1)\n"
	;
	$r_command .= 
		"rect.hclust(hcl, k=$cluster_number, border=\"#FF8B00FF\")\n"
		if $cluster_number > 1;

	# プロット作成
	use kh_r_plot;
	my $plot1 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command,
		width     => $args{plot_size},
		height    => 480,
	) or return 0;
	$plot1->rotate_cls;

	my $plot2 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_2',
		command_a => $r_command_2a,
		command_f => $r_command_2,
		width     => $args{plot_size},
		height    => 480,
	) or return 0;
	$plot2->rotate_cls;

	my $plot3 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_3',
		command_a => $r_command_3a,
		command_f => $r_command_3,
		width     => $args{plot_size},
		height    => 480,
	) or return 0;
	$plot3->rotate_cls;

	# プロットWindowを開く
	my $plotwin_id = 'w_'.$args{plotwin_name}.'_plot';
	if ($::main_gui->if_opened($plotwin_id)){
		$::main_gui->get($plotwin_id)->close;
	}
	$args{base_win}->close;
	
	my $plotwin = 'gui_window::r_plot::'.$args{plotwin_name};
	$plotwin->open(
		plots       => [$plot1,$plot2,$plot3],
		no_geometry => 1,
		plot_size   => $args{plot_size},
	);

	return 1;
}

#--------------#
#   アクセサ   #


sub label{
	return '抽出語・クラスター分析：オプション';
}

sub win_name{
	return 'w_word_cls';
}

sub min{
	my $self = shift;
	return $self->gui_jg( $self->{ent_min}->get );
}
sub max{
	my $self = shift;
	return $self->gui_jg( $self->{ent_max}->get );
}
sub min_df{
	my $self = shift;
	return $self->gui_jg( $self->{ent_min_df}->get );
}
sub max_df{
	my $self = shift;
	return $self->gui_jg( $self->{ent_max_df}->get );
}
sub tani{
	my $self = shift;
	return $self->{tani_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{hinshi_obj}->selected;
}



1;