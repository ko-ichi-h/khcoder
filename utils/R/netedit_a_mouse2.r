# 微調整したTkプロットのレイアウトを画面上のプロットに反映させる

library(Cairo)
CairoWin(width=12, height=9, dpi=72)


lay_f <- tkplot.getcoords(tkid)

lay_f <- scale(lay_f,center=T, scale=F)
for (i in 1:2){
	lay_f[,i] <- lay_f[,i] - min(lay_f[,i]); # 最小を0に
	lay_f[,i] <- lay_f[,i] / max(lay_f[,i]); # 最大を1に
	lay_f[,i] <- ( lay_f[,i] - 0.5 ) * 1.96;
}
#lay_f[,2] <- lay_f[,2] * -1

#-------------------------------------------------------#
#  get ready for ggplot2 graph drawing (2): parameters  #

library(ggplot2)
library(ggnetwork)

p <- ggplot(
	ggnetwork(n2, layout=lay_f),
	aes(x = x, y = y, xend = xend, yend = yend),
)

if (use_alpha == 1){
	alpha_value = 0.62
	gray_color_n <- "gray20"
} else {
	alpha_value = 1
	gray_color_n <- "gray40"

}

if (text_font == 2){
	face <- "bold"
} else {
	face <- "plain"
}
if (smaller_nodes == 1 ){
	edge_colour <- "gray68"
	nudge <- 0.015
	hjust <- "left"
} else {
	edge_colour <- "gray55"
	nudge <- 0
	hjust <- "center"
}

if (com_method == "twomode_c"){
	edge_colour <- "gray70"
}

if (com_method == "none" || com_method == "twomode_g"){
	edge_colour <- "gray40"
	gray_color_n <- "black"
}

rownames(lay_f) <- colnames(d)[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ]
lay_f[,1] <- lay_f[,1] - min(lay_f[,1])
lay_f[,1] <- lay_f[,1] / max(lay_f[,1])
lay_f[,2] <- lay_f[,2] - min(lay_f[,2])
lay_f[,2] <- lay_f[,2] / max(lay_f[,2])
lay_f_df <- data.frame(
	x = lay_f[,1],
	y = lay_f[,2],
	lab = rownames(lay_f)
)

if ( smaller_nodes == 1 ){
	vv <- 6.2
} else {
	vv <- 20
}

sans <- "sans"
if ( exists("saving_eps") ){
	sans <- NULL
}

#-----------------------------------------------------------------------------#
#                           Start Plotting with ggplot2                       #

#---------#
#  Edges  #

if (com_method == "cor"){ # cor

	if ( gray_scale == 1) {
		myPalette <- gray( seq(1, 0, length.out=100) )
		gray_color_n <- "black"
		if (alpha_value < 0.8) {
			alpha_value <- 0.8
		}
		p <- p + geom_edges(
			color = "black",
			size = 1.5
		)
		p <- p + geom_edges(
			aes(
				color = edge_pos
			),
			size = 1,
		)
	} else {
		myPalette <- colorRampPalette(
			rev( brewer.pal(9, "RdYlBu") )
		)(100) #Spectral
		p <- p + geom_edges(
			aes(
				color = edge_pos
			),
			size = 0.6,
		)
	}

	p <- p + scale_color_gradientn(
		colours = myPalette,
		#limits = c( min(edge_pos), limv ),
		#limits = c( 0 - limv, 0 + limv ),
		guide = guide_colourbar(
			title = "Correlation:\n",
			title.theme = element_text(
				family=sans,
				face="bold",
				size=11,
				lineheight=0.4,
				angle=0
			),
			order = 1,
			#override.aes = list(size=6, shape=22),
			label.hjust = 1,
			#reverse = TRUE,
			#ncol=2,
			#keyheight = unit(1.5,"line")
		)
	)
	p <- p + scale_fill_gradientn(
		colours = myPalette,
		guide = FALSE
	)
} else if (min_sp_tree == 1){
	edg_col2 <- p$data$edg_col
	edg_col2[edg_col2=="gray30"] <- "MST"
	edg_col2[edg_col2=="gray55"] <- "non-MST"
	edg_col2[edg_col2=="gray70"] <- "non-MST"
	p <- p + geom_edges(
		aes(linetype = as.character(line), alpha=edg_col2),
		#size = 0.8,
		color = "grey10"
	)
	p <- p + scale_alpha_discrete(
		range = c(1, 0.3),
		guide = guide_legend(
			title = "Edge:",
			keyheight = unit(1.2,"line"),
			order = 2
		)
	)
} else if ( use_weight_as_width == 1 ){
	p <- p + geom_edges(
		aes(linetype = as.character(line), alpha=weight),
		#size = 0.8,
		color = "grey10"
	)
	p <- p + scale_alpha(
		range = c(0.2, 1),
		guide = guide_legend(
			title = "Coefficient:",
			label.hjust = 1,
			keyheight = unit(1.2,"line"),
			order = 2
		)
	)
} else {
	p <- p + geom_edges(
		aes(linetype = as.character(line)),
		size = 0.4,
		color = edge_colour
	)
}

