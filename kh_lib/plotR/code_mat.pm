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
	$r_command .= "cex <- $args{font_size}\n";
	#$r_command .= "cex <- 1\n";

	if ( defined($self->{selection}) ){                # コード選択
		if ( $#{$self->{selection}} > -1 ){
			$r_command .= "c_names <- colnames(d)\n";
			
			my $t = '';
			foreach my $i (@{$self->{selection}}){
					$t .= "$i,";
			}
			chop $t;
			$r_command .= "d <- as.matrix(d[,c($t)])\n";
			$r_command .= "if (exists(\"rsd\")){ rsd <- as.matrix(rsd[,c($t)]) }\n";
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

	unless ( $args{topic_model} ){
		$args{topic_model} = 0;
	}
	$r_command .= "topic_model <- $args{topic_model}\n";
	
	$args{plot_size_heat} = 480 unless $args{plot_size_heat};

	# パラメーター設定（バブルプロット）
	$args{plot_size_maph} = $::config_obj->plot_size_codes unless $args{plot_size_maph};
	$args{plot_size_mapw} = $::config_obj->plot_size_words unless $args{plot_size_mapw};
	
	$args{bubble_shape} = 0 unless length($args{bubble_shape});
	$r_command .= "bubble_shape <- $args{bubble_shape}\n";
	
	$args{bubble_size} = 1 unless $args{bubble_size};
	$args{bubble_size} = int( $args{bubble_size} * 100 + 0.5) / 100;
	$r_command .= "bubble_size <- $args{bubble_size}\n";

	if (length($args{breaks})) {
		$r_command .= "breaks <- c($args{breaks})\n";
	} else {
		$r_command .= "breaks <- NULL\n";
	}

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

	$plots[0] = kh_r_plot->new(
		name      => $args{plotwin_name}.'_1',
		command_f =>
			 $r_command
			.$self->r_plot_cmd_heat,
		width     => $::config_obj->plot_size_words,
		height    => $args{plot_size_heat},
		font_size => $args{font_size},
	) or return 0;

	print "topic_model: $self->{topic_model}\n";
	unless ( $self->{topic_model} ){
		$plots[1] = kh_r_plot->new(
			name      => $args{plotwin_name}.'_2',
			command_f =>
				 $r_command
				.$self->r_plot_cmd_fluc,
			width     => $args{plot_size_mapw},
			height    => $args{plot_size_maph},
			font_size => $args{font_size},
		) or return 0;
	
		# get breaks of bubble plot legend
		$::config_obj->R->send('
			legend_breaks_n <- ""
			for ( i in 1:length(breaks_a) ){
				legend_breaks_n <- paste(legend_breaks_n, breaks_a[i], sep = ", ")
			}
			print(paste0("<breaks>", legend_breaks_n, "</breaks>"))
		');
		my $breaks = $::config_obj->R->read;
		if ( $breaks =~ /<breaks>(.+)<\/breaks>/) {
			$breaks = $1;
			substr($breaks, 0, 2) = '';
		}
		foreach my $i (@plots){
			$i->{command_f} .= "\n# breaks: $breaks\n";
		}
		print "breaks: $breaks\n";
	}

	kh_r_plot->clear_env;
	undef $self;
	undef %args;
	$self->{result_plots} = \@plots;
	
	return $self;
}

sub r_plot_cmd_fluc{
	my $self = shift;
	return '

# dpi: short based
alpha_value <- 0.5

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
					title = "Pearson residuals:",
					order = 1,
					override.aes = list(size=6, shape=22),
					label.hjust = 1,
					reverse = TRUE,
					keyheight = unit(1.5,"line")
				)
			)
		}
		else if (color_universal_design == 0){
			p <- p + scale_fill_gradientn(
				colours = cm.colors(99),
				limits = c( limv * -1, limv ),
				guide = guide_legend(
					title = "Pearson residuals:",
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
					title = "Pearson residuals:\n",
					title.theme = element_text(
						size=11,
						lineheight=0.4,
						angle=0
					),
					ticks.colour = "gray45",
					ticks.linewidth = 1/.pt,
					label.hjust = 1,
					order = 1
				)
			)
		}
	}

	# bubble plot legend configuration
	limits_a <- c(0.05, ceiling(max(table$result)));
	if (is.null(breaks)){
		breaks <- labeling::extended(
			0.05,
			max(table$result, na.rm=T),
			5
		)
		breaks_a <- NULL
		for ( i in 1:length(breaks) ){
			if (
				   0.05 <= breaks[i]
				&& max(table$result, na.rm=T) >= breaks[i]
			){
				breaks_a <- c(breaks_a, breaks[i])
			}
		}
		breaks <- breaks_a
	} else {
		breaks_a <- breaks
		if (  min(breaks) < 0.05 ){
			limits_a[1] <- min(breaks)
		}
		if (  max(breaks) > max(table$result, na.rm=T) ){
			limits_a[2] <- max(breaks)
		}
	}
	breaks_a <<- breaks_a

	p <- p + scale_size_area(
		breaks = breaks_a,
		limits = limits_a,
		max_size = 15*bubble_size,
		guide = guide_legend(
			title = "\nPercent:",
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
		legend.title = element_text(face="plain", size=11, angle=0),
		legend.text  = element_text(face="plain", size=11, angle=0),
		plot.margin =   unit(c(0.25, 0.01, 0.25, 0.25), "cm"),
		axis.line.x    = element_line(colour = "black", size=0.5),
		axis.line.y    = element_line(colour = "black", size=0.5),
		panel.grid.major = element_line(
			colour = "gray50",
			size=0.25
		),
		panel.grid.major.x = element_line(
			colour = "gray50",
			size=0.25
		),
		panel.grid.major.y = element_line(
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
	
	# color and width of ticks; continuous color scale legends; for ggplot2 v2.x.x
	library(grid)
	library(gtable)
	g <- ggplotGrob(p)
	if ( length( g$grobs[[8]][[1]][[1]] ) > 1){
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$col <- "gray45"
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$lwd <- 1
	}
	grid.draw(g)
	#print(p)
}

if (exists("rsd") == FALSE){
	rsd <- d
}
ggfluctuation_my(  t( as.matrix(d) ),  t( as.matrix(rsd) ), maxv ) 

	';
}



sub r_plot_cmd_heat{
	my $t0 = '

if (ncol(d) == 1){
	dendro_c <- 0
}
if (nrow(d) == 1){
	dendro_v <- 0
}

library(grid)
#library(pheatmap)
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
	n_lab <- 30
	n_lab <- round( n_lab / cex )
	if (n_lab < 2){
		n_lab <- 2
	}
	cutting <- length(col.labels) / n_lab
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
';

my $t1 = <<'EndOfPHeatmap';
#------------------------------------------------------------------------------
# original pheatmap 0.7.7 begin
#------------------------------------------------------------------------------

lo = function(rown, coln, nrow, ncol, cellheight = NA, cellwidth = NA, treeheight_col, treeheight_row, legend, annotation, annotation_colors, annotation_legend, main, fontsize, fontsize_row, fontsize_col, ...){
	# Get height of colnames and length of rownames
	if(!is.null(coln[1])){
		longest_coln = which.max(strwidth(coln, units = 'in'))
		gp = list(fontsize = fontsize_col, ...)
		coln_height = unit(1, "grobheight", textGrob(coln[longest_coln], rot = 90, gp = do.call(gpar, gp))) + unit(5, "bigpts")
	}
	else{
		coln_height = unit(5, "bigpts")
	}
	
	if(!is.null(rown[1])){
		longest_rown = which.max(strwidth(rown, units = 'in'))
		gp = list(fontsize = fontsize_row, ...)
		rown_width = unit(1, "grobwidth", textGrob(rown[longest_rown], gp = do.call(gpar, gp))) + unit(10, "bigpts")
	}
	else{
		rown_width = unit(5, "bigpts")
	}
	
	gp = list(fontsize = fontsize, ...)
	# Legend position
	if(!is.na(legend[1])){
		longest_break = which.max(nchar(names(legend)))
		longest_break = unit(1.1, "grobwidth", textGrob(as.character(names(legend))[longest_break], gp = do.call(gpar, gp)))
		title_length = unit(1.1, "grobwidth", textGrob("Scale", gp = gpar(fontface = "bold", ...)))
		legend_width = unit(12, "bigpts") + longest_break * 1.2
		legend_width = max(title_length, legend_width)
	}
	else{
		legend_width = unit(0, "bigpts")
	}
	
	# Set main title height
	if(is.na(main)){
		main_height = unit(0, "npc")
	}
	else{
		main_height = unit(1.5, "grobheight", textGrob(main, gp = gpar(fontsize = 1.3 * fontsize, ...)))
	}
	
	# Column annotations
	if(!is.na(annotation[[1]][1])){
		# Column annotation height 
		annot_height = unit(ncol(annotation) * (8 + 2) + 2, "bigpts")
		# Width of the correponding legend
		longest_ann = which.max(nchar(as.matrix(annotation)))
		annot_legend_width = unit(1.2, "grobwidth", textGrob(as.matrix(annotation)[longest_ann], gp = gpar(...))) + unit(12, "bigpts")
		if(!annotation_legend){
			annot_legend_width = unit(0, "npc")
		}
	}
	else{
		annot_height = unit(0, "bigpts")
		annot_legend_width = unit(0, "bigpts")
	}
	
	# Tree height
	treeheight_col = unit(treeheight_col, "bigpts") + unit(5, "bigpts")
	treeheight_row = unit(treeheight_row, "bigpts") + unit(5, "bigpts") 
	
	# Set cell sizes
	if(is.na(cellwidth)){
		matwidth = unit(1, "npc") - rown_width - legend_width - treeheight_row - annot_legend_width
	}
	else{
		matwidth = unit(cellwidth * ncol, "bigpts")
	}
	
	if(is.na(cellheight)){
		matheight = unit(1, "npc") - main_height - coln_height - treeheight_col - annot_height
	}
	else{
		matheight = unit(cellheight * nrow, "bigpts")
	}	
	
	
	# Produce layout()
	pushViewport(viewport(layout = grid.layout(nrow = 5, ncol = 5, widths = unit.c(treeheight_row, matwidth, rown_width, legend_width, annot_legend_width), heights = unit.c(main_height, treeheight_col, annot_height, matheight, coln_height)), gp = do.call(gpar, gp)))
	
	# Get cell dimensions
	pushViewport(vplayout(4, 2))
	cellwidth = convertWidth(unit(0:1, "npc"), "bigpts", valueOnly = T)[2] / ncol
	cellheight = convertHeight(unit(0:1, "npc"), "bigpts", valueOnly = T)[2] / nrow
	upViewport()
	
	# Return minimal cell dimension in bigpts to decide if borders are drawn
	mindim = min(cellwidth, cellheight) 
	return(mindim)
}

draw_dendrogram = function(hc, horizontal = T){
	h = hc$height / max(hc$height) / 1.05
	m = hc$merge
	o = hc$order
	n = length(o)

	m[m > 0] = n + m[m > 0] 
	m[m < 0] = abs(m[m < 0])

	dist = matrix(0, nrow = 2 * n - 1, ncol = 2, dimnames = list(NULL, c("x", "y"))) 
	dist[1:n, 1] = 1 / n / 2 + (1 / n) * (match(1:n, o) - 1)

	for(i in 1:nrow(m)){
		dist[n + i, 1] = (dist[m[i, 1], 1] + dist[m[i, 2], 1]) / 2
		dist[n + i, 2] = h[i]
	}
	
	draw_connection = function(x1, x2, y1, y2, y){
		grid.lines(x = c(x1, x1), y = c(y1, y))
		grid.lines(x = c(x2, x2), y = c(y2, y))
		grid.lines(x = c(x1, x2), y = c(y, y))
	}
	
	if(horizontal){
		for(i in 1:nrow(m)){
			draw_connection(dist[m[i, 1], 1], dist[m[i, 2], 1], dist[m[i, 1], 2], dist[m[i, 2], 2], h[i])
		}
	}
	
	else{
		gr = rectGrob()
		pushViewport(viewport(height = unit(1, "grobwidth", gr), width = unit(1, "grobheight", gr), angle = 90))
		dist[, 1] = 1 - dist[, 1] 
		for(i in 1:nrow(m)){
			draw_connection(dist[m[i, 1], 1], dist[m[i, 2], 1], dist[m[i, 1], 2], dist[m[i, 2], 2], h[i])
		}
		upViewport()
	}
}

draw_matrix = function(matrix, border_color, fmat, fontsize_number){
	n = nrow(matrix)
	m = ncol(matrix)
	x = (1:m)/m - 1/2/m
	y = 1 - ((1:n)/n - 1/2/n)
	for(i in 1:m){
		grid.rect(x = x[i], y = y[1:n], width = 1/m, height = 1/n, gp = gpar(fill = matrix[,i], col = border_color))
		if(attr(fmat, "draw")){
			grid.text(x = x[i], y = y[1:n], label = fmat[, i], gp = gpar(col = "grey30", fontsize = fontsize_number))
		}
	}
}

draw_colnames = function(coln, ...){
	m = length(coln)
	x = (1:m)/m - 1/2/m
	grid.text(coln, x = x, y = unit(0.96, "npc"), vjust = 0.5, hjust = 0, rot = 270, gp = gpar(...))
}

draw_rownames = function(rown, ...){
	n = length(rown)
	y = 1 - ((1:n)/n - 1/2/n)
	grid.text(rown, x = unit(0.04, "npc"), y = y, vjust = 0.5, hjust = 0, gp = gpar(...))	
}

draw_legend = function(color, breaks, legend, ...){
	height = min(unit(1, "npc"), unit(150, "bigpts"))
	pushViewport(viewport(x = 0, y = unit(1, "npc"), just = c(0, 1), height = height))
	legend_pos = (legend - min(breaks)) / (max(breaks) - min(breaks))
	breaks = (breaks - min(breaks)) / (max(breaks) - min(breaks))
	h = breaks[-1] - breaks[-length(breaks)]
	grid.rect(x = 0, y = breaks[-length(breaks)], width = unit(10, "bigpts"), height = h, hjust = 0, vjust = 0, gp = gpar(fill = color, col = "#FFFFFF00"))
	grid.text(names(legend), x = unit(12, "bigpts"), y = legend_pos, hjust = 0, gp = gpar(...))
	upViewport()
}

convert_annotations = function(annotation, annotation_colors){
	new = annotation
	for(i in 1:ncol(annotation)){
		a = annotation[, i]
		b = annotation_colors[[colnames(annotation)[i]]]
		if(is.character(a) | is.factor(a)){
			a = as.character(a)
			if(length(setdiff(a, names(b))) > 0){
				stop(sprintf("Factor levels on variable %s do not match with annotation_colors", colnames(annotation)[i]))
			}
			new[, i] = b[a]
		}
		else{
			a = cut(a, breaks = 100)
			new[, i] = colorRampPalette(b)(100)[a]
		}
	}
	return(as.matrix(new))
}

draw_annotations = function(converted_annotations, border_color){
	n = ncol(converted_annotations)
	m = nrow(converted_annotations)
	x = (1:m)/m - 1/2/m
	y = cumsum(rep(8, n)) - 4 + cumsum(rep(2, n))
	for(i in 1:m){
		grid.rect(x = x[i], unit(y[1:n], "bigpts"), width = 1/m, height = unit(8, "bigpts"), gp = gpar(fill = converted_annotations[i, ], col = border_color))
	}
}

draw_annotation_legend = function(annotation, annotation_colors, border_color, ...){
	y = unit(1, "npc")
	text_height = unit(1, "grobheight", textGrob("FGH", gp = gpar(...)))
	for(i in names(annotation_colors)){
		grid.text(i, x = 0, y = y, vjust = 1, hjust = 0, gp = gpar(fontface = "bold", ...))
		y = y - 1.5 * text_height
		if(is.character(annotation[, i]) | is.factor(annotation[, i])){
			for(j in 1:length(annotation_colors[[i]])){
				grid.rect(x = unit(0, "npc"), y = y, hjust = 0, vjust = 1, height = text_height, width = text_height, gp = gpar(col = border_color, fill = annotation_colors[[i]][j]))
				grid.text(names(annotation_colors[[i]])[j], x = text_height * 1.3, y = y, hjust = 0, vjust = 1, gp = gpar(...))
				y = y - 1.5 * text_height
			}
		}
		else{
			yy = y - 4 * text_height + seq(0, 1, 0.02) * 4 * text_height
			h = 4 * text_height * 0.02
			grid.rect(x = unit(0, "npc"), y = yy, hjust = 0, vjust = 1, height = h, width = text_height, gp = gpar(col = "#FFFFFF00", fill = colorRampPalette(annotation_colors[[i]])(50)))
			txt = rev(range(grid.pretty(range(annotation[, i], na.rm = TRUE))))
			yy = y - c(0, 3) * text_height
			grid.text(txt, x = text_height * 1.3, y = yy, hjust = 0, vjust = 1, gp = gpar(...))
			y = y - 4.5 * text_height
		}
		y = y - 1.5 * text_height
	}
}

draw_main = function(text, ...){
	grid.text(text, gp = gpar(fontface = "bold", ...))
}

vplayout = function(x, y){
	return(viewport(layout.pos.row = x, layout.pos.col = y))
}

heatmap_motor = function(matrix, border_color, cellwidth, cellheight, tree_col, tree_row, treeheight_col, treeheight_row, filename, width, height, breaks, color, legend, annotation, annotation_colors, annotation_legend, main, fontsize, fontsize_row, fontsize_col, fmat, fontsize_number, ...){
	grid.newpage()
	
	# Set layout
	mindim = lo(coln = colnames(matrix), rown = rownames(matrix), nrow = nrow(matrix), ncol = ncol(matrix), cellwidth = cellwidth, cellheight = cellheight, treeheight_col = treeheight_col, treeheight_row = treeheight_row, legend = legend, annotation = annotation, annotation_colors = annotation_colors, annotation_legend = annotation_legend, main = main, fontsize = fontsize, fontsize_row = fontsize_row, fontsize_col = fontsize_col,  ...)
	
	if(!is.na(filename)){
		pushViewport(vplayout(1:5, 1:5))
		
		if(is.na(height)){
			height = convertHeight(unit(0:1, "npc"), "inches", valueOnly = T)[2]
		}
		if(is.na(width)){
			width = convertWidth(unit(0:1, "npc"), "inches", valueOnly = T)[2]
		}
		
		# Get file type
		r = regexpr("\\.[a-zA-Z]*$", filename)
		if(r == -1) stop("Improper filename")
		ending = substr(filename, r + 1, r + attr(r, "match.length"))

		f = switch(ending,
			pdf = function(x, ...) pdf(x, ...),
			png = function(x, ...) png(x, units = "in", res = 300, ...),
			jpeg = function(x, ...) jpeg(x, units = "in", res = 300, ...),
			jpg = function(x, ...) jpeg(x, units = "in", res = 300, ...),
			tiff = function(x, ...) tiff(x, units = "in", res = 300, compression = "lzw", ...),
			bmp = function(x, ...) bmp(x, units = "in", res = 300, ...),
			stop("File type should be: pdf, png, bmp, jpg, tiff")
		)
		
		# print(sprintf("height:%f width:%f", height, width))
		f(filename, height = height, width = width)
		heatmap_motor(matrix, cellwidth = cellwidth, cellheight = cellheight, border_color = border_color, tree_col = tree_col, tree_row = tree_row, treeheight_col = treeheight_col, treeheight_row = treeheight_row, breaks = breaks, color = color, legend = legend, annotation = annotation, annotation_colors = annotation_colors, annotation_legend = annotation_legend, filename = NA, main = main, fontsize = fontsize, fontsize_row = fontsize_row, fontsize_col = fontsize_col, fmat = fmat, fontsize_number =  fontsize_number, ...)
		dev.off()
		upViewport()
		return()
	}
	
	# Omit border color if cell size is too small 
	if(mindim < 3) border_color = NA
	
	# Draw title
	if(!is.na(main)){
		pushViewport(vplayout(1, 2))
		draw_main(main, fontsize = 1.3 * fontsize, ...)
		upViewport()
	}
	
	# Draw tree for the columns
	if(!is.na(tree_col[[1]][1]) & treeheight_col != 0){
		pushViewport(vplayout(2, 2))
		draw_dendrogram(tree_col, horizontal = T)
		upViewport()
	}
	
	# Draw tree for the rows
	if(!is.na(tree_row[[1]][1]) & treeheight_row != 0){
		pushViewport(vplayout(4, 1))
		draw_dendrogram(tree_row, horizontal = F)
		upViewport()
	}
	
	# Draw matrix
	pushViewport(vplayout(4, 2))
	draw_matrix(matrix, border_color, fmat, fontsize_number)
	upViewport()
	
	# Draw colnames
	if(length(colnames(matrix)) != 0){
		pushViewport(vplayout(5, 2))
		pars = list(colnames(matrix), fontsize = fontsize_col, ...)
		do.call(draw_colnames, pars)
		upViewport()
	}
	
	# Draw rownames
	if(length(rownames(matrix)) != 0){
		pushViewport(vplayout(4, 3))
		pars = list(rownames(matrix), fontsize = fontsize_row, ...)
		do.call(draw_rownames, pars)
		upViewport()
	}
	
	# Draw annotation tracks
	if(!is.na(annotation[[1]][1])){
		pushViewport(vplayout(3, 2))
		converted_annotation = convert_annotations(annotation, annotation_colors)
		draw_annotations(converted_annotation, border_color)
		upViewport()
	}
	
	# Draw annotation legend
	if(!is.na(annotation[[1]][1]) & annotation_legend){
		if(length(rownames(matrix)) != 0){
			pushViewport(vplayout(4:5, 5))
		}
		else{
			pushViewport(vplayout(3:5, 5))
		}
		draw_annotation_legend(annotation, annotation_colors, border_color, fontsize = fontsize, ...)
		upViewport()
	}
	
	# Draw legend
	if(!is.na(legend[1])){
		length(colnames(matrix))
		if(length(rownames(matrix)) != 0){
			pushViewport(vplayout(4:5, 4))
		}
		else{
			pushViewport(vplayout(3:5, 4))
		}
		draw_legend(color, breaks, legend, fontsize = fontsize, ...)
		upViewport()
	}
	
	
}

generate_breaks = function(x, n, center = F){
	if(center){
		m = max(abs(c(min(x, na.rm = T), max(x, na.rm = T))))
		res = seq(-m, m, length.out = n + 1)
	}
	else{
		res = seq(min(x, na.rm = T), max(x, na.rm = T), length.out = n + 1)
	}
	
	return(res)
}

scale_vec_colours = function(x, col = rainbow(10), breaks = NA){
	return(col[as.numeric(cut(x, breaks = breaks, include.lowest = T))])
}

scale_colours = function(mat, col = rainbow(10), breaks = NA){
	mat = as.matrix(mat)
	return(matrix(scale_vec_colours(as.vector(mat), col = col, breaks = breaks), nrow(mat), ncol(mat), dimnames = list(rownames(mat), colnames(mat))))
}

cluster_mat = function(mat, distance, method){
	if(!(method %in% c("ward", "single", "complete", "average", "mcquitty", "median", "centroid"))){
		stop("clustering method has to one form the list: 'ward', 'single', 'complete', 'average', 'mcquitty', 'median' or 'centroid'.")
	}
	if(!(distance[1] %in% c("correlation", "euclidean", "maximum", "manhattan", "canberra", "binary", "minkowski")) & class(distance) != "dist"){
		print(!(distance[1] %in% c("correlation", "euclidean", "maximum", "manhattan", "canberra", "binary", "minkowski")) | class(distance) != "dist")
		stop("distance has to be a dissimilarity structure as produced by dist or one measure  form the list: 'correlation', 'euclidean', 'maximum', 'manhattan', 'canberra', 'binary', 'minkowski'")
	}
	if(distance[1] == "correlation"){
		d = as.dist(1 - cor(t(mat)))
	}
	else{
		if(class(distance) == "dist"){
			d = distance
		}
		else{
			d = dist(mat, method = distance)
		}
	}
	
	return(hclust(d, method = method))
}

scale_rows = function(x){
	m = apply(x, 1, mean, na.rm = T)
	s = apply(x, 1, sd, na.rm = T)
	return((x - m) / s)
}

scale_mat = function(mat, scale){
	if(!(scale %in% c("none", "row", "column"))){
		stop("scale argument shoud take values: 'none', 'row' or 'column'")
	}
	mat = switch(scale, none = mat, row = scale_rows(mat), column = t(scale_rows(t(mat))))
	return(mat)
}

generate_annotation_colours = function(annotation, annotation_colors, drop){
	if(is.na(annotation_colors)[[1]][1]){
		annotation_colors = list()
	}
	count = 0
	for(i in 1:ncol(annotation)){
		if(is.character(annotation[, i]) | is.factor(annotation[, i])){
			if (is.factor(annotation[, i]) & !drop){
				count = count + length(levels(annotation[, i]))
			}
			else{
				count = count + length(unique(annotation[, i]))
			}
		}
	}
	
	factor_colors = hsv((seq(0, 1, length.out = count + 1)[-1] + 
      0.2)%%1, 0.7, 0.95)
	
	set.seed(3453)
	
	for(i in 1:ncol(annotation)){
		if(!(colnames(annotation)[i] %in% names(annotation_colors))){
			if(is.character(annotation[, i]) | is.factor(annotation[, i])){
				n = length(unique(annotation[, i]))
				if (is.factor(annotation[, i]) & !drop){
					n = length(levels(annotation[, i]))
				}
				ind = sample(1:length(factor_colors), n)
				annotation_colors[[colnames(annotation)[i]]] = factor_colors[ind]
				l = levels(as.factor(annotation[, i]))
				l = l[l %in% unique(annotation[, i])]
				if (is.factor(annotation[, i]) & !drop){
					l = levels(annotation[, i])
				}
				names(annotation_colors[[colnames(annotation)[i]]]) = l
				factor_colors = factor_colors[-ind]
			}
			else{
				r = runif(1)
				annotation_colors[[colnames(annotation)[i]]] = hsv(r, c(0.1, 1), 1)
			}
		}
	}
	return(annotation_colors)
}

kmeans_pheatmap = function(mat, k = min(nrow(mat), 150), sd_limit = NA, ...){
	# Filter data
	if(!is.na(sd_limit)){
		s = apply(mat, 1, sd)
		mat = mat[s > sd_limit, ]	
	}
	
	# Cluster data
	set.seed(1245678)
	km = kmeans(mat, k, iter.max = 100)
	mat2 = km$centers
	
	# Compose rownames
	t = table(km$cluster)
	rownames(mat2) = sprintf("cl%s_size_%d", names(t), t)
	
	# Draw heatmap
	pheatmap(mat2, ...)
}
 
#' A function to draw clustered heatmaps.
#' 
#' A function to draw clustered heatmaps where one has better control over some graphical 
#' parameters such as cell size, etc. 
#' 
#' The function also allows to aggregate the rows using kmeans clustering. This is 
#' advisable if number of rows is so big that R cannot handle their hierarchical 
#' clustering anymore, roughly more than 1000. Instead of showing all the rows 
#' separately one can cluster the rows in advance and show only the cluster centers. 
#' The number of clusters can be tuned with parameter kmeans_k.
#'
#' @param mat numeric matrix of the values to be plotted.
#' @param color vector of colors used in heatmap.
#' @param kmeans_k the number of kmeans clusters to make, if we want to agggregate the 
#' rows before drawing heatmap. If NA then the rows are not aggregated.
#' @param breaks a sequence of numbers that covers the range of values in mat and is one 
#' element longer than color vector. Used for mapping values to colors. Useful, if needed 
#' to map certain values to certain colors, to certain values. If value is NA then the 
#' breaks are calculated automatically.
#' @param border_color color of cell borders on heatmap, use NA if no border should be 
#' drawn.
#' @param cellwidth individual cell width in points. If left as NA, then the values 
#' depend on the size of plotting window.
#' @param cellheight individual cell height in points. If left as NA, 
#' then the values depend on the size of plotting window.
#' @param scale character indicating if the values should be centered and scaled in 
#' either the row direction or the column direction, or none. Corresponding values are 
#' \code{"row"}, \code{"column"} and \code{"none"}
#' @param cluster_rows boolean values determining if rows should be clustered,
#' @param cluster_cols boolean values determining if columns should be clustered.
#' @param clustering_distance_rows distance measure used in clustering rows. Possible 
#' values are \code{"correlation"} for Pearson correlation and all the distances 
#' supported by \code{\link{dist}}, such as \code{"euclidean"}, etc. If the value is none 
#' of the above it is assumed that a distance matrix is provided.
#' @param clustering_distance_cols distance measure used in clustering columns. Possible 
#' values the same as for clustering_distance_rows.
#' @param clustering_method clustering method used. Accepts the same values as 
#' \code{\link{hclust}}.
#' @param treeheight_row the height of a tree for rows, if these are clustered. 
#' Default value 50 points.
#' @param treeheight_col the height of a tree for columns, if these are clustered. 
#' Default value 50 points.
#' @param legend logical to determine if legend should be drawn or not.
#' @param legend_breaks vector of breakpoints for the legend.
#' @param legend_labels vector of labels for the \code{legend_breaks}.
#' @param annotation data frame that specifies the annotations shown on top of the 
#' columns. Each row defines the features for a specific column. The columns in the data 
#' and rows in the annotation are matched using corresponding row and column names. Note 
#' that color schemes takes into account if variable is continuous or discrete.
#' @param annotation_colors list for specifying annotation track colors manually. It is 
#' possible to define the colors for only some of the features. Check examples for 
#' details.
#' @param annotation_legend boolean value showing if the legend for annotation tracks 
#' should be drawn. 
#' @param drop_levels logical to determine if unused levels are also shown in the legend
#' @param show_rownames boolean specifying if column names are be shown.
#' @param show_colnames boolean specifying if column names are be shown.
#' @param main the title of the plot
#' @param fontsize base fontsize for the plot 
#' @param fontsize_row fontsize for rownames (Default: fontsize) 
#' @param fontsize_col fontsize for colnames (Default: fontsize) 
#' @param display_numbers logical determining if the numeric values are also printed to 
#' the cells. 
#' @param number_format format strings (C printf style) of the numbers shown in cells. 
#' For example "\code{\%.2f}" shows 2 decimal places and "\code{\%.1e}" shows exponential 
#' notation (see more in \code{\link{sprintf}}).    
#' @param fontsize_number fontsize of the numbers displayed in cells
#' @param filename file path where to save the picture. Filetype is decided by 
#' the extension in the path. Currently following formats are supported: png, pdf, tiff,
#'  bmp, jpeg. Even if the plot does not fit into the plotting window, the file size is 
#' calculated so that the plot would fit there, unless specified otherwise.
#' @param width manual option for determining the output file width in inches.
#' @param height manual option for determining the output file height in inches.
#' @param \dots graphical parameters for the text used in plot. Parameters passed to 
#' \code{\link{grid.text}}, see \code{\link{gpar}}. 
#' 
#' @return 
#' Invisibly a list of components 
#' \itemize{
#' 	\item \code{tree_row} the clustering of rows as \code{\link{hclust}} object 
#' 	\item \code{tree_col} the clustering of columns as \code{\link{hclust}} object
#' 	\item \code{kmeans} the kmeans clustering of rows if parameter \code{kmeans_k} was 
#' specified 
#' }
#' 
#' @author  Raivo Kolde <rkolde@@gmail.com>
#' @examples
#'  # Generate some data
#' test = matrix(rnorm(200), 20, 10)
#' test[1:10, seq(1, 10, 2)] = test[1:10, seq(1, 10, 2)] + 3
#' test[11:20, seq(2, 10, 2)] = test[11:20, seq(2, 10, 2)] + 2
#' test[15:20, seq(2, 10, 2)] = test[15:20, seq(2, 10, 2)] + 4
#' colnames(test) = paste("Test", 1:10, sep = "")
#' rownames(test) = paste("Gene", 1:20, sep = "")
#' 
#' # Draw heatmaps
#' pheatmap(test)
#' pheatmap(test, kmeans_k = 2)
#' pheatmap(test, scale = "row", clustering_distance_rows = "correlation")
#' pheatmap(test, color = colorRampPalette(c("navy", "white", "firebrick3"))(50))
#' pheatmap(test, cluster_row = FALSE)
#' pheatmap(test, legend = FALSE)
#' pheatmap(test, display_numbers = TRUE)
#' pheatmap(test, display_numbers = TRUE, number_format = "%.1e")
#' pheatmap(test, cluster_row = FALSE, legend_breaks = -1:4, legend_labels = c("0", 
#' "1e-4", "1e-3", "1e-2", "1e-1", "1"))
#' pheatmap(test, cellwidth = 15, cellheight = 12, main = "Example heatmap")
#' pheatmap(test, cellwidth = 15, cellheight = 12, fontsize = 8, filename = "test.pdf")
#' 
#' 
#' # Generate column annotations
#' annotation = data.frame(Var1 = factor(1:10 %% 2 == 0, 
#' 				labels = c("Class1", "Class2")), Var2 = 1:10)
#' annotation$Var1 = factor(annotation$Var1, levels = c("Class1", "Class2", "Class3"))
#' rownames(annotation) = paste("Test", 1:10, sep = "")
#' 
#' pheatmap(test, annotation = annotation)
#' pheatmap(test, annotation = annotation, annotation_legend = FALSE)
#' pheatmap(test, annotation = annotation, annotation_legend = FALSE, drop_levels = FALSE)
#' 
#' # Specify colors
#' Var1 = c("navy", "darkgreen")
#' names(Var1) = c("Class1", "Class2")
#' Var2 = c("lightgreen", "navy")
#' 
#' ann_colors = list(Var1 = Var1, Var2 = Var2)
#' 
#' pheatmap(test, annotation = annotation, annotation_colors = ann_colors, main = "Example")
#' 
#' # Specifying clustering from distance matrix
#' drows = dist(test, method = "minkowski")
#' dcols = dist(t(test), method = "minkowski")
#' pheatmap(test, clustering_distance_rows = drows, clustering_distance_cols = dcols)
#'
#' @export
pheatmap = function(mat, color = colorRampPalette(rev(brewer.pal(n = 7, name = "RdYlBu")))(100), kmeans_k = NA, breaks = NA, border_color = "grey60", cellwidth = NA, cellheight = NA, scale = "none", cluster_rows = TRUE, cluster_cols = TRUE, clustering_distance_rows = "euclidean", clustering_distance_cols = "euclidean", clustering_method = "complete",  treeheight_row = ifelse(cluster_rows, 50, 0), treeheight_col = ifelse(cluster_cols, 50, 0), legend = TRUE, legend_breaks = NA, legend_labels = NA, annotation = NA, annotation_colors = NA, annotation_legend = TRUE, drop_levels = TRUE, show_rownames = T, show_colnames = T, main = NA, fontsize = 10, fontsize_row = fontsize, fontsize_col = fontsize, display_numbers = F, number_format = "%.2f", fontsize_number = 0.8 * fontsize, filename = NA, width = NA, height = NA, ...){
	
	# Preprocess matrix
	mat = as.matrix(mat)
	if(scale != "none"){
		mat = scale_mat(mat, scale)
		if(is.na(breaks)){
			breaks = generate_breaks(mat, length(color), center = T)
		}
	}
	
	
	# Kmeans
	if(!is.na(kmeans_k)){
		# Cluster data
		km = kmeans(mat, kmeans_k, iter.max = 100)
		mat = km$centers

		# Compose rownames
		t = table(km$cluster)
		rownames(mat) = sprintf("cl%s_size_%d", names(t), t)
	}
	else{
		km = NA
	}
	
	# Do clustering
	if(cluster_rows){
		tree_row = cluster_mat(mat, distance = clustering_distance_rows, method = clustering_method)
		mat = mat[tree_row$order, , drop = FALSE]
	}
	else{
		tree_row = NA
		treeheight_row = 0
	}
	
	if(cluster_cols){
		tree_col = cluster_mat(t(mat), distance = clustering_distance_cols, method = clustering_method)
		mat = mat[, tree_col$order, drop = FALSE]
	}
	else{
		tree_col = NA
		treeheight_col = 0
	}
	
	# Format numbers to be displayed in cells 
	if(display_numbers){
		fmat = matrix(sprintf(number_format, mat), nrow = nrow(mat), ncol = ncol(mat))
		attr(fmat, "draw") = TRUE
	}
	else{
		fmat = matrix(NA, nrow = nrow(mat), ncol = ncol(mat))
		attr(fmat, "draw") = FALSE
	}
	
	
	# Colors and scales
	if(!is.na(legend_breaks[1]) & !is.na(legend_labels[1])){
		if(length(legend_breaks) != length(legend_labels)){
			stop("Lengths of legend_breaks and legend_labels must be the same")
		}
	}
	
	
	if(is.na(breaks[1])){
      breaks = generate_breaks(as.vector(mat), length(color))
  }
  if (legend & is.na(legend_breaks[1])) {
      legend = grid.pretty(range(as.vector(breaks)))
			names(legend) = legend
  }
	else if(legend & !is.na(legend_breaks[1])){
		legend = legend_breaks[legend_breaks >= min(breaks) & legend_breaks <= max(breaks)]
		
		if(!is.na(legend_labels[1])){
			legend_labels = legend_labels[legend_breaks >= min(breaks) & legend_breaks <= max(breaks)]
			names(legend) = legend_labels
		}
		else{
			names(legend) = legend
		}
	}
  else {
      legend = NA
  }
	mat = scale_colours(mat, col = color, breaks = breaks)
	
	# Preparing annotation colors
	if(!is.na(annotation[[1]][1])){
		annotation = annotation[colnames(mat), , drop = F]
		annotation_colors = generate_annotation_colours(annotation, annotation_colors, drop = drop_levels)
	}
	
	if(!show_rownames){
		rownames(mat) = NULL
	}
	
	if(!show_colnames){
		colnames(mat) = NULL
	}
	
	# Draw heatmap
	heatmap_motor(mat, border_color = border_color, cellwidth = cellwidth, cellheight = cellheight, treeheight_col = treeheight_col, treeheight_row = treeheight_row, tree_col = tree_col, tree_row = tree_row, filename = filename, width = width, height = height, breaks = breaks, color = color, legend = legend, annotation = annotation, annotation_colors = annotation_colors, annotation_legend = annotation_legend, main = main, fontsize = fontsize, fontsize_row = fontsize_row, fontsize_col = fontsize_col, fmat = fmat, fontsize_number = fontsize_number, ...)
	
	invisible(list(tree_row = tree_row, tree_col = tree_col, kmeans = km))
}

#------------------------------------------------------------------------------
# original pheatmap 0.7.7 end
#------------------------------------------------------------------------------

draw_matrix = function(
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

#assignInNamespace(
#	x="draw_matrix",
#	value=draw_matrix_my,
#	ns=asNamespace("pheatmap")
#)

draw_colnames = function(coln, ...){
	m = length(coln)
	x = (1:m)/m - 1/2/m
	grid.text(coln, x = x, y = unit(0.96, "npc"), vjust = 0.5, hjust = 1, rot = 90, gp = gpar(...))
}

#assignInNamespace(
#	x="draw_colnames",
#	value=draw_colnames_my,
#	ns=asNamespace("pheatmap")
#)

cluster_mat = function(mat, distance, method){
	d = dist(mat, method = "euclid")
	#library(proxy)
	#d <- proxy::dist(mat, method = "correlation")
	
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

#assignInNamespace(
#	x="cluster_mat",
#	value=cluster_mat_my,
#	ns=asNamespace("pheatmap")
#)


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
		number_format            = ifelse(topic_model==1, "%.3f", "%.1f"),
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

EndOfPHeatmap
	return $t0.$t1;
}

1;