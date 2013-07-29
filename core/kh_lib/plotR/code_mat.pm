package plotR::code_mat;

use strict;

use kh_r_plot;

sub new{
	my $class = shift;
	my %args = @_;

	#print "$class\n";

	my $self = \%args;
	bless $self, $class;

	kh_r_plot->clear_env;

	my $r_command = $args{r_command};

	# パラメーター設定（ヒートマップ）
	$r_command .= "cex <- $args{font_size}\n";
	
	unless ( $args{heat_dendro_c} ){
		$args{heat_dendro_c} = 0;
	}
	$r_command .= "dendro_c <- $args{heat_dendro_c}\n";

	unless ( $args{heat_dendro_v} ){
		$args{heat_dendro_v} = 0;
	}
	$r_command .= "dendro_v <- $args{heat_dendro_v}\n";

	unless ( $args{heat_cellnote} ){
		$args{heat_cellnote} = 0;
	}
	$r_command .= "cellnote <- $args{heat_cellnote}\n";

	unless ( $args{plot_size_heat} ){
		$args{plot_size_heat} = 480;
	}

	# パラメーター設定（バブルプロット）
	$args{plot_size_maph} = 480 unless $args{plot_size_maph};
	$args{plot_size_mapw} = 640 unless $args{plot_size_mapw};
	print "$args{plot_size_heat}, $args{plot_size_maph}, $args{plot_size_mapw}\n";


	# プロット作成
	
	#use Benchmark;
	#my $t0 = new Benchmark;
	
	my @plots = ();
	my $flg_error = 0;

	$plots[0] = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f =>
			 $r_command
			.$self->r_plot_cmd_heat,
		width     => 640,
		height    => $args{plot_size_heat},
	) or $flg_error = 1;

	$plots[1] = kh_r_plot->new(
		name      => $args{plotwin_name}.'_2',
		command_f =>
			 $r_command
			.$self->r_plot_cmd_fluc,
		width     => $args{plot_size_mapw},
		height    => $args{plot_size_maph},
	) or $flg_error = 1;

	#my $t1 = new Benchmark;
	#print timestr(timediff($t1,$t0)),"\n" if $bench;

	kh_r_plot->clear_env;
	undef $self;
	undef %args;
	$self->{result_plots} = \@plots;
	
	return 0 if $flg_error;
	return $self;
}

sub r_plot_cmd_fluc{
	return '

library(ggplot2)

font_fam <- "Meiryo UI"
get.gpar()
if ( is.na(dev.list()["pdf"]) && is.na(dev.list()["postscript"]) ){
	if ( grepl("darwin", R.version$platform) ){
		quartzFonts(HiraKaku=quartzFont(rep("Hiragino Kaku Gothic Pro W6",4)))
		font_fam <- "HiraKaku"
	}
}

ggfluctuation_my <- function (mat){
	# preparing the data.frame
	table <- NULL
	for (r in 1:nrow(mat)){
		for (l in 1:ncol(mat)){
			table <- rbind(table, c(r, l, mat[r,l]))
		}
	}
	table <- data.frame(
		x	  = as.factor(table[,2]),
		y	  = as.factor(table[,1]),
		result = table[,3]
	)

	# create the plot
	p <- ggplot(
		table,
		aes_string(
			x = "x",
			y = "y",
			size = "result"
		)
	)
	rgb <- col2rgb( "black" ) / 255
	col <- rgb(
		red  =rgb[1,1],
		green=rgb[2,1],
		blue =rgb[3,1],
		alpha=0.25
	)
	p <- p + geom_point(
		shape=22,
		fill=col,
		colour="black",
		alpha=0.5
	)

	# cofigure the regend
	bt <- floor( floor(max(table$result)) / 3 )
	breaks <- c(bt, 2 * bt, 3 * bt)
	p <- p + scale_area(
		"Percent:",
		limits = c(1, ceiling(max(table$result))),
		to=c(0,15),
		breaks = breaks
	)
	
	# labels of axis
	p <- p + scale_x_discrete(
		breaks = 1:ncol(mat),
		labels = colnames(mat)
	)
	p <- p + scale_y_discrete(
		breaks = 1:nrow(mat),
		labels = rownames(mat)
	)
	p <- p + xlab("")
	p <- p + ylab("")

	# other cofigs of the plot
	nx <- length(levels(table$x))
	ny <- length(levels(table$y))
	p <- p + opts(
		#aspect.ratio = ny/nx,
		axis.text.x=theme_text(
			size=12 * cex,
			angle=90,
			hjust=1,
			family=font_fam
		),
		axis.text.y=theme_text(
			size=12 * cex,
			hjust=1,
			family=font_fam
		)
	)

	print(p)

}


ggfluctuation_my(  t( as.matrix(d) ) ) 

	';
}