p <- p + scale_linetype_identity()

#---------#
#  Nodes  #

# words

p <- p + geom_nodes(
	aes(
		size = size * 0.41,
		color = com
	),
	alpha = 0.85,
	show.legend = F,
	shape = 16
)
p <- p + geom_nodes(
	aes(
		size = size,
		color = com,
		shape = shape
	),
	alpha = alpha_value,
	shape = 16
)
p <- p + geom_nodes(
	aes(
		size = size,
		shape = shape
	),
	colour = gray_color_n,
	show.legend = F,
	alpha = alpha_value,
	shape = 1
)
p <- p + geom_nodes( # dummy for the legend
	aes( fill = com ),
	size=0,
	colour = gray_color_n,
	alpha = 0,
	shape = 21
)

if ( use_freq_as_size == 1 ){
	# bubble plot legend configuration
	limits_a <- c(NA, NA);
	if (is.null(breaks)){
		breaks <- labeling::extended(
			min(ver_freq, na.rm=T),
			max(ver_freq, na.rm=T),
			5
		)
		breaks_a <- NULL
		for ( i in 1:length(breaks) ){
			if (
				   min(ver_freq, na.rm=T) <= breaks[i]
				&& max(ver_freq, na.rm=T) >= breaks[i]
			){
				breaks_a <- c(breaks_a, breaks[i])
			}
		}
		breaks <- breaks_a
	} else {
		breaks_a <- breaks
		if (  min(breaks) < min(ver_freq, na.rm=T) ){
			limits_a[1] <- min(breaks)
		}
		if (  max(breaks) > max(ver_freq, na.rm=T) ){
			limits_a[2] <- max(breaks)
		}
	}

	# bubble size configuration
	if ( exists("bs_fixed") == F ) {
		bubble_size <- bubble_size / font_size
		bs_fixed <- 1
	}

	p <- p + scale_size_area(
		"Frequency",
		max_size = 30 * bubble_size / 100,
		breaks = breaks_a,
		limits = limits_a,
		guide = guide_legend(
			title = "Frequency:",
			override.aes = list(colour="black", alpha=1, shape=1),
			label.hjust = 1,
			order = 3
		)
	)
} else {
	p <- p + scale_size_area(
		max_size = vv,
		guide = F
	)
}

# variables

if ( (com_method == "twomode_c" || com_method == "twomode_g") ) {
	# (is.null(target_ids) == FALSE)

	if ( com_method == "twomode_c" ){
		var_outline_c <- "gray50"
		var_fill_c <- "#FB8072"
	}
	if ( com_method == "twomode_g" ){
		var_outline_c <- "black"
		var_fill_c <- "white"
	}
	
	p <- p + geom_point(
		data = data.frame(
			x = lay_f[var_select,1],
			y = lay_f[var_select,2]
		),
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y
		),
		fill = var_fill_c,
		show.legend = F,
		colour = NA,
		alpha = 0.8,
		size = vv * 2 / 3,
		shape = 22
	)
	
	p <- p + geom_point(
		data = data.frame(
			x = lay_f[var_select,1],
			y = lay_f[var_select,2]
		),
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y
		),
		fill = var_fill_c,
		show.legend = F,
		colour = var_outline_c,
		alpha = alpha_value,
		size = vv,
		shape = 22
	)
}

# selected words

if ( (is.null(target_ids) == FALSE) ) {
	var_select <- target_ids

	p <- p + geom_point(
		data = data.frame(
			x = lay_f[var_select,1],
			y = lay_f[var_select,2]
		),
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y,
			fill = com_label[var_select]
		),
		show.legend = F,
		colour = NA,
		alpha = 0.8,
		size = vv * 2 / 3,
		shape = 22
	)
	
	p <- p + geom_point(
		data = data.frame(
			x = lay_f[var_select,1],
			y = lay_f[var_select,2]
		),
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y,
			fill = com_label[var_select]
		),
		show.legend = F,
		colour = gray_color_n,
		alpha = alpha_value,
		size = vv,
		shape = 22
	)
	
	p <- p + geom_point(
		data = data.frame(
			x = lay_f[var_select,1],
			y = lay_f[var_select,2]
		),
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y
		),
		fill = NA,
		show.legend = F,
		colour = gray_color_n,
		alpha = alpha_value,
		size = vv * 1.4,
		shape = 22
	)
}

