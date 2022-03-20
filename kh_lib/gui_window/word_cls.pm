package gui_window::word_cls;
use base qw(gui_window);
use utf8;

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
		-label       => kh_msg->get('u_w'), # 集計単位と抽出語の選択
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-fill => 'both', -expand => 1, -side => 'left');

	my $lf = $win->LabFrame(
		-label       => kh_msg->get('opt'), # クラスター分析のオプション
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-fill => 'both', -expand => 0);

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		verb   => kh_msg->get('cluster'), # 分類
		sampling     => 1,
		command      => sub{
			$self->calc;
		},
	);

	# クラスター分析のオプション
	$self->{cls_obj} = gui_widget::r_cls->open(
		parent       => $lf,
		command      => sub{ $self->calc; },
		pack    => { -anchor   => 'w'},
	);

	# フォントサイズ
	$self->{font_obj} = gui_widget::r_font->open(
		parent    => $lf,
		command   => sub{ $self->calc; },
		pack      => { -anchor   => 'w' },
		show_bold => 0,
		plot_size => 'Auto',
	);

	#SCREEN Plugin
	use screen_code::cluster;
	&screen_code::cluster::add_menu($self,$lf,0);
	#SCREEN Plugin

	$win->Checkbutton(
			-text     => kh_msg->gget('r_dont_close'),
			-variable => \$self->{check_rm_open},
			-anchor => 'w',
	)->pack(-anchor => 'w');

	$win->Button(
		-text => kh_msg->gget('cancel'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se')->focus;

	return $self;
}

sub start_raise{
	my $self = shift;
	$self->{words_obj}->settings_load;
}

sub start{
	my $self = shift;

	# Windowを閉じる際のバインド
	$self->win_obj->bind(
		'<Control-Key-q>',
		sub{ $self->withd; }
	);
	$self->win_obj->bind(
		'<Key-Escape>',
		sub{ $self->withd; }
	);
	$self->win_obj->protocol('WM_DELETE_WINDOW', sub{ $self->withd; });
}

#----------#
#   実行   #

sub calc{
	my $self = shift;
	
	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::word_corresp->select_pos'), # '品詞が1つも選択されていません。',
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
			msg  => kh_msg->gget('select_3words'), #'少なくとも3つ以上の抽出語を選択して下さい。',
		);
		return 0;
	}

	if ($check_num > 500){
		my $ans = $self->win_obj->messageBox(
			-message => $self->gui_jchar
				(
					kh_msg->get('gui_window::word_corresp->too_many1')
					.$check_num
					.kh_msg->get('gui_window::word_corresp->too_many2')
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many3')
					."\n"
					.kh_msg->get('gui_window::word_corresp->too_many4')
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
		sampling => $self->{words_obj}->sampling_value,
	)->run;

	# クラスター分析を実行するためのコマンド
	$r_command .= "d <- t(d)\n";
	$r_command .= "# END: DATA\n";

	my $plot = &make_plot(
		$self->{cls_obj}->params,
		font_size      => $self->{font_obj}->font_size,
		font_bold      => $self->{font_obj}->check_bold_text,
		plot_size      => $self->{font_obj}->plot_size,
		r_command      => $r_command,
		plotwin_name   => 'word_cls',
		data_number    => $check_num,
	);

	$w->end(no_dialog => 1);
	return 0 unless $plot;

	unless ( $self->{check_rm_open} ){
		$self->withd;
	}

}

sub make_plot{
	my %args = @_;

	kh_r_plot->clear_env;

	my $fontsize = $args{font_size};
	#my $fontsize = 1;
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
		$args{plot_size} = int( $args{plot_size} * ( $::config_obj->plot_size_codes / 480 ) );
		
		if ($args{plot_size} < $::config_obj->plot_size_codes){
			$args{plot_size} = $::config_obj->plot_size_codes;
		}
		elsif ($args{plot_size} < $::config_obj->plot_size_words){
			$args{plot_size} = $::config_obj->plot_size_words;
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

	$r_command .= "freq <- NULL\n";
	$r_command .= "for (i in 1:nrow(d)) {\n";
	$r_command .= "	freq[i] = sum( d[i,] )\n";
	$r_command .= "}\n";

	$r_command .= "

if (exists(\"doc_length_mtr\")){
	leng <- as.numeric(doc_length_mtr[,2])
	leng[leng ==0] <- 1
	d <- t(d)
	d <- d / leng
	d <- d * 1000
	d <- t(d)
}

" unless $args{method_dist} eq 'binary';

	if ($args{method_dist} eq 'euclid'){
		$r_command .= "d <- t( scale( t(d) ) )\n";
	}
	# euclidの場合は抽出語ごとに標準化
		# euclid係数を使う主旨からすると、標準化は不要とも考えられるが、
		# 標準化を行わないと連鎖の程度が激しくなり、クラスター分析として
		# の用をなさなくなる場合がまま見られる。

	$r_command .= "method_dist <- \"$args{method_dist}\"\n";
	$r_command .= "method_clst <- \"$args{method_mthd}\"\n";

	$r_command .= '
if (
	   ( method_dist == "Dice" )
	|| ( method_dist == "Simpson" )
){
	library(proxy)
	dj <- proxy::dist(d,method=method_dist)
	detach("package:proxy")
} else {
	library(amap)
	dj <- Dist(d,method=method_dist)
}

if (
	   ( as.numeric( R.Version()$major ) >= 3 )
	&& ( as.numeric( R.Version()$minor ) >= 1.0)
){                                                      # >= R 3.1.0
	if (method_clst == "ward"){
		method_clst  <-  "ward.D2"
	}
	hcl <- hclust(dj,method=method_clst)
} else {                                                # <= R 3.0
	if (method_clst == "ward"){
		dj <- dj^2
		hcl <- hclust(dj,method=method_clst)
		hcl$height <- sqrt( hcl$height )
	} else {
		hcl <- hclust(dj,method=method_clst)
	}
}'
	;

	$r_command .= "\n$par";
	$r_command .= &r_command_plot($old_simple_style);

	# make plots
	my $merges;
	
	my ($w,$h) = ($::config_obj->plot_size_codes, $args{plot_size});
	($w,$h) = ($h,$w) if $old_simple_style;
	
	# dendrogram
	my $plot1 = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f => $r_command,
		width     => $w,
		height    => $h,
		font_size => $args{font_size},
	) or return 0;
	$plot1->rotate_cls if $old_simple_style;

	# write coordinates to a file
	my $csv;
	unless ($old_simple_style) {
		$csv = $::project_obj->file_TempCSV;
		$::config_obj->R->send("
			write.table(coord, file=\"".$::config_obj->uni_path($csv)."\", fileEncoding=\"UTF-8\", sep=\"\\t\", quote=F, col.names=F)\n
		");
	}

	# heights
	foreach my $i ('last','first','all'){
		$merges->{0}{$i} = kh_r_plot->new(
			name      => $args{plotwin_name}.'_1_'.$i,
			command_f =>  $r_command
			             ."pp_type <- \"$i\"\n"
			             .&r_command_height,
			command_a =>  "pp_type <- \"$i\"\n"
			             .&r_command_height,
			width     => $::config_obj->plot_size_words,
			height    => $::config_obj->plot_size_codes,
			font_size => $args{font_size},
		) or return 0;
	}

	# プロットWindowを開く
	kh_r_plot->clear_env;
	my $plotwin_id = 'w_'.$args{plotwin_name}.'_plot';
	if ($::main_gui->if_opened($plotwin_id)){
		$::main_gui->get($plotwin_id)->close;
	}
	
	my $plotwin = 'gui_window::r_plot::'.$args{plotwin_name};
	$plotwin->open(
		plots       => [$plot1],
		#no_geometry => 1,
		plot_size   => $args{plot_size},
		merges      => $merges,
		coord       => $csv,
	);

	return 1;
}

#--------------#
#   アクセサ   #


sub label{
	return kh_msg->get('win_title'); # 抽出語・クラスター分析：オプション
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
	my $t = '

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
	
	str_xlab <- paste(" ('
	.kh_msg->pget('last1') # 最後の
	.'",pp_focus,"'
	.kh_msg->pget('last2') # 回
	.')",sep="")
} else if (pp_type == "first") {
	if ( pp_focus > nrow(det) ){
		pp_focus <- nrow(det)
	}
	det <- det[pp_focus:1,]
	
	str_xlab <- paste(" ('
	.kh_msg->pget('first1') # 最初の
	.'",pp_focus,"'
	.kh_msg->pget('first2') # 回
	.')",sep="")
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
	bty = "l",
	xlab = paste("'
	.kh_msg->pget('agglomer') # クラスター併合の段階
	.'",str_xlab,sep = ""),
	ylab = "'
	.kh_msg->pget('hight') # 併合水準（非類似度）
	.'"
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
	legend = c("'
	.kh_msg->pget('note1') # ※プロット内の数値ラベルは\n　併合後のクラスター総数
	.'"),
	#pch = c(16),
	cex = .9,
	box.lty = 0
)

';
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
	my $t = '

library(grid)
library(ggplot2)
library(ggdendro)

ddata <- dendro_data(as.dendrogram(hcl), type="rectangle")

p <- NULL
p <- ggplot()

font_family <- "'.$::config_obj->font_plot_current.'"
if ( exists("PERL_font_family") ){
	font_family <- PERL_font_family
}

# クラスターごとのカラー設定

if (n_cls > 1){
	memb <- cutree(hcl,k=n_cls)
	# 全体の色設定
	p <- p + scale_colour_hue(l=40, c=100)
	# 切り離し線(1)
	cutpoint <- mean(
		c(
			rev(hcl$height)[n_cls-1],
			rev(hcl$height)[n_cls]
		)
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
			c <- paste("0",c,sep="")
		}
		col_vec <- c(col_vec, c)
	}
	# 線の色分け
	seg_bl <- NULL
	seg_cl <- NULL
	colnames(ddata$segment) <- c(
		"x0",
		"y0",
		"x1",
		"y1"
	)
	colnames(ddata$labels) <- c(
		"x",
		"y",
		"text"
	)
	for ( i in 1:nrow( ddata$segment ) ) {
		if (
			   ddata$segment$y0[i] > cutpoint
			|| ddata$segment$y1[i] > cutpoint
			|| (
				   ddata$segment$y0[i] >= cutpoint
				&& ddata$segment$y1[i] >= cutpoint
			   )
		) {
			seg_bl <- c(
				seg_bl,
				ddata$segment$x0[i],
				ddata$segment$y0[i],
				ddata$segment$x1[i],
				ddata$segment$y1[i]
			)
		} else {
			seg_cl <- c(
				seg_cl,
				ddata$segment$x0[i],
				ddata$segment$y0[i],
				ddata$segment$x1[i],
				ddata$segment$y1[i],
				#col_vec[
					memb[hcl$order][
						floor(
							mean(
								ddata$segment$x0[i],
								ddata$segment$x1[i]) 
							)
					]
				#]
			)
		}
	}
	seg_bl = matrix(seg_bl, byrow=T, ncol=4 )
	seg_cl = matrix(seg_cl, byrow=T, ncol=5 )
	
	if (is.null(seg_bl) == F){
		colnames(seg_bl) <- c("x0", "y0", "x1", "y1")
		seg_bl <- as.data.frame(seg_bl)
		# 切り離し線(2)
		if ( max(seg_bl$y1) > cutpoint ){
			p <- p + geom_hline(
				yintercept = cutpoint,
				colour="black",
				linetype=5,
				size=0.5
			)
		}
	}
	colnames(seg_cl) <- c("x0", "y0", "x1", "y1", "c")
	seg_cl <- as.data.frame(seg_cl)
	seg_cl$c <- col_vec[seg_cl$c]

	p <- p + geom_text(
		data=data.frame(                    # ラベル
			x=label(ddata)$x,
			y=label(ddata)$y,
			text=labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
			cols= col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ]
		),
		aes_string(
			x="x",
			y="y",
			label="text",
			colour="cols"
		),
		hjust=1,
		angle =0,
		family = font_family,
		fontface = "bold",
		size = 5 * 0.85 * font_size
	)

	p <- p + geom_segment(
		data=seg_cl,
		aes_string(x="x0", y="y0", xend="x1", yend="y1", colour="c"),
		size=0.5
	)
} else {
	memb <- rep( c("a"), length(labels) )
	p <- p + scale_colour_manual(values=c("black"))
	seg_bl <- ddata$segment
	col_vec <- c("001")
	p <- p + geom_text(
		data=data.frame(                    # ラベル
			x=label(ddata)$x,
			y=label(ddata)$y,
			text=labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
			cols= col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ]
		),
		aes_string(
			x="x",
			y="y",
			label="text",
			colour="cols"
		),
		hjust=1,
		angle =0,
		family = font_family,
		fontface = "bold",
		size = 5 * 0.85 * font_size
	)
}

if (is.null(seg_bl) == F){
	p <- p + geom_segment(
		data=seg_bl,
		aes_string(x="x0", y="y0", xend="x1", yend="y1"),
		color="gray50",
		linetype=1,
	)
}

p <- p + geom_text(
	data=data.frame(                    # ラベル変換
		x=label(ddata)$x,
		y=label(ddata)$y,
		text=labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
		cols= col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ]
	),
	aes_string(
		x="x",
		y="y",
		label="text",
		colour="cols"
	),
	hjust=1,
	angle =0,
	family = font_family,
	fontface = "bold",
	size = 5 * 0.85 * font_size
)

# 語やコードの長さにあわせて余白の大きさを設定
y_max <- max( ddata$segment$y1 )
y_min <- 0.2
# "strwidth" crashes if the device is cairo_pdf or cairo_ps 
if (
	is.na(dev.list()["cairo_pdf"])
	&& is.na(dev.list()["cairo_ps"])
){
	y_min <- max(
		strwidth(
			labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
			units = "figure",
			font = 2
		)
	)
}
y_min <- y_min * font_size
y_min <- ( 6 * y_max * y_min ) / ( 5 - 6 * y_min )
y_min <- y_min * 1.1
if (y_min > y_max * 2){
	y_min <- y_max * 2
}
y_min <- y_min * -1

# 目盛の位置を設定
b1 <- 0
for (i in 1:1000){
	b1 <- signif(y_max * 0.875, i)
	if (b1 < y_max){
		break
	}
}

p <- p + coord_flip()
p <- p + scale_x_reverse(
	expand = c(0,0),
	breaks = NULL,
	limits=c( length(ddata$labels$text) + 0.5 , 1 - 0.5 )
)
p <- p + scale_y_continuous(
	limits=c(y_min,y_max),
	breaks=c(0,b1/2,b1),
	expand = c(0.02,0.02)
)

p <- p + theme(
	axis.title.y = element_blank(),
	axis.title.x = element_blank(),
	axis.ticks   = element_line(colour="gray60"),
	axis.text.y  = element_text(size=12,colour="gray40"),
	axis.text.x  = element_text(size=12,colour="gray40"),
	legend.position="none"
)

if (n_cls <= 1){
	p <- p + theme(
		axis.text.y  = element_blank(),
		axis.text.x  = element_text(size=12,colour="black"),
		axis.ticks = element_line(colour="black"),
		#panel.grid.major = theme_blank(),
		#panel.grid.minor = theme_blank(),
		#panel.background = theme_blank(),
		axis.line = element_line(colour = "black")
	)
}

show_bar <- 1

if (show_bar == 1){
	p <- p + theme(
		axis.ticks  = element_blank(),
		axis.text.y = element_blank()
	)
	p <- p + theme(
		plot.margin = unit(c(0,0,0,0), "lines")
	)

	bard <- data.frame(
		nm <- labels[ as.numeric( as.vector( ddata$labels$text ) ) ],
		ht <- freq[ as.numeric( as.vector( ddata$labels$text ) ) ],
		cl <- col_vec[ memb[ as.numeric( as.vector( ddata$labels$text ) ) ] ],
		od <- nrow(d):1
	)

	if (n_cls <= 1){
		bard$cl <- "001"
	}

	p2 <- NULL
	p2 <- ggplot()
	p2 <- p2 + geom_bar(
		stat="identity",
		position = "identity",
		width=0.75,
		data=bard,
		aes(
			x=reorder(od,od),
			y=ht,
			fill=cl
		)
	)
	p2 <- p2 + coord_flip()
	p2 <- p2 + scale_y_reverse( expand = c(0,0))
	p2 <- p2 + scale_x_discrete( expand = c(0,0) )
	p2 <- p2 + theme(
		axis.title.y     = element_blank(),
		axis.title.x     = element_blank(),
		axis.ticks       = element_blank(),
		axis.text.y      = element_blank(),
		axis.text.x      = element_text(size=12,colour="white"),
		legend.position  = "none",
		panel.background = element_rect(fill="white", colour="white"),
		panel.grid.major = element_blank(),
		panel.grid.minor = element_blank()
	)

	margin <- 0.002 * nrow(d) + 0.00001 * nrow(d)^2 - 0.12
	p2 <- p2 + theme(
		plot.margin = unit(c(0.25,0,0.25,0), "lines") # r: -0.75
	)

	grid.newpage()
	pushViewport(viewport(layout=grid.layout(1,2, width=c(1,5)) ) )
	print(p,  vp= viewport(layout.pos.row=1, layout.pos.col=2) )
	print(p2, vp= viewport(layout.pos.row=1, layout.pos.col=1) )
} else {
	print(p)
}

if (
	is.na(dev.list()["pdf"])
	&& is.na(dev.list()["postscript"])
	&& is.na(dev.list()["cairo_pdf"])
	&& is.na(dev.list()["cairo_ps"])
){
	if ( grepl("darwin", R.version$platform) ){
		quartzFonts(HiraKaku=quartzFont(rep("'.$::config_obj->font_plot_current.'",4)))
		grid.force()
		grid.gedit("GRID.text", grep=TRUE, global=TRUE, gp=gpar(fontfamily="HiraKaku"))
	}
}

detach("package:ggdendro", unload=T)

# for clickable image map
exp <- (y_max - y_min ) * 0.02
coord <- cbind(
	(1 / 6 + 5 / 6 * -1 * (y_min - exp) / ( (y_max + exp) - (y_min - exp) )) * 1.03,
	1:length(ddata$labels$text) / length(ddata$labels$text)
)
rownames(coord) <-
	labels[ as.numeric( as.vector( ddata$labels$text ) ) ]

';


return $t;
}

1;