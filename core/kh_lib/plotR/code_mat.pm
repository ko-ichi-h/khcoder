package plotR::code_mat;

use strict;
use utf8;

use kh_r_plot;

sub new{
	my $class = shift;
	my %args = @_;

	#print "$class\n";

	my $self = \%args;
	bless $self, $class;

	kh_r_plot->clear_env;

	my $r_command = $args{r_command};

	# パラメーター設定（共通）
	$args{font_size} = $::config_obj->plot_font_size / 100 unless $args{font_size}; # フォントサイズ
	#$r_command .= "cex <- $args{font_size}\n";
	$r_command .= "cex <- 1\n";

	if ( defined($self->{selection}) ){                # コード選択
		if ( $#{$self->{selection}} > -1 ){
			$r_command .= "c_names <- colnames(d)\n";
			
			my $t = '';
			foreach my $i (@{$self->{selection}}){
					$t .= "$i,";
			}
			chop $t;
			$r_command .= "d <- as.matrix(d[,c($t)])\n";
			$r_command .= "rsd <- as.matrix(rsd[,c($t)])\n";
			$r_command .= "colnames(d) <- c_names[c($t)]\n";
		}
	}

	# パラメーター設定（ヒートマップ）
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

	
	$args{plot_size_heat} = 480 unless $args{plot_size_heat};

	# パラメーター設定（バブルプロット）
	$args{plot_size_maph} = $::config_obj->plot_size_codes unless $args{plot_size_maph};
	$args{plot_size_mapw} = $::config_obj->plot_size_words unless $args{plot_size_mapw};
	
	$args{bubble_shape} = 0 unless length($args{bubble_shape});
	$r_command .= "bubble_shape <- $args{bubble_shape}\n";
	
	$args{bubble_size} = 1 unless $args{bubble_size};
	$args{bubble_size} = int( $args{bubble_size} * 100 + 0.5) / 100;
	$r_command .= "bubble_size <- $args{bubble_size}\n";

	$args{color_rsd} = 1 unless length($args{color_rsd});
	$r_command .= "color_rsd <- $args{color_rsd}\n";

	$args{color_gry} = 0 unless length($args{color_gry});
	$r_command .= "color_gry <- $args{color_gry}\n";

	$args{color_maxv} = 10 unless length( $args{color_maxv} );
	$r_command .= "maxv <- $args{color_maxv}\n";
	
	$args{color_fix} = 0 unless length( $args{color_fix} );
	$r_command .= "color_fix <- $args{color_fix}\n";
	
	# プロット作成
	
	my @plots = ();
	my $flg_error = 0;

	$plots[0] = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f =>
			 $r_command
			.$self->r_plot_cmd_heat,
		width     => $::config_obj->plot_size_words,
		height    => $args{plot_size_heat},
		font_size => $args{font_size},
	) or $flg_error = 1;

	$plots[1] = kh_r_plot->new(
		name      => $args{plotwin_name}.'_2',
		command_f =>
			 $r_command
			.$self->r_plot_cmd_fluc,
		width     => $args{plot_size_mapw},
		height    => $args{plot_size_maph},
		font_size => $args{font_size},
	) or $flg_error = 1;

	#$plots[2] = kh_r_plot->new(
	#	name      => $args{plotwin_name}.'_3',
	#	command_f =>
	#		 $r_command
	#		.$self->r_plot_cmd_line,
	#	width     => 640,
	#	height    => 480,
	#) or $flg_error = 1;


	kh_r_plot->clear_env;
	undef $self;
	undef %args;
	$self->{result_plots} = \@plots;
	
	return 0 if $flg_error;
	return $self;
}

