d <- t(d)

library(vegan)                                    # Run MDS
c <- metaMDS( dist(d, method="binary"), k=2 )

plot(c$points, bty="l", pch=20, col="gray60")     # Plot only dots

library(maptools)                                 # Plot labels
pointLabel(
  x = c$points[,1],
  y = c$points[,2],
  labels = rownames(c$points),
)
