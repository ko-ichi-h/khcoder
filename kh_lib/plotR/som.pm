package plotR::som;

use strict;

use kh_r_plot;

sub new{
	my $class = shift;
	my %args = @_;

	my $self = \%args;
	bless $self, $class;

	kh_r_plot->clear_env;

	my $r_command = $args{r_command};
	$args{font_bold} += 1;

	# パラメーター設定（SOM）
	my $param0 = "\n";
	$param0 .= "n_nodes <- $args{n_nodes}\n";
	$param0 .= "rlen1 <- $args{rlen1}\n";
	$param0 .= "rlen2 <- $args{rlen2}\n";

	# パラメーター設定（描画）
	my $param1 = "\n";
	$param1 .= "cex <- $args{font_size}\n";
	$param1 .= "text_font <- $args{font_bold}\n";
	$param1 .= "if_cls <- $args{if_cls}\n";
	$param1 .= "n_cls <- $args{n_cls}\n";
	if ($args{p_topo} eq 'hx'){
		$param1 .= "if_plothex <- 1\n";
	} else {
		$param1 .= "if_plothex <- 0\n";
	}
	$param1 .= "\n";
	$param1 .= "# n_nodes <- $args{n_nodes}\n";
	$param1 .= "# rlen1 <- $args{rlen1}\n";
	$param1 .= "# rlen2 <- $args{rlen2}\n";

	# 自己組織化マップを保存するファイル名
	my $file_save = $::project_obj->file_datadir;
	$file_save .= '_'.$args{plotwin_name};
	my $icode = Jcode::getcode($file_save);
	$file_save = Jcode->new($file_save, $icode)->euc;
	$file_save =~ tr/\\/\//;
	$file_save = Jcode->new($file_save,'euc')->$icode unless $icode eq 'ascii';
	#print "icode: $icode\nfile: $file_save\n";

	# 自己組織化マップの実行
	unless ($args{reuse}){
		if ( -e $file_save ){
			unlink $file_save;
		}
		my $r_data = $r_command;
		$r_data = Jcode->new($r_data)->sjis if $::config_obj->os eq 'win32';
		
		my $p0_r = $self->r_cmd_p0_hx;
		$::config_obj->R->send(
			 $r_data
			.$param0
			.$p0_r
		);
		print $::config_obj->R->read();

		# 自己組織化マップの保存
		$::config_obj->R->send(
			"save(word_labs,n_nodes,somm, file=\"$file_save\" )\n"
		);
		print $::config_obj->R->read();
		
		my $file_save_s = $file_save.'_s';
		open (my $fh, '>', $file_save_s)
			or gui_errormsg->open(
				type    => 'file',
				thefile => $file_save_s,
			)
		;
		print $fh 
			 $r_data
			.$param0
			.$p0_r
		;
		close $fh;
	}

	# コマンドの準備
	my $p0_a = Jcode->new( "load(\"$file_save\")\n" )->euc;
	$p0_a   .= "# END: DATA\n";
	$p0_a   .= "$param1\n\n";

	my $p1 = $self->r_cmd_p1_hx;
	my $p2 = $self->r_cmd_p2_hx;

	# プロット作成
	my @plots = ();
	my $flg_error = 0;

	my $com_a = '';

	if ( $args{if_cls} == 1 ){
		push @plots, kh_r_plot->new(
			name      => $args{plotwin_name}.'_1',
			command_f =>
				 $p0_a
				.$p1
				."plot_mode <- \"color\"\n"
				.$p2,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;
		$com_a = "plot_mode <- \"gray\"\n".$p2;
	}
	
	push @plots, kh_r_plot->new(
		name      => $args{plotwin_name}.'_2',
		command_f =>
			 $p0_a
			.$p1
			."plot_mode <- \"gray\"\n"
			.$p2,
		command_a =>
			 $com_a,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or $flg_error = 1;


	push @plots, kh_r_plot->new(
		name      => $args{plotwin_name}.'_3',
		command_f =>
			 $p0_a
			.$p1
			."plot_mode <- \"freq\"\n"
			.$p2,
		command_a =>
			 "plot_mode <- \"freq\"\n"
			.$p2,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or $flg_error = 1;

	push @plots, kh_r_plot->new(
		name      => $args{plotwin_name}.'_4',
		command_f =>
			 $p0_a
			.$p1
			."plot_mode <- \"umat\"\n"
			.$p2,
		command_a =>
			 "plot_mode <- \"umat\"\n"
			.$p2,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or $flg_error = 1;

	$::config_obj->R->send("print( summary(somm) )");
	my $t = $::config_obj->R->read;
	$t .= "\n";
	$t .= "U-Matrix:\n";
	$t .= $plots[$#plots]->r_msg;
	$t =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	print "-------------------------[Begin]-------------------------[R]\n";
	print "$t\n";
	print "---------------------------------------------------------[R]\n";

	kh_r_plot->clear_env;
	undef $self;
	undef %args;
	$self->{result_plots} = \@plots;
	#$self->{result_info} = $info;
	#$self->{result_info_long} = $info_long;
	
	return 0 if $flg_error;
	return $self;
}

sub r_cmd_p0_hx{
	return '

d <- t(d)
d <- subset(d, rowSums(d) > 0)
d <- scale(d)
d <- t(d)

# SOM
library(som)
somm <- som(
	d,
	n_nodes,
	n_nodes,
	topol="hexa",
	rlen=c(rlen1,rlen2)
)

word_labs <- rownames(d)


';
}

sub r_cmd_p1_hx{
	return '

# 格子の座標を取得
row2coods <- NULL
eve <- 0
for (i in 0:(n_nodes - 1)){
	for (h in 0:(n_nodes - 1)){
		row2coods <- c(row2coods, h + eve, i)
	}
	if (eve == 0){
		eve <- 0.5
	} else {
		eve <- 0
	}
}
row2coods <- matrix( row2coods, byrow=T, ncol=2  )

# 格子のクラスター化
if ( if_cls == 1 ){
	library(amap)
	library( RColorBrewer )
	hcl <- hcluster(somm$code, method="euclidean", link="ward")

	colors <- NULL
	if (n_cls <= 9){
		pastel <- brewer.pal(9, "Pastel1")
		# pastel[6] = brewer.pal(9, "Pastel1")[9]
		# pastel[9] = brewer.pal(9, "Pastel1")[6]
		pastel[6] = "gray91"
		pastel[9] = "#F5F5DC" # FAF3C8 F7F1C6 EEE8AA F0E68C
		colors <- pastel[cutree(hcl,k=n_cls)]
	}
	if (n_cls > 9) {
		# 色の順番を決定
		library(colorspace)
		new_col <- order( runif(n_cls) )
		colors <-
			rainbow_hcl(n_cls, start=20, end=340, l=92, c=20)[
			#terrain_hcl(n_cls, c = c(35, 5), l = c(85, 95), power = c(0.5,1))[
				new_col[cutree(hcl,k=n_cls)]
			]
	}
} else {
	colors <- rep("gray90", n_nodes^2)
}
labcd <- NULL




';
}

sub r_cmd_p2_hx{

return 
'
# プロットの実行
par(mai=c(0,0,0,0), mar=c(0,0,0,0), omi=c(0,0,0,0), oma =c(0,0,0,0) )

plot(                                             # 初期化
	NULL,NULL,
	xlim=c(0,n_nodes-0.5),
	ylim=c(0,n_nodes-1),
	axes=F,
	frame.plot=F
)

if (if_plothex == 1){                             # 格子の色
	a <- 0.333333333333
} else {
	a <- 0.5
}
b <- 1-a

if ( plot_mode == "gray"){                        # 各カラーモードへの対応
	color_act  <- rep("white",n_nodes^2)
	color_line <- "gray70"
	if_points  <- 1
	w_lwd      <- 1
	color_cls  <- "gray45"
	color_ptf  <- "gray90"
}
if ( plot_mode == "color" ) {
	color_act <- colors
	color_line <- "white"
	if_points  <- 1
	w_lwd      <- 1
	if (n_cls > 9) {
		color_cls  <- "gray45"
	} else {
		color_cls  <- "gray60"
	}
	color_ptf  <- "white"
}
if ( plot_mode == "freq" ){
	color_act <- somm$code.sum$nobs;
	if (max(color_act) == 1){
		color_act <- color_act * 3 + 1;
	} else {
		color_act <- color_act - min(color_act)
		color_act <- round( color_act / max(color_act) * 6 ) + 1
		#color_act[color_act==7] <- 6
	}
	color_seed <- brewer.pal(6,"GnBu")
	#color_seed <- brewer.pal(6,"YlOrRd")
	color_seed <- c("white", color_seed)
	color_act <- color_seed[color_act]
	
	color_line <- "gray70"
	if_points  <- 0
	w_lwd      <- 1
	color_cls  <- "gray45"
	color_ptf  <- "white"
}
if ( plot_mode == "umat" ){
	
	# 距離計算
	dist_u <- NULL
	
	dist_m <- as.matrix( dist(somm$code, method="euclid") )
	
	for (i in 0:(n_nodes - 1)){
		for (h in 0:(n_nodes - 1)){
			cu <- NULL
			n  <- 0
			
			if (h != n_nodes -1){       # 右
				cu <- c(
					cu, 
					dist_m[
						h     + i * n_nodes + 1,
						h + 1 + i * n_nodes + 1
					]
				)
			}
			
			if (h != 0){                # 左
				cu <- c(
					cu,
					dist_m[
						h     + i * n_nodes + 1,
						h - 1 + i * n_nodes + 1
					]
				)
			}
			
			if (i != n_nodes - 1){
				if (h %% 2 == 0){       # 右上（偶数）
					cu <- c(
						cu,
						dist_m[
							h +   i       * n_nodes + 1,
							h + ( i + 1 ) * n_nodes + 1
						]
					)
				} else {                # 右上（奇数）
					if (h != n_nodes -1){
						cu <- c(
							cu,
							dist_m[
								h     +   i       * n_nodes + 1,
								h + 1 + ( i + 1 ) * n_nodes + 1
							]
						)
					}
				}
			}
			
			if (i != 0){
				if (h %% 2 == 0){       # 右下（偶数）
					cu <- c(
						cu,
						dist_m[
							h +   i       * n_nodes + 1,
							h + ( i - 1 ) * n_nodes + 1
						]
					)
				} else {                # 右下（奇数）
					if (h != n_nodes -1){
						cu <- c(
							cu,
							dist_m[
								h     +   i       * n_nodes + 1,
								h + 1 + ( i - 1 ) * n_nodes + 1
							]
						)
					}
				}
			}
			
			if (i != n_nodes - 1){
				if (h %% 2 == 0){       # 左上（偶数）
					if (h != 0){
						cu <- c(
							cu,
							dist_m[
								h      +   i       * n_nodes + 1,
								h - 1  + ( i + 1 ) * n_nodes + 1
							]
						)
					}
				} else {                # 左上（奇数）
					cu <- c(
						cu,
						dist_m[
							h +   i       * n_nodes + 1,
							h + ( i + 1 ) * n_nodes + 1
						]
					)
				}
			}
			
			if (i != 0){
				if (h %% 2 == 0){       # 左下（偶数）
					if (h != 0){
						cu <- c(
							cu,
							dist_m[
								h      +   i       * n_nodes + 1,
								h - 1  + ( i - 1 ) * n_nodes + 1
							]
						)
					}
				} else {                # 左下（奇数）
					cu <- c(
						cu,
						dist_m[
							h +   i       * n_nodes + 1,
							h + ( i - 1 ) * n_nodes + 1
						]
					)
				}
			}
			dist_u <- c(dist_u, median(cu) )
		}
	}
	
	print( summary(dist_u) )
	
	dist_u <- dist_u - min(dist_u)
	dist_u <- round( dist_u / max(dist_u) * 100 ) + 1
	color_act <- cm.colors(101)[dist_u]
	
	color_line <- "gray70"
	if_points  <- 1
	w_lwd      <- 1
	color_cls  <- "gray45"
	color_ptf  <- "white"
}


for (i in 1:n_nodes^2){                           # ノードの色
	x <- row2coods[i,1]
	y <- row2coods[i,2]

	polygon(
		x=c( x + 0.5, x + 0.5, x,     x - 0.5, x - 0.5, x ),
		y=c( y + a,   y - a,   y - b, y - a,   y + a,   y + b ),
		col=color_act[i],
		border="white",
		lty=0,
	)
}


for (i in 0:(n_nodes - 1)){                       # 白線・縦
	for (h in 0:(n_nodes - 2)){
		if ( colors[h + i * n_nodes + 1] == colors[h + i * n_nodes + 2] ){
			x <- h
			y <- i
			if ( y %% 2 == 1 ){
				x <- x + 0.5
			}
			
			segments(
				x + 0.5, y + a,
				x + 0.5, y - a,
				col=color_line,
				lwd=w_lwd,
			)
		}
	}
}

for (i in 0:(n_nodes - 1)){                       # 白線・両端
	for (h in c(-1, n_nodes-1) ){
		x <- h
		y <- i
		if ( y %% 2 == 1 ){
			x <- x + 0.5
		}
		segments(                       # 縦線
			x + 0.5, y + a,
			x + 0.5, y - a,
			col=color_line,
			lwd=w_lwd,
		)
	}
	if ( y %% 2 == 0 ){
		segments(                       # 左端1
			-0.5, y + a,
			0   , y + 1 - a,
			col=color_line,
			lwd=w_lwd,
		)
		if ( y != 0){
			segments(                   # 左端2
				-0.5, y - a,
				 0  , y - 1 + a,
				col=color_line,
				lwd=w_lwd,
			)
		}
	} else {
		if ( y != n_nodes - 1){
			segments(                   # 右端1
				n_nodes - 0.5, y + 1 - a,
				n_nodes      , y + a,
				col=color_line,
				lwd=w_lwd,
			)
		}
		segments(                       # 右端2
			n_nodes - 0.5, y - 1 + a,
			n_nodes      , y - a,
			col=color_line,
			lwd=w_lwd,
		)
	}
}

for (i in 0:(n_nodes - 2)){                       # 白線・右上
	for (h in 0:(n_nodes - 1)){
		if (i %% 2 == 1){
			chk <- 1
		} else {
			chk <- 0
		}
	
		if (
			   is.na(colors[h +        i    * n_nodes + 1]) == 1
			|| is.na(colors[h + chk + (i+1) * n_nodes + 1]) == 1
			|| h + chk == n_nodes
		){
			next
		}
	
		if ( 
			    colors[h +        i    * n_nodes + 1]
			==  colors[h + chk + (i+1) * n_nodes + 1] 
		){
			x <- h
			y <- i
			if ( y %% 2 == 1 ){
				x <- x + 0.5
			}
			
			segments(
				x,       y + b,
				x + 0.5, y + a,
				col=color_line,
				lwd=w_lwd,
			)
		}
	}
}

for (i in 0:(n_nodes - 2)){                       # 白線・左上
	for (h in 0:(n_nodes - 1)){
		if (i %% 2 == 0){
			chk <- 1
		} else {
			chk <- 0
		}
		if (
			   is.na(colors[h +        i    * n_nodes + 1]) == 1
			|| is.na(colors[h - chk + (i+1) * n_nodes + 1]) == 1
			|| h - chk < 0
		){
			next
		}
	
		if ( 
			    colors[h +        i    * n_nodes + 1]
			==  colors[h - chk + (i+1) * n_nodes + 1] 
		){
			x <- h
			y <- i
			if ( y %% 2 == 1 ){
				x <- x + 0.5
			}
			
			segments(
				x,       y + b,
				x - 0.5, y + a,
				col=color_line,
				lwd=w_lwd,
			)
		}
	}
}



for (i in 0:(n_nodes - 1)){                       # グレー境界線・縦
	for (h in 0:(n_nodes - 2)){
		if ( colors[h + i * n_nodes + 1] != colors[h + i * n_nodes + 2] ){
			x <- h
			y <- i
			if ( y %% 2 == 1 ){
				x <- x + 0.5
			}
			
			segments(
				x + 0.5, y + a,
				x + 0.5, y - a,
				col=color_cls,
				lwd=2,
			)
		}
	}
}

for (i in 0:(n_nodes - 2)){                       # グレー境界線・右上
	for (h in 0:(n_nodes - 1)){
		if (i %% 2 == 1){
			chk <- 1
		} else {
			chk <- 0
		}
	
		if (
			   is.na(colors[h +        i    * n_nodes + 1]) == 1
			|| is.na(colors[h + chk + (i+1) * n_nodes + 1]) == 1
			|| h + chk == n_nodes
		){
			next
		}
	
		if ( 
			    colors[h +        i    * n_nodes + 1]
			!=  colors[h + chk + (i+1) * n_nodes + 1] 
		){
			x <- h
			y <- i
			if ( y %% 2 == 1 ){
				x <- x + 0.5
			}
			
			segments(
				x,       y + b,
				x + 0.5, y + a,
				col=color_cls,
				lwd=2,
			)
		}
	}
}

for (i in 0:(n_nodes - 2)){                       # グレー境界線・左上
	for (h in 0:(n_nodes - 1)){
		if (i %% 2 == 0){
			chk <- 1
		} else {
			chk <- 0
		}
	
		if (
			   is.na(colors[h +        i    * n_nodes + 1]) == 1
			|| is.na(colors[h - chk + (i+1) * n_nodes + 1]) == 1
			|| h - chk < 0
		){
			next
		}
	
		if ( 
			    colors[h +        i    * n_nodes + 1]
			!=  colors[h - chk + (i+1) * n_nodes + 1] 
		){
			x <- h
			y <- i
			if ( y %% 2 == 1 ){
				x <- x + 0.5
			}
			
			segments(
				x,       y + b,
				x - 0.5, y + a,
				col=color_cls,
				lwd=2,
			)
		}
	}
}

points <- NULL                                    # 語のポイント
sf <- 0.35
a  <- a   * sf;
b  <- b   * sf;
c  <- 0.5 * sf;
for (i in 1:nrow(somm$visual)){
	x <- somm$visual[i,1]
	y <- somm$visual[i,2]
	if ( y %% 2 == 1 ){
		x <- x + 0.5
	}
	points <- c(points, x, y)
}
points <- matrix( points, byrow=T, ncol=2  )

if( if_points == 1 ){
	if (F){
		for (i in 1:nrow(points)){
			x <- points[i,1]
			y <- points[i,2]
		
			polygon(
				x=c( x + c, x + c, x,     x - c, x - c, x ),
				y=c( y + a,   y - a,   y - b, y - a,   y + a,   y + b ),
				col=color_ptf,
				border="gray70",
				lty=1,
			)
		}
	} else {
		symbols(
			points[,1],
			points[,2],
			squares=rep(0.35,length(points[,1])),
			#circles=rep(0.2,length(points[,1])),
			fg="gray70",
			bg=color_ptf,
			inches=F,
			add=T,
		)
	}
}

library(maptools)                                 # 語のラベル
if (is.null(labcd) == 1){
	labcd <- pointLabel(
		x=points[,1],
		y=points[,2],
		labels=word_labs,
		doPlot=F,
		cex=cex,
		offset=0
	)

	# ラベル再調整
	xorg <- points[,1]
	yorg <- points[,2]
	#cex  <- 1

	library(wordcloud)
	nc <- wordlayout(
		labcd$x,
		labcd$y,
		word_labs,
		cex=cex * 1.25,
		xlim=c(  par( "usr" )[1], par( "usr" )[2] ),
		ylim=c(  par( "usr" )[3], par( "usr" )[4] )
	)

	xlen <- par("usr")[2] - par("usr")[1]
	ylen <- par("usr")[4] - par("usr")[3]

	for (i in 1:length(word_labs) ){
		x <- ( nc[i,1] + .5 * nc[i,3] - labcd$x[i] ) / xlen
		y <- ( nc[i,2] + .5 * nc[i,4] - labcd$y[i] ) / ylen
		d <- sqrt( x^2 + y^2 )
		if ( d > 0.05 ){
			# print( paste( rownames(cb)[i], d ) )
			
			segments(
				nc[i,1] + .5 * nc[i,3], nc[i,2] + .5 * nc[i,4],
				xorg[i], yorg[i],
				col="gray60",
				lwd=1
			)
			
		}
	}

	xorg <- labcd$x
	yorg <- labcd$y
	labcd$x <- nc[,1] + .5 * nc[,3]
	labcd$y <- nc[,2] + .5 * nc[,4]



}

text(
	labcd$x,
	labcd$y,
	labels=word_labs,
	cex=cex,
	offset=0,
	font=text_font
)


';
}

1;