sub r_plot_cmd_fluc{
	my $self = shift;
	return '

alpha_value <- 0.5

bubble_size <- bubble_size / '.$self->{font_size}.'

if ( exists("saving_emf") || exists("saving_eps") ){
	alpha_value <- 1
}

library(grid)
library(ggplot2)

font_fam <- NULL
if ( is.null(dev.list()) ){
	font_fam <- 1
} else {
	if ( is.na(dev.list()["pdf"]) && is.na(dev.list()["postscript"]) ){
		font_fam <- 1
	}
}
if ( is.null(font_fam) == FALSE ){
	if ( grepl("darwin", R.version$platform) ){
		quartzFonts(HiraKaku=quartzFont(rep("'.$::config_obj->font_plot_current.'",4)))
		font_fam <- "HiraKaku"
	} else {
		font_fam <- "'.$::config_obj->font_plot_current.'"
	}
}

ggfluctuation_my <- function (mat, rsd, maxv){
	if (nrow(mat) > 1){
		mat <- mat[nrow(mat):1,]
		rsd <- rsd[nrow(rsd):1,]
	}
	
	# preparing the data.frame
	table <- NULL
	for (r in 1:nrow(mat)){
		for (l in 1:ncol(mat)){
			table <- rbind(table, c(r, l, mat[r,l], rsd[r,l]))
		}
	}
	table <- data.frame(
		x	  = as.factor(table[,2]),
		y	  = as.factor(table[,1]),
		result = table[,3],
		rsd    = table[,4]
	)
	table <- subset(table, result > 0)

	if (color_fix == 1){
		table$rsd[table$rsd >  maxv     ] <- maxv
		table$rsd[table$rsd <  maxv * -1] <- maxv * -1
	}

	# Set up the plot
	p <- ggplot(
		table,
		aes_string(
			x = "x",
			y = "y",
			size = "result",
			fill = "rsd"
		)
	)

	# Basic points
	if (color_rsd == 1){
		p <- p + geom_point(
			shape=ifelse(bubble_shape==0, 22, 21),
			colour = "black",
			alpha=alpha_value
		)
	} else {
		p <- p + geom_point(
			shape=ifelse(bubble_shape==0, 22, 21),
			colour="black",
			fill="gray30",
			alpha=alpha_value
		)
	}

	# Fill color
	if (color_rsd == 1){
		limv = max( abs( table$rsd ) )
		if ( color_fix == 1 ){
			limv <- maxv
		}
		if (color_gry == 1){
			p <- p + scale_fill_gradientn(
				colours = paste("gray",95:1, sep=""),
				limits = c( limv * -1, limv ),
				guide = guide_legend(
					title = "Pearson rsd.",
					order = 1,
					override.aes = list(size=6, shape=22),
					label.hjust = 1,
					reverse = TRUE,
					keyheight = unit(1.5,"line")
				)
			)
		}
		else if (color_gry == -1){
			p <- p + scale_fill_gradientn(
				colours = cm.colors(99),
				limits = c( limv * -1, limv ),
				guide = guide_legend(
					title = "Pearson rsd.",
					order = 1,
					override.aes = list(size=6, shape=22),
					label.hjust = 1,
					reverse = TRUE,
					keyheight = unit(1.5,"line")
				)
			)
		} else {
			library(RColorBrewer)
			myPalette <- colorRampPalette(rev(brewer.pal(5, "RdYlBu"))) #Spectral
			
			p <- p + scale_fill_gradientn(
				colours = myPalette(100),
				limits = c( limv * -1, limv ),
				na.value = "black",
				guide = guide_colourbar(
					title = "Pearson rsd.\n",
					title.theme = element_text(
						face="bold",
						size=11,
						lineheight=0.4,
						angle=0
					),
					label.hjust = 1,
					order = 1
				)
			)
		}
	}

	p <- p + scale_size_area(
		limits = c(0.05, ceiling(max(table$result))),
		max_size = 15*bubble_size,
		guide = guide_legend(
			title = "Percent",
			override.aes = list(alpha = 1, fill=NA),
			label.hjust = 1,
			order = 2
		)
	)

	# labels of axis
	p <- p + scale_x_discrete(
		breaks = 1:ncol(mat),
		labels = colnames(mat),
		expand = c(0.015, 0.5)
	)
	p <- p + scale_y_discrete(
		breaks = 1:nrow(mat),
		labels = rownames(mat),
		expand = c(0.015, 0.5)
	)

	# other cofigs of the plot
	nx <- length(levels(table$x))
	ny <- length(levels(table$y))
	p <- p + theme_classic()
	p <- p + theme(
		#aspect.ratio = ny/nx,
		#legend.background=element_rect(fill="gray96",colour = NA),
		legend.key=element_rect(fill=NA,colour = NA),
		legend.title = element_text(face="bold",  size=11, angle=0),
		legend.text  = element_text(face="plain", size=11, angle=0),
		plot.margin =   unit(c(0.25, 0.01, 0.25, 0.25), "cm"),
		axis.line.x    = element_line(colour = "black", size=0.5),
		axis.line.y    = element_line(colour = "black", size=0.5),
		panel.grid.major.x = element_line(
			#colour = "gray25",
			#linetype="dotted"
			colour = "gray50",
			size=0.25
		),
		panel.grid.major.y = element_line(
			#colour = "gray25",
			#linetype="dotted"
			colour = "gray50",
			size=0.25
		),
		axis.title.y     = element_blank(),
		axis.title.x     = element_blank(),
		axis.ticks       = element_blank(),
		axis.text.x=element_text(
			size=12 * cex,
			colour="black",
			angle=90,
			hjust=1
			#family=font_fam
		),
		axis.text.y=element_text(
			size=12 * cex,
			colour="black",
			hjust=1
			#family=font_fam
		)
	)

	if ( is.null(font_fam) == FALSE ){
		p <- p + theme(
			axis.text.x=element_text(
				size=12 * cex,
				colour="black",
				angle=90,
				hjust=1,
				family=font_fam
			),
			axis.text.y=element_text(
				size=12 * cex,
				colour="black",
				hjust=1,
				family=font_fam
			)
		)
	}
	print(p)
}


ggfluctuation_my(  t( as.matrix(d) ),  t( as.matrix(rsd) ), maxv ) 

	';
}



sub r_plot_cmd_heat{
	return '

if (ncol(d) == 1){
	dendro_c <- 0
}
if (nrow(d) == 1){
	dendro_v <- 0
}

library(grid)
library(pheatmap)
library(RColorBrewer)

font_fam <- NULL
if ( is.null(dev.list()) ){
	font_fam <- 1
} else {
	if ( is.na(dev.list()["pdf"]) && is.na(dev.list()["postscript"]) ){
		font_fam <- 1
	}
}
if ( is.null(font_fam) == FALSE ){
	if ( grepl("darwin", R.version$platform) ){
		quartzFonts(HiraKaku=quartzFont(rep("'.$::config_obj->font_plot_current.'",4)))
		font_fam <- "HiraKaku"
	} else {
		font_fam <- "'.$::config_obj->font_plot_current.'"
	}
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

draw_colnames_my = function(coln, ...){
	m = length(coln)
	x = (1:m)/m - 1/2/m
	grid.text(coln, x = x, y = unit(0.96, "npc"), vjust = 0.5, hjust = 1, rot = 90, gp = gpar(...))
}

assignInNamespace(
	x="draw_colnames",
	value=draw_colnames_my,
	ns=asNamespace("pheatmap")
)

cluster_mat_my = function(mat, distance, method){
	d = dist(mat, method = "euclid")
	
	if (
		   ( as.numeric( R.Version()$major ) >= 3 )
		&& ( as.numeric( R.Version()$minor ) >= 1.0)
	){                                                      # >= R 3.1.0
		hcl <- hclust(d,method="ward.D2")
	} else {                                                # <= R 3.0
		hcl <- hclust(d^2,method="ward")
		hcl$height <- sqrt( hcl$height )
	}
	
	return(hcl)
}

assignInNamespace(
	x="cluster_mat",
	value=cluster_mat_my,
	ns=asNamespace("pheatmap")
)


if ( is.null(font_fam) == FALSE ){
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
		fontfamily               = font_fam,
	)
} else {
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
		#fontfamily               = font_fam,
	)
}


	';
}

1;