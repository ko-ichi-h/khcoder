d <- t(d)

library(vegan)                                    # MDSの実行
c <- metaMDS( dist(d, method="binary"), k=2 )

plot(c$points, bty="l", pch=20, col="gray60")     # ドットを描画

library(maptools)                                 # ラベルが重ならないように
pointLabel(                                       # 調整してから描画
  x = c$points[,1],
  y = c$points[,2],
  labels = rownames(c$points),
)
