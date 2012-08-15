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

	# プロット作成
	my @plots = ();
	my $flg_error = 0;

	$plots[0] = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f =>
			 $r_command
			.$self->r_plot_cmd_p1
			."if_gray <- 0\n"
			.$self->r_plot_cmd_p2,
		width     => $args{plot_size},
		height    => $args{plot_size},
	) or $flg_error = 1;

	if ( $args{n_cls} > 0 ){
		$plots[1] = kh_r_plot->new(
			name      => $args{plotwin_name}.'_2',
			command_f =>
				 $r_command
				.$self->r_plot_cmd_p1
				."if_gray <- 1\n"
				.$self->r_plot_cmd_p2,
			command_a =>
				 "if_gray <- 1\n"
				.$self->r_plot_cmd_p2,
			width     => $args{plot_size},
			height    => $args{plot_size},
		) or $flg_error = 1;
	}

	kh_r_plot->clear_env;
	undef $self;
	undef %args;
	$self->{result_plots} = \@plots;
	#$self->{result_info} = $info;
	#$self->{result_info_long} = $info_long;
	
	return 0 if $flg_error;
	return $self;
}

sub r_plot_cmd_p1{
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
		colors <- brewer.pal(9, "Pastel1")[cutree(hcl,k=n_cls)]
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

sub r_plot_cmd_p2{

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




1;