package gui_window::word_cls;
use base qw(gui_window);

use strict;
use Tk;

use gui_widget::words;
use mysql_crossout;
use kh_r_plot;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));

	my $lf_w = $win->LabFrame(
		-label => 'Words',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 1);

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		verb   => '分類',
	);

	my $lf = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both');

	# クラスター数
	my $f4 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f4->Label(
		-text => $self->gui_jchar('距離：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget_dist = gui_widget::optmenu->open(
		parent  => $f4,
		pack    => {-side => 'left'},
		options =>
			[
				['Jaccard', 'binary' ],
				['Euclid',  'euclid' ],
				['Cosine',  'pearson'],
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
		-text => $self->gui_jchar('フォントサイズ：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_font_size} = $ff->Entry(
		-font       => "TKFN",
		-width      => 3,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_font_size}->insert(0,$::config_obj->r_default_font_size);
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

	$win->Checkbutton(
			-text     => $self->gui_jchar('実行時にこの画面を閉じない','euc'),
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

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

	$self->{words_obj}->settings_save;

	my $w = gui_wait->start;

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
		#base_win       => $self,
		cluster_number => $self->gui_jg( $self->{entry_cluster_number}->get ),
		font_size      => $fontsize,
		plot_size      => $self->gui_jg( $self->{entry_plot_size}->get ),
		r_command      => $r_command,
		plotwin_name   => 'word_cls',
		data_number    => $check_num,
		method_dist    => $self->gui_jg( $self->{method_dist} ),
	);

	$w->end(no_dialog => 1);

	unless ( $self->{check_rm_open} ){
		$self->close;
	}

}

sub make_plot{
	my %args = @_;

	kh_r_plot->clear_env;

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
		$cluster_number = int( sqrt( $args{data_number} ) + 0.5)
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
	}
	$r_command .= "library(amap)\n";
	$r_command .= "dj <- Dist(d,method=\"$args{method_dist}\")\n";
	$r_command .= "try( library(flashClust) )\n";

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
	my $flg_error = 0;
	my $merges;
	
	# Ward法
	my $plot1 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command,
		width     => $args{plot_size},
		height    => 480,
	) or $flg_error = 1;
	$plot1->rotate_cls;

	foreach my $i ('last','first','all'){
		$merges->{0}{$i} = kh_r_plot->new(
			name      => $args{plotwin_name}.'_1_'.$i,
			command_f =>  $r_command
			             ."pp_type <- \"$i\"\n"
			             .&r_command_height,
			command_a =>  "pp_type <- \"$i\"\n"
			             .&r_command_height,
			width     => 640,
			height    => 480,
		);
	}

	# 群平均法
	my $plot2 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_2',
		command_a => $r_command_2a,
		command_f => $r_command_2,
		width     => $args{plot_size},
		height    => 480,
	) or $flg_error = 1;
	$plot2->rotate_cls;

	foreach my $i ('last','first','all'){
		$merges->{1}{$i} = kh_r_plot->new(
			name      => $args{plotwin_name}.'_2_'.$i,
			command_f =>  $r_command_2
			             ."pp_type <- \"$i\"\n"
			             .&r_command_height,
			command_a =>  "pp_type <- \"$i\"\n"
			             .&r_command_height,
			width     => 640,
			height    => 480,
		);
	}

	# 最遠隣法
	my $plot3 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_3',
		command_a => $r_command_3,
		command_f => $r_command_3,
		width     => $args{plot_size},
		height    => 480,
	) or $flg_error = 1;
	$plot3->rotate_cls;

	foreach my $i ('last','first','all'){
		$merges->{2}{$i} = kh_r_plot->new(
			name      => $args{plotwin_name}.'_3_'.$i,
			command_f =>  $r_command_3
			             ."pp_type <- \"$i\"\n"
			             .&r_command_height,
			command_a =>  "pp_type <- \"$i\"\n"
			             .&r_command_height,
			width     => 640,
			height    => 480,
		);
	}

	# プロットWindowを開く
	kh_r_plot->clear_env;
	my $plotwin_id = 'w_'.$args{plotwin_name}.'_plot';
	if ($::main_gui->if_opened($plotwin_id)){
		$::main_gui->get($plotwin_id)->close;
	}
	
	return 0 if $flg_error;
	
	my $plotwin = 'gui_window::r_plot::'.$args{plotwin_name};
	$plotwin->open(
		plots       => [$plot1,$plot2,$plot3],
		no_geometry => 1,
		plot_size   => $args{plot_size},
		merges      => $merges,
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
sub r_command_height{
	my $t = << 'END_OF_the_R_COMMAND';

# プロットの準備開始
pp_focus  <- 50     # 最初・最後の50回の併合をプロット
pp_kizami <-  5     # クラスター数のきざみ（5個おきに表示）

# 併合水準を取得
det <- hcl$merge
det <- cbind(1:nrow(det), nrow(det):1, det, hcl$height)
colnames(det) <- c("u_n", "cls_n", "u1", "u2", "height")

# タイプ別の処理：必要な部分の併合データ切出し・表記・クラスター数表示のきざみ
if (pp_type == "last"){
	n_start <- nrow(det) - pp_focus + 1
	if (n_start < 1){ n_start <- 1 }
	det <- det[nrow(det):n_start,]
	
	str_xlab <- paste("（最後の",pp_focus,"回）",sep="")
} else if (pp_type == "first") {
	if ( pp_focus > nrow(det) ){
		pp_focus <- nrow(det)
	}
	det <- det[pp_focus:1,]
	
	str_xlab <- paste("（最初の",pp_focus,"回）",sep="")
} else if (pp_type == "all") {
	det <- det[nrow(det):1,]
	pp_kizami <- nrow(det) / 8
	pp_kizami <- pp_kizami - ( pp_kizami %% 5 ) + 5
	
	str_xlab <- ""
}

# クラスター数のマーカーを入れる準備
p_type <- NULL
p_nums <- NULL
for (i in 1:nrow(det)){
	if ( (det[i,"cls_n"] %%  pp_kizami == 0) | (det[i,"cls_n"] == 1)){
		p_type <- c(p_type, 16)
		p_nums <- c(p_nums, det[i,"cls_n"])
	} else {
		p_type <- c(p_type, 1)
		p_nums <- c(p_nums, "")
	}
}

# プロット
par(mai=c(0,0,0,0), mar=c(4,4,1,1), omi=c(0,0,0,0), oma =c(0,0,0,0) )
plot(
	det[,"u_n"],
	det[,"height"],
	type = "b",
	pch  = p_type,
	xlab = paste("クラスター併合の段階",str_xlab,sep = ""),
	ylab = "併合水準（非類似度）"
)

text(
	x      = det[,"u_n"],
	y      = det[,"height"]
	         - ( max(det[,"height"]) - min(det[,"height"]) ) / 40,
	labels = p_nums,
	pos    = 4,
	offset = .2,
	cex    = .8
)

legend(
	min(det[,"u_n"]),
	max(det[,"height"]),
	legend = c("※プロット内の数値ラベルは\n　併合後のクラスター総数"),
	#pch = c(16),
	cex = .8,
	box.lty = 0
)

END_OF_the_R_COMMAND
return $t;
}

1;