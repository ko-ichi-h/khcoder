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

	# パラメーター設定部分
	$r_command .= "cex <- $args{font_size}\n";
	$r_command .= "text_font <- $args{font_bold}\n";
	$r_command .= "n_nodes <- $args{n_nodes}\n";
	$r_command .= "n_cls <- $args{n_cls}\n";
	if ($args{p_topo} eq 'hx'){
		$r_command .= "if_plothex <- 1\n";
	} else {
		$r_command .= "if_plothex <- 0\n";
	}

	my ($p1, $p2);
	if ($args{topo} eq 'hx'){
		$p1 = $self->r_cmd_p1_hx;
		$p2 = $self->r_cmd_p2_hx;
	} else {
		$p1 = $self->r_cmd_p1_sq;
		$p2 = $self->r_cmd_p2_sq;
	}

	# プロット作成
	my @plots = ();
	my $flg_error = 0;

	$plots[0] = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f =>
			 $r_command
			.$p1
			."if_gray <- 0\n"
			.$p2,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or $flg_error = 1;

	if ( $args{n_cls} > 0 ){
		$plots[1] = kh_r_plot->new(
			name      => $args{plotwin_name}.'_2',
			command_f =>
				 $r_command
				.$p1
				."if_gray <- 1\n"
				.$p2,
			command_a =>
				 "if_gray <- 1\n"
				.$p2,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;
	}

	$::config_obj->R->send("print( summary(somm) )");
	my $t = $::config_obj->R->read;
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

sub r_cmd_p1_sq{
	return '

d <- t(d)
d <- subset(d, rowSums(d) > 0)
d <- scale(d)
d <- t(d)

# SOMの実行
library(som)
ti <- system.time(
	somm <- som(
		d,
		n_nodes,
		n_nodes,
		rlen=c(414,2070)
	)
)
#print(ti)
#print(somm$rlen)
#print(somm$qerror)

# 格子の座標を取得
row2coods <- NULL
for (i in 0:(n_nodes - 1)){
	for (h in 0:(n_nodes - 1)){
		row2coods <- c(row2coods, h, i)
	}
}
row2coods <- matrix( row2coods, byrow=T, ncol=2  )

# 格子のクラスター化（色分け）
if ( n_cls > 0 ){
	library(amap)
	library( RColorBrewer )
	hcl <- hcluster(somm$code, method="euclidean", link="ward")

	colors <- NULL
	if (n_cls <= 9){
		pastel <- brewer.pal(9, "Pastel1")
		pastel[6] = brewer.pal(9, "Pastel1")[9]
		pastel[9] = brewer.pal(9, "Pastel1")[6]
		colors <- pastel[cutree(hcl,k=n_cls)]
	} else {
		colors <- brewer.pal(12, "Set3")[cutree(hcl,k=n_cls)]
	}
} else {
	colors <- rep("gray90", n_nodes^2)
}

library(maptools)                                 # 語のラベル
labcd <- NULL

	';
}

sub r_cmd_p2_sq{

return 
'

# プロットの実行
par(mai=c(0,0,0,0), mar=c(0,0,0,0), omi=c(0,0,0,0), oma =c(0,0,0,0) )

plot(                                             # 初期化
	somm$visual[,1:2],
	type="p",
	axes=F,
	frame.plot=F
)

if (if_gray == 1){                                # 格子の色
	symbols(
		row2coods[,1],
		row2coods[,2],
		squares=rep(1,length(row2coods[,1])),
		fg=NULL,
		bg="gray90",
		inches=F,
		add=T,
	)
} else {
	symbols(
		row2coods[,1],
		row2coods[,2],
		squares=rep(1,length(row2coods[,1])),
		fg=NULL,
		bg=colors,
		inches=F,
		add=T,
	)
}

for (i in 0:(n_nodes -1 )){                       # 縦線・白
	for (h in 0:(n_nodes - 2)){
		if ( colors[h + i * n_nodes + 1] == colors[h + i * n_nodes + 2] ){
			segments(
				h + 0.5, i + 0.5,
				h + 0.5, i - 0.5,
				col="white",
				lwd=1,
			)
		}
	}
}

for (i in 0:(n_nodes - 2)){                       # 横線・白
	for (h in 0:(n_nodes - 1)){
		if ( colors[h + i * n_nodes + 1] == colors[h + (i+1) * n_nodes + 1] ){
			segments(
				h - 0.5, i + 0.5,
				h + 0.5, i + 0.5,
				col="white",
				lwd=1,
			)
		}
	}
}

for (i in 0:(n_nodes - 1)){                       # 縦線・グレー
	for (h in 0:(n_nodes - 2)){
		if ( colors[h + i * n_nodes + 1] != colors[h + i * n_nodes + 2] ){
			segments(
				h + 0.5, i + 0.5,
				h + 0.5, i - 0.5,
				col="gray60",
				lwd=3,
			)
		}
	}
}


for (i in 0:(n_nodes - 2)){                       # 横線・グレー
	for (h in 0:(n_nodes - 1)){
		if ( colors[h + i * n_nodes + 1] != colors[h + (i+1) * n_nodes + 1] ){
			segments(
				h - 0.5, i + 0.5,
				h + 0.5, i + 0.5,
				col="gray60",
				lwd=3,
			)
		}
	}
}

symbols(                                          # 語のポイント
	somm$visual[,1],
	somm$visual[,2],
	squares=rep(0.4,length(somm$visual[,1])),
	fg="gray60",
	bg="white",
	inches=F,
	add=T,
)

if (is.null(labcd) == 1){
	labcd <- pointLabel(
		x=somm$visual[,1],
		y=somm$visual[,2],
		labels=rownames(d),
		doPlot=F,
		cex=cex,
		offset=0
	)
}

text(
	labcd$x,
	labcd$y,
	labels=rownames(d),
	cex=cex,
	offset=0,
	font=text_font
)


';

}


sub r_cmd_p1_hx{
	return '

d <- t(d)
d <- subset(d, rowSums(d) > 0)
d <- scale(d)
d <- t(d)

# SOMの実行
library(som)
ti <- system.time(
	somm <- som(
		d,
		n_nodes,
		n_nodes,
		topol="hexa",
		rlen=c(414,2070)
	)
)
#print(ti)
#print(somm$rlen)
#print(somm$qerror)

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

# 格子のクラスター化（色分け）
if ( n_cls > 0 ){
	library(amap)
	library( RColorBrewer )
	hcl <- hcluster(somm$code, method="euclidean", link="ward")

	colors <- NULL
	if (n_cls <= 9){
		pastel <- brewer.pal(9, "Pastel1")
		pastel[6] = brewer.pal(9, "Pastel1")[9]
		pastel[9] = brewer.pal(9, "Pastel1")[6]
		colors <- pastel[cutree(hcl,k=n_cls)]
	} else {
		colors <- brewer.pal(12, "Set3")[cutree(hcl,k=n_cls)]
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

if ( if_gray == 1){
	for (i in 1:n_nodes^2){
		x <- row2coods[i,1]
		y <- row2coods[i,2]

		polygon(
			x=c( x + 0.5, x + 0.5, x,     x - 0.5, x - 0.5, x ),
			y=c( y + a,   y - a,   y - b, y - a,   y + a,   y + b ),
			col="gray90",
			border="white",
			lty=0,
		)
	}
} else {
	for (i in 1:n_nodes^2){
		x <- row2coods[i,1]
		y <- row2coods[i,2]

		polygon(
			x=c( x + 0.5, x + 0.5, x,     x - 0.5, x - 0.5, x ),
			y=c( y + a,   y - a,   y - b, y - a,   y + a,   y + b ),
			col=colors[i],
			border="white",
			lty=0,
		)
	}
}

if (T){

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
				col="white",
				lwd=1,
			)
		}
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
				col="white",
				lwd=1,
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
				col="white",
				lwd=1,
			)
		}
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
				col="gray60",
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
				col="gray60",
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
				col="gray60",
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

if (F){
	for (i in 1:nrow(points)){
		x <- points[i,1]
		y <- points[i,2]
	
		polygon(
			x=c( x + c, x + c, x,     x - c, x - c, x ),
			y=c( y + a,   y - a,   y - b, y - a,   y + a,   y + b ),
			col="white",
			border="gray70",
			lty=1,
		)
	}
} else {
	symbols(
		points[,1],
		points[,2],
		squares=rep(0.35,length(points[,1])),
		fg="gray70",
		bg="white",
		inches=F,
		add=T,
	)
}

library(maptools)                                 # 語のラベル
if (is.null(labcd) == 1){
	labcd <- pointLabel(
		x=points[,1],
		y=points[,2],
		labels=rownames(d),
		doPlot=F,
		cex=cex,
		offset=0
	)
}

text(
	labcd$x,
	labcd$y,
	labels=rownames(d),
	cex=cex,
	offset=0,
	font=text_font
)

';
}

1;