#---------------#
#  Node labels  #

#if ( (use_freq_as_fontsize == 1) && (use_freq_as_size == 1) ) {
#	p <- p + geom_nodetext(
#		aes(label = lab, size=size * 0.1),
#		show.legend = F,
#		family="Meiryo UI",
#		fontface=face
#	)
#}

if (
	( com_method == "com-b" || com_method == "com-g" || com_method == "com-r" || com_method == "cor")
	&& gray_scale == 1
	&& smaller_nodes == 0
){
	p <- p + geom_label(
		data = lay_f_df,
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y,
			label = lab
		),
		size=4,
		hjust = hjust,
		nudge_x = nudge,
		nudge_y = nudge * 1.25,
		family=font_fam,
		na.rm = T,
		label.size = NA,
		label.padding = unit(0.2, "lines"),
		label.r = unit(0.1, "lines"),
		fontface=face
	)
} else {
	p <- p + geom_text(
		data = lay_f_df,
		aes(
			x = x,
			y = y,
			xend = x,
			yend = y,
			label = lab
		),
		size=4,
		hjust = hjust,
		nudge_x = nudge,
		nudge_y = nudge * 1.25,
		family=font_fam,
		na.rm = T,
		fontface=face
	)
}

#---------------#
#  Edge labels  #

if (view_coef == 1){
	p <- p + geom_edgetext(
		aes(label = substring( round(weight, digits = 2), 2, 4) ),
		color = "#000080",
		fill = NA,
		size=3.5,
	)
}

#-------------------#
#  Community color  #

if ( com_method == "com-b" || com_method == "com-g" || com_method == "com-r"){
	if ( gray_scale == 1) {
		p <- p + scale_color_grey(
			na.value = "white",
			guide = FALSE
		)
		p <- p + scale_fill_grey(
			na.value = "white",
			guide = guide_legend(
				title = "Subgraph:",
				override.aes = list(size=5.5, alpha=1, shape=22),
				keyheight = unit(1,"line"),
				ncol=2,
				order = 1
			)
		)
	} else {
		if ( length(table(igraph::get.vertex.attribute(n2, "com"))) <= 12 ){
			p <- p + scale_color_brewer(
				palette = "Set3",
				na.value = "white",
				guide = FALSE
			)
			p <- p + scale_fill_brewer(
				palette = "Set3",
				na.value = "white",
				guide = guide_legend(
					title = "Subgraph:",
					override.aes = list(size=5.5, alpha=1, shape=22),
					keyheight = unit(1.25,"line"),
					ncol=2,
					order = 1
				)
			)
		} else if (length(table(igraph::get.vertex.attribute(n2, "com"))) <= 20){
			library(ggsci)
			c20org <- col2rgb( pal_d3("category20")(20) )

			p <- p + scale_color_manual(
				values = rgb( t( ( 255 - ( 255 - c20org ) * 0.5 ) / 255  ) ),
				na.value = "white",
				guide = FALSE
			)
			p <- p + scale_fill_manual(
				values = rgb( t( ( 255 - ( 255 - c20org ) * 0.5 ) / 255  ) ),
				na.value = "white",
				guide = guide_legend(
					title = "Community:",
					override.aes = list(size=5.5, alpha=1, shape=22),
					keyheight = unit(1.25,"line"),
					ncol=2,
					order = 1
				)
			)
		} else {
			p <- p + scale_color_hue(
				c = 50,
				l = 85,
				na.value = "white",
				guide = FALSE
			)
			p <- p + scale_fill_hue(
				c = 50,
				l = 85,
				na.value = "white",
				guide = guide_legend(
					title = "Community:",
					override.aes = list(size=5.5, alpha=1, shape=22, colour="gray45"),
					keyheight = unit(1.25,"line"),
					ncol=2,
					order = 1
				)
			)
		}
	}
}

#--------------------#
#  Centrality color  #

if ( com_method == "cnt-b" || com_method == "cnt-d" || com_method == "cnt-e"){
	
	if (gray_scale == 1){
		myPalette <- gray( seq(1, 0.4, length.out=100) )
	} else {
		if (color_universal_design == 0){
			myPalette <- cm.colors(99)
		} else {
			library(RColorBrewer)
			col_seed <- brewer.pal(8,"YlGnBu")[1:6]

			myPalette <- colorRampPalette( col_seed )
			myPalette <- myPalette(99)
		}
	}

	p <- p + scale_color_gradientn(
		colours = myPalette,
		guide = FALSE
	)
	p <- p + scale_fill_gradientn(
		colours = myPalette,
		guide = guide_colourbar(
			title = "Centrality:\n",
			title.theme = element_text(
				family=sans,
				face="bold",
				size=11,
				lineheight=0.4,
				angle=0
			),
			order = 1,
			#override.aes = list(size=6, shape=22),
			label.hjust = 1,
			#reverse = TRUE,
			#ncol=2,
			#keyheight = unit(1.5,"line")
		)
	)
}

