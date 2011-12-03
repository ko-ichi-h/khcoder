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
	)->pack(-fill => 'both', -expand => 1, -side => 'left');

	$lf_w->Label(
		-text => gui_window->gui_jchar('■集計単位と語の選択'),
		-font => "TKFN",
		-foreground => 'blue'
	)->pack(-anchor => 'w', -pady => 2);

	my $lf = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'both', -expand => 0);

	$lf->Label(
		-text => $self->gui_jchar('■クラスター分析の設定'),
		-font => "TKFN",
		-foreground => 'blue'
	)->pack(-anchor => 'w', -pady => 2);


	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		verb   => '分類',
	);

	#my $lf = $win->LabFrame(
	#	-label => 'Options',
	#	-labelside => 'acrosstop',
	#	-borderwidth => 2,
	#)->pack(-fill => 'both');

	# 距離
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

	# クラスター数
	my $f5 = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f5->Label(
		-text => $self->gui_jchar('クラスター数：'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_cluster_number} = $f5->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	$self->{entry_cluster_number}->insert(0,'Auto');
	$self->{entry_cluster_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_cluster_number});

	$f5->Label(
		-text => '  ',
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{check_color_cls} = 1;
	$f5->Checkbutton(
			-text     => $self->gui_jchar('クラスターの色分け','euc'),
			-variable => \$self->{check_color_cls},
			-anchor => 'w',
	)->pack(-anchor => 'w', -side => 'left');


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
		-command => sub{$self->close;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
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
		cluster_color  => $self->gui_jg( $self->{check_color_cls} ),
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

	my $old_simple_style = 0;
	if ( $args{cluster_color} == 0 ){
		$old_simple_style = 1;
	}

	my $bonus = 0;
	$bonus = 8 if $old_simple_style;

	if ($args{plot_size} =~ /auto/i){
		$args{plot_size} =
			int( ($args{data_number} * ( (20 + $bonus) * $fontsize) + 45) * 1 );
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

	$r_command .= "n_cls <- $cluster_number\n";
	$r_command .= "font_size <- $fontsize\n";
	
	$r_command .= "labels <- rownames(d)\n";
	$r_command .= "rownames(d) <- NULL\n";

	if ($args{method_dist} eq 'euclid'){
		# 抽出語ごとに標準化
			# euclid係数を使う主旨からすると、標準化は不要とも考えられるが、
			# 標準化を行わないと連鎖の程度が激しくなり、クラスター分析として
			# の用をなさなくなる場合がまま見られる。
		$r_command .= "d <- t( scale( t(d) ) )\n";
	}
	$r_command .= "library(amap)\n";
	$r_command .= "dj <- Dist(d,method=\"$args{method_dist}\")\n";
	if ($args{method_dist} eq 'euclid'){
		$r_command .= "dj <- dj^2\n";
	}
	
	$r_command .= "try( library(flashClust) )\n";

	my $r_command_2a = 
		"$par"
		.'hcl <- hclust(dj, method="average")'."\n"
		.&r_command_plot($old_simple_style)
	;

	#$r_command_2a .= 
	#	"rect.hclust(hcl, k=$cluster_number, border=\"#FF8B00FF\")\n"
	#	if $cluster_number > 1;
	
	my $r_command_2 = $r_command.$r_command_2a;

	my $r_command_3a = 
		"$par"
		.'hcl <- hclust(dj, method="complete")'."\n"
		.&r_command_plot($old_simple_style)
	;
	#$r_command_3a .= 
	#	"rect.hclust(hcl, k=$cluster_number, border=\"#FF8B00FF\")\n"
	#	if $cluster_number > 1;
	my $r_command_3 = $r_command.$r_command_3a;

	$r_command .=
		"$par"
		.'hcl <- hclust(dj, method="ward")'."\n"
		.&r_command_plot($old_simple_style)
	;
	#$r_command .= 
	#	"rect.hclust(hcl, k=$cluster_number, border=\"#FF8B00FF\")\n"
	#	if $cluster_number > 1;


	# プロット作成
	my $flg_error = 0;
	my $merges;
	
	my ($w,$h) = (480,$args{plot_size});
	($w,$h) = ($h,$w) if $old_simple_style;
	
	# Ward法
	my $plot1 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command,
		width     => $w,
		height    => $h,
	) or $flg_error = 1;
	$plot1->rotate_cls if $old_simple_style;

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
		width     => $w,
		height    => $h,
	) or $flg_error = 1;
	$plot2->rotate_cls if $old_simple_style;

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
		width     => $w,
		height    => $h,
	) or $flg_error = 1;
	$plot3->rotate_cls if $old_simple_style;

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