sub r_plot_cmd_heat{
	return '

library(grid)
library(pheatmap)
library(RColorBrewer)

font_fam <- "Meiryo UI"
get.gpar()
if ( is.na(dev.list()["pdf"]) && is.na(dev.list()["postscript"]) ){
	if ( grepl("darwin", R.version$platform) ){
		quartzFonts(HiraKaku=quartzFont(rep("Hiragino Kaku Gothic Pro W6",4)))
		font_fam <- "HiraKaku"
	}
}

if (F) {
	savefile <- NULL
	require(tcltk)
	csvfile <- tclvalue(
	    tkgetOpenFile(
	        filetypes = "{{CSV Files} {.csv}}",
	        defaultextension=".csv"
	    )
	)
	d <- read.csv(csvfile, header=T, sep = ",", row.names=1)
	d <- as.matrix(d)
}


if (cellnote == 1){
	colors <- brewer.pal(9,"BuGn")[1:8]
} else {
	colors <- brewer.pal(9,"BuGn")[1:9]
}

col.labels <- rownames(d);
if ( length(col.labels) > 35 && (dendro_v == 0)){
	cutting <- length(col.labels) / 30
	cutting <- ceiling(cutting)
	col.labels <- NULL
	n <- 1
	while ( n <= nrow(d) ){
		col.labels[n] <- rownames(d)[n]
		n <- n + cutting
	}
	for (i in (1:length(rownames(d)))){
		if (is.na(col.labels[i]) == TRUE){
			col.labels[i] <- ""
		}
	}
	rownames(d) <- col.labels
}

cexcol <- 12
if ( length(col.labels) > 35 && (dendro_v == 1)){
	#cexcol <- 0.2 + 1/log10( length(col.labels) * 5)
	cexcol <- 2 + 8 * 30 / length(col.labels)
}

# pheatmapのカスタマイズ
draw_matrix_my = function(
	matrix,
	border_color,
	fmat,
	fontsize_number
){
	n = nrow(matrix)
	m = ncol(matrix)
	x = (1:m)/m - 1/2/m
	y = 1 - ((1:n)/n - 1/2/n)
	for(i in 1:m){
		grid.rect(
			x      = x[i],
			y      = y[1:n],
			width  = 1/m,
			height = 1/n - (1/n) * 0.2, # 行と行の間に隙間を作る
			gp     = gpar(
				fill = matrix[,i],
				col  = NA, #ifelse((attr(fmat, "draw")), NA, NA),
				lwd=2
			)
		)
		if(attr(fmat, "draw")){
			grid.text(x = x[i], y = y[1:n], label = fmat[, i], gp = gpar(col = "black", fontsize = fontsize_number))
		}
	}
}

assignInNamespace(
	x="draw_matrix",
	value=draw_matrix_my,
	ns=asNamespace("pheatmap")
)

pheatmap(
	t(d),
	color                    = colors,
	drop_levels              = T,
	fontsize_col             = cexcol * cex,
	fontsize_row             = 12 * cex,
	border_color             = NA,
	cluster_cols             = ifelse(dendro_v==1, T, F),
	cluster_rows             = ifelse(dendro_c==1, T, F),
	display_numbers          = ifelse(cellnote==1, T, F),
	number_format            = "%.1f",
	legend                   = ifelse(cellnote==1, F, T),
	fontsize_number          = 10 * cex,
	clustering_distance_rows = "euclidean",
	clustering_method        = "ward",
	fontfamily               = font_fam,
)

	';
}

1;