#----------------#
#  2 Mode color  #

if (com_method == "twomode_c"){
	p <- p + scale_color_manual(
		values = brewer.pal(8, "Spectral")[4:8],
		guide = FALSE
	)
	p <- p + scale_fill_manual(
		values = brewer.pal(8, "Spectral")[4:8],
		guide = guide_legend(
			title = "Degree:",
			order = 1,
			override.aes = list(size=5.5, shape=22, alpha=1),
			#label.hjust = "left",
			#reverse = TRUE,
			#ncol=2,
			keyheight = unit(1.2,"line")
		)
	)
}

if ( com_method == "none" || com_method == "twomode_g"){
	p <- p + scale_color_manual(
		values = c("white"),
		na.value = "white",
		guide = F
	)
	p <- p + scale_fill_manual(
		values = c("white"),
		na.value = "white",
		guide = F
	)
}

#---------------------#
#  Final adjustments  #

p <- p + theme_blank(
	base_family  = font_fam
)

if (com_method == "cor" && gray_scale == 0){ # cor
	if ( cor_var_darker == 1 ){
		col_backg <- "gray50"
	} else {
		col_backg <- "gray60"
	}
	p <- p + theme(
		panel.background = element_rect(fill = col_backg, colour = NA)
	)
}

p <- p + theme(
	legend.title    = element_text(family=sans, face="bold",  size=11, angle=0),
	legend.text     = element_text(face="plain", size=11, angle=0)
)


# make a small space between the graph and the legend

if ( exists("margin_top") == F ){
	margin_top <- 0
}
if ( exists("margin_bottom") == F ){
	margin_bottom <- 0
}
if ( exists("margin_left") == F ){
	margin_top <- 0
}
if ( exists("margin_right") == F ){
	margin_top <- 0
}

margin <- 0.04
extra  <- 0.025

m_t <- margin_top    / 100
m_b <- margin_bottom / 100
m_l <- margin_left   / 100
m_r <- margin_right  / 100

xlimv <- c(0-margin-extra-m_l, 1+margin+extra+m_r)
ylimv <- c(0-margin-m_b, 1+margin+m_t)

p <- p + coord_fixed(
	ratio = 1,
	expand = F,
	xlim = xlimv,
	ylim = ylimv
)

g <- ggplotGrob(p)

if ( length( g$grobs[[8]][[1]][[1]] ) > 1){
	if ( 
		(com_method == "cnt-b" || com_method == "cnt-d" || com_method == "cnt-e")
		&& ( gray_scale == 0 )
	){
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$col <- "gray45"
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$lwd <- 1.25
	}
	if ( 
		(com_method == "cnt-b" || com_method == "cnt-d" || com_method == "cnt-e")
		&& ( gray_scale == 1 )
	){
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$col <- "gray30"
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$lwd <- 1.25
	}
	if ( com_method == "cor" && gray_scale == 0){
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$col <- "gray40"
		g$grobs[[8]][[1]][[1]]$grobs[[5]]$gp$lwd <- 1.1
	}
}

library(grid)
library(gtable)

# fixing width of legends to 22%
if ( exists("saving_file") ){
	if ( saving_file == 0){
		target_legend_width <- convertX(
			unit( image_width * 0.22, "in" ),
			"mm"
		)
		if ( as.numeric( substr( packageVersion("ggplot2"), 1, 3) ) <= 2.1 ){ # ggplot2 <= 2.1.0
			diff_mm <- diff( c(
				convertX( g$widths[5], "mm" ),
				target_legend_width
			))
			if ( diff_mm > 0 ){
				print(diff_mm)
				g <- gtable_add_cols(g, unit(diff_mm, "mm"))
			}
		} else { # ggplot2 >= 2.2.0
			
			diff_mm <- diff( c(
				convertX( g$widths[7], "mm", valueOnly=T ) + convertX( g$widths[8], "mm", valueOnly=T ),
				target_legend_width
			))
			if ( diff_mm > 0 ){
				print(diff_mm)
				g <- gtable_add_cols(g, unit(diff_mm, "mm"))
			}
		}
	}
}

grid.draw(g)