sub r_command_plot{
	my $simple = shift;
	my $t;
	if ($simple){
		$t = &r_command_plot_simple;
	} else {
		$t = &r_command_plot_ggplot2;
	}
	return $t;
}


sub r_command_plot_simple{
	my $t = << 'END_OF_the_R_COMMAND';

hcl$labels <- labels
plot(hcl,ann=0,cex=font_size, hang=-1)
if (n_cls > 1){
	rect.hclust(hcl, k=n_cls, border="#FF8B00FF")
}

END_OF_the_R_COMMAND
return $t;
}

sub r_command_plot_ggplot2{
	my $t = << 'END_OF_the_R_COMMAND';

#plot(hcl,ann=0,cex=1, hang=-1)

library(ggplot2)
library(ggdendro)

ddata <- dendro_data(as.dendrogram(hcl), type="rectangle")

p <- NULL
p <- ggplot()

# クラスターごとのカラー設定

if (n_cls > 1){
	memb <- cutree(hcl,k=n_cls)
	# 全体の色設定
	p <- p + scale_colour_hue(l=40, c=100)
	# 切り離し線
	cutpoint <- mean(
		c(
			rev(hcl$height)[n_cls-1],
			rev(hcl$height)[n_cls]
		)
	)
	p <- p + geom_hline(
		yintercept = cutpoint,
		colour="black",
		linetype=5,
		size=0.5
	)
	# 色の順番を決定
	n <- length( unique(memb[hcl$order]) )
	new_col <- NULL
	for (i in 1:ceiling(n / 2) ){
		new_col <- c(new_col, i)
		if (i + ceiling(n / 2) <= n){
			new_col <- c(new_col, i + ceiling(n / 2))
		}
	}
	# クラスター番号→色名の変換用ベクトル作成（col_vec）
	col_tab <- cbind(
		unique(memb[hcl$order]),
		new_col
	)
	colnames(col_tab) <- c("org","new")
	col_vec <- NULL
	for (i in col_tab[order(col_tab[,1]),2]){
		c <- as.character(i)
		while (nchar(c) < 3){
			c <- paste('0',c,sep='')
		}
		col_vec <- c(col_vec, c)
	}
	# 線の色分け
	seg_bl <- NULL
	seg_cl <- NULL
	for ( i in 1:nrow( segment(ddata) ) ) {
		if (
			   segment(ddata)$y0[i] > cutpoint
			|| segment(ddata)$y1[i] > cutpoint
		) {
			seg_bl <- rbind(
				seg_bl,
				c(
					segment(ddata)$x0[i],
					segment(ddata)$y0[i],
					segment(ddata)$x1[i],
					segment(ddata)$y1[i]
				)
			)
		} else {
			seg_cl <- rbind(
				seg_cl,
				c(
					segment(ddata)$x0[i],
					segment(ddata)$y0[i],
					segment(ddata)$x1[i],
					segment(ddata)$y1[i],
					#col_vec[
						memb[hcl$order][
							floor(
								mean(
									segment(ddata)$x0[i],
									segment(ddata)$x1[i]) 
								)
						]
					#]
				)
			)
		}
	}
	colnames(seg_bl) <- c("x0", "y0", "x1", "y1")
	colnames(seg_cl) <- c("x0", "y0", "x1", "y1", "c")
	seg_bl <- as.data.frame(seg_bl)
	seg_cl <- as.data.frame(seg_cl)
	seg_cl$c <- col_vec[seg_cl$c]
	p <- p + geom_segment(
		data=seg_cl,
		aes_string(x="x0", y="y0", xend="x1", yend="y1", colour="c"),
		size=0.5
	)
} else {
	memb <- rep( c("a"), length(labels) )
	p <- p + scale_colour_manual(values=c("black"))
	seg_bl <- segment(ddata)
}

p <- p + geom_segment(
	data=seg_bl,
	aes_string(x="x0", y="y0", xend="x1", yend="y1"),
	color="gray50",
	linetype=1,
)


p <- p + geom_text(
	data=data.frame(                    # ラベル変換
		x=label(ddata)$x,
		y=label(ddata)$y,
		text=labels[ as.numeric( as.vector( label(ddata)$text ) ) ],
		cols= col_vec[ memb[ as.numeric( as.vector( label(ddata)$text ) ) ] ]
	),
	aes_string(
		x="x",
		y="y",
		label="text",
		colour="cols"
	),
	hjust=1,
	angle =0,
	size = 5 * 0.85 * font_size
)

p <- p + coord_flip()
p <- p + scale_x_reverse( expand = c(0.01,0.01) )
p <- p + scale_y_continuous(expand = c(0.2,0))

p <- p + ggplot2::opts(
	axis.title.y = theme_blank(),
	axis.title.x = theme_blank(),
	axis.ticks   = theme_segment(colour="gray60"),
	axis.text.y  = theme_text(size=12,family="sans",colour="gray40"),
	axis.text.x  = theme_text(size=12,family="sans",colour="gray40"),
	legend.position="none"
)

if (n_cls <= 1){
	p <- p + ggplot2::opts(
		axis.text.y  = theme_blank(),
		axis.text.x  = theme_text(size=12,family="sans",colour="black"),
		axis.ticks = theme_segment(colour="black"),
		#panel.grid.major = theme_blank(),
		#panel.grid.minor = theme_blank(),
		#panel.background = theme_blank(),
		axis.line = theme_segment(colour = 'black')
	)
}

# Save the original definition of guide_grid
guide_grid_orig <- guide_grid

# Create the replacement function
guide_grid_no_hline <- function(theme, x.minor, x.major, y.minor, y.major) {
  ggname("grill", grobTree(
    theme_render(theme, "panel.background"),
    theme_render(
      theme, "panel.grid.minor", name = "x",
      x = rep(x.minor, each=2), y = rep(0:1, length(x.minor)),
      id.lengths = rep(2, length(x.minor))
    ),
    theme_render(
      theme, "panel.grid.major", name = "x",
      x = rep(x.major, each=2), y = rep(0:1, length(x.major)),
      id.lengths = rep(2, length(x.major))
    )
  ))
}

# Assign the function inside ggplot2
assignInNamespace("guide_grid", guide_grid_no_hline, pos="package:ggplot2")

print(p)
if (n_cls > 1) {
	if ( par("family") == "sans" ){
		grid.gedit("GRID.text", grep=TRUE, global=TRUE, gp=gpar(fontfamily="sans",fontface="bold"))
	} else {
		if ( grepl("darwin", R.version$platform) ){
			quartzFonts(HiraKaku=quartzFont(rep("Hiragino Kaku Gothic Pro W6",4)))
			grid.gedit("GRID.text", grep=TRUE, global=TRUE, gp=gpar(fontfamily="HiraKaku"))
		} else {
			grid.gedit("GRID.text", grep=TRUE, global=TRUE, gp=gpar(fontface="bold"))
		}
	}
} else {
	grid.remove(gPath("axis_v"), grep=TRUE)
}
assignInNamespace("guide_grid", guide_grid_orig, pos="package:ggplot2")

END_OF_the_R_COMMAND
return $t;
}

1;