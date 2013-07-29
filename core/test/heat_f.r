savefile <- NULL
require(tcltk)

if (T){
	csvfile <- tclvalue(
		tkgetOpenFile(
			filetypes = "{{CSV Files} {.csv}}",
			defaultextension=".csv"
		)
	)
	d <- read.csv(csvfile, header=T, sep = ",", row.names=1)
}

d <- as.matrix(d)
rownames(d)[2] <- "ãEˆê";

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
		to=c(0,50),
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
		aspect.ratio = ny/nx,
		axis.text.x=theme_text(angle=90, hjust=1, family=font_fam),
		axis.text.y=theme_text(hjust=1, family=font_fam)
	)

	print(p)

}

ggfluctuation_my( t( as.matrix(d) ) ) 