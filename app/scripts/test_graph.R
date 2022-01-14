install.packages('igraph')
install.packages('visNetwork')

nodes <- read.csv(file = 'downloads/nodes.csv', header=T, as.is=T)
links <- read.csv(file = 'downloads/edges.csv', header=T, as.is=T)

head(nodes)
head(links)

#igraph network
library('igraph')
net <- graph_from_data_frame(d=links, vertices=nodes, directed=T) 

V(net)$label <- NA
V(net)$size <- V(net)$pip.score*20
V(net)$color <- "orange"
V(net)$frame.color <- "#ffffff"
V(net)$label.degree <- “pi/2”
V(net)$label.color <- "black"

colrs <- c("dark red", "slategrey")
E(net)$color <- c("dark red", "slategrey")[(E(net)$type=="activate")+1]
E(net)$arrow.size <- .3
E(net)$curved <- 0.5
E(net)$width <- 1.3

plot(net, layout=layout_in_circle)
legend('bottomleft', c("Activate", "Repress"), pch=21,
       col="#777777", pt.bg=colrs, pt.cex=2, cex=.8, bty="n", ncol=1)

#interactive network
library(visNetwork)

vis.nodes <- nodes
vis.links <- links

vis.nodes$title  <- vis.nodes$gene.number
vis.nodes$size   <- vis.nodes$pip.score*15
visNetwork(vis.nodes, vis.links, width="100%", height="400px")

