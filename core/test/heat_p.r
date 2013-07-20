dendro_c <- 1
cellnote <- 0
dendro_v <- 0

if (T) {
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

library(RColorBrewer)
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

cexcol <- 9
if ( length(col.labels) > 35 && (dendro_v == 1)){
	#cexcol <- 0.2 + 1/log10( length(col.labels) * 5)
	cexcol <- 2 + 8 * 30 / length(col.labels)
}

library(grid)
library(pheatmap)

# https://github.com/raivokolde/pheatmap/blob/master/R/pheatmap.r
# http://stackoverflow.com/questions/15505607/diagonal-labels-orientation-on-x-axis-in-heatmaps
# http://www.okada.jp.org/RWiki/?grid%20%A5%D1%A5%C3%A5%B1%A1%BC%A5%B8%BB%F6%BB%CF

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
			height = 1/n,
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
	
	# 行と行を白線で区切る
	for (i in 1:(n-1)){
		grid.segments(
			x0=x[1] - 0.5/m,
			y0=y[i] - 0.5/n,
			x1=x[m] + 0.5/m,
			y1=y[i] - 0.5/n,
			gp = gpar(col="white",lwd=6),
		)
	}

}

assignInNamespace(
	x="draw_matrix",
	value=draw_matrix_my,
	ns=asNamespace("pheatmap")
)

pheatmap(
	t(d),
	color=colors,
	drop_levels=T,
	fontsize_col=cexcol,
	border_color=NA,
	cluster_cols=ifelse(dendro_v==1, T, F),
	cluster_rows=ifelse(dendro_c==1, T, F),
	display_numbers=ifelse(cellnote==1, T, F),
	number_format = "%.1f",
	legend=ifelse(cellnote==1, F, T),
	fontsize_number=10,
	clustering_distance_rows = "euclidean",
	clustering_method        = "ward",
)

