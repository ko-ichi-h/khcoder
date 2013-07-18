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



library(ggplot2)
#ggfluctuation( as.table( t( as.matrix(d) ) ) )



ggfluctuation_my <- function (
	table, type = "size", floor = 0, ceiling = max(table$freq, na.rm = TRUE)
){
    if (is.table(table)) 
        table <- as.data.frame(t(table))
    oldnames <- names(table)
    names(table) <- c("x", "y", "result")
    table <- add.all.combinations(table, list("x", "y"))
    table <- transform(table, x = as.factor(x), y = as.factor(y), 
        freq = result)
    if (type == "size") {
        table <- transform(
        	table,
        	freq = sqrt(pmin(freq, ceiling)/ceiling),
            border = ifelse(
            	is.na(freq),
            	"grey90",
            	ifelse(freq > ceiling, "grey30", "grey50")
            )
        )
        table[is.na(table$freq), "freq"] <- 1
        table <- subset(table, freq * ceiling >= floor)
    }
    if (type == "size") {
    	#print (table)
        nx <- length(levels(table$x))
        ny <- length(levels(table$y))
        p <- ggplot(
        		table,
        		aes_string(
        			x = "x",
        			y = "y",
        			size = "result",
        			width = "freq",
        			height = "freq"
        			#fill = "result"
        			#fill = "border"
        		)
        	)
        #p <- p + geom_tile(color = "white", fill="gray50")
        
        bt <- floor( floor(max(table$result)) / 3 )
        breaks <- c(bt, 2 * bt, 3 * bt)
        
        p <- p + geom_point(shape=22,fill="gray50",colour="white")
        p <- p + scale_area(
        	"Percent:",
        	limits = c(1, ceiling(max(table$result))),
        	to=c(0,8),
        	breaks = breaks
        )
        p <- p + xlab("")
        p <- p + ylab("")
        p <- p + opts(
        		aspect.ratio = ny/nx,
        		axis.text.x=theme_text(angle=90, hjust=1),
        		axis.text.y=theme_text(hjust=1)
        	)
        print(p)
    }
    else {
        p <- ggplot(table, aes_string(x = "x", y = "y", fill = "freq")) + 
            geom_tile(colour = "grey50") + scale_fill_gradient2(low = "white", 
            high = "darkgreen")
    }
    #p$xlabel <- oldnames[1]
    #p$ylabel <- oldnames[2]
    #print(p)
}

ggfluctuation_my( as.table( t( as.matrix(d) ) ) )