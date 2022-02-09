#install.packages('visNetwork')
library(visNetwork)

#create node dataframe

default_graph <- function(){
  gene_file <- read.csv(file = './data/gene_list.csv', header=T, as.is=T)
  cpg_file <- read.csv(file = './data/cpg_list.csv', header=T, as.is=T)
  bed_file <- read.csv(file = './data/gene_to_cpg_map.csv', header=T, as.is=T)
  
  gene_list <- as.data.frame(gene_file, stringsAsFactors = FALSE)
  cpg_list <- as.data.frame(cpg_file, stringsAsFactors = FALSE)
  mapping <- as.data.frame(bed_file, stringsAsFactors = FALSE)
  
  gene_list['group'] = 'a'
  cpg_list['group'] = 'b'
  
  gene_palette <- colorRampPalette(c("lightblue", "steelblue4"))
  gene_list$color <- gene_palette(length(gene_list))[as.numeric(cut(gene_list$feature, breaks = length(gene_list)))]
  
  cpg_palette <- colorRampPalette(c("yellow2","goldenrod","darkred"))
  cpg_list$color <- cpg_palette(length(cpg_list))[as.numeric(cut(cpg_list$feature, breaks = length(cpg_list)))]
  
  nodes <- rbind(gene_list, cpg_list)
  
  nodes$feature <- as.numeric(nodes$feature)
  is.numeric(nodes$feature)
  
  #create edge list
  gene_col <- gene_list$id
  rownumber = 1
  len = length(gene_col)
  iterations = len*(len-1)/2
  gene_edges <- matrix(nrow = iterations, ncol = 2)
  
  for (i in 1:(len-1)) 
  {
    val <- gene_col[i]
    for (j in 1:(len-i)) 
    { 
      val2 <- gene_col[j+i]
      gene_edges[rownumber, 1] = val
      gene_edges[rownumber, 2] = val2
      rownumber = rownumber + 1
    }
  }
  edge_list <- as.data.frame(gene_edges)
  colnames(edge_list) <- c('from', 'to')
  edges <- rbind(edge_list, mapping)
  
  #assign node and edges attributes for default graph
  nodes$size <- nodes$feature*30
  edges$color <- "black"
  
  #default graph
  visNetwork(nodes, edges) %>%
    visIgraphLayout(layout = "layout_with_kk") %>%
    visOptions(highlightNearest = list(enabled =TRUE, degree = 2, hover = T), nodesIdSelection = TRUE, selectedBy = list(variable = "group", highlight = TRUE),
               manipulation = TRUE)%>%
    visEdges(hoverWidth = 3, selectionWidth = 3) %>%
    visNodes(label = NULL, labelHighlightBold = TRUE, borderWidthSelected = 4) %>%
    visGroups(groupname = "a", color = "orange", shape = "circle") %>%
    visGroups(groupname = "b", color = "blue", shape = "triangle") 
}

# Function to plot color bar
#color.bar <- function(lut, min, max, nticks=11, ticks=seq(min, max, len=nticks), title='') {
  #scale = (length(lut)-1)/(max-min)
  
 # dev.new(width=1, height=5)
 # plot(c(0,10), c(min,max), type='n', bty='n', xaxt='n', xlab='', yaxt='n', ylab='', main=title)
  #axis(2, ticks, las=1)
  #for (i in 1:(length(lut)-1)) {
  #  y = (i-1)/scale + min
 #   rect(0,y,10,y+1/scale, col=lut[i], border=NA)
 # }
#}
#color.bar(colorRampPalette(c("yellow2","goldenrod","darkred"))(100), 0, 1)

#color.bar(colorRampPalette(c("lightblue", "steelblue4"))(100), 0, 1)

#SUBGRAPH
#create nodes dataframe for subgraph
subgraph <- function(thres){
  gene_file <- read.csv(file = './data/gene_list.csv', header=T, as.is=T)
  cpg_file <- read.csv(file = './data/cpg_list.csv', header=T, as.is=T)
  bed_file <- read.csv(file = './data/gene_to_cpg_map.csv', header=T, as.is=T)
  
  gene_list <- as.data.frame(gene_file, stringsAsFactors = FALSE)
  cpg_list <- as.data.frame(cpg_file, stringsAsFactors = FALSE)
  mapping <- as.data.frame(bed_file, stringsAsFactors = FALSE)
  
  gene_list2 <- data.frame(matrix(ncol = 5))
  k = 1
  for (i in 1:length(gene_list$id))
  {
    if (gene_list$feature[i] > thres)
    {
      gene_list2[k, ] <- gene_list[i, ]
      k = k+1
    }
  }
  colnames(gene_list2) <- c('feature', 'id', 'group', 'color', 'size')
  
  cpg_list2 <- data.frame(matrix(ncol = 5))
  k = 1
  for (i in 1:length(cpg_list$id))
  {
    if (cpg_list$feature[i] > thres)
    {
      cpg_list2[k, ] <- cpg_list[i, ]
      k = k+1
    }
  }
  colnames(cpg_list2) <- c('feature', 'id', 'group', 'color', 'size')
  nodes2 <- rbind(gene_list2, cpg_list2)
  
  #create edgelist2
  genes2 <- gene_list2$id
  rownumber2 = 1
  len2 = length(genes2)
  iterations2 = len2*(len2-1)/2
  edgelist2 <- matrix(nrow = iterations2, ncol = 2)
  
  for (i in 1:(len2-1)) 
  {
    val <- genes2[i]
    for (j in 1:(len2-i)) 
    { 
      val2 <- genes2[j+i]
      edgelist2[rownumber2, 1] = val
      edgelist2[rownumber2, 2] = val2
      rownumber2 = rownumber2 + 1
    }
  }
  
  edgelist2 = as.data.frame(edgelist2)
  colnames(edgelist2) = c("from", "to")
  
  # create bed file for 
  for (i in 1: nrow(mapping))
  {
    if ((mapping[i, 1] %in% gene_list2$id) & (mapping[i, 2] %in% cpg_list2$id))
    {
      edgelist2 = rbind(edgelist2, mapping[i,])
    }
  }
  
  visNetwork(nodes2, edgelist2) %>%
    visIgraphLayout(layout = "layout_with_kk") %>%
    visOptions(highlightNearest = list(enabled =TRUE, degree = 2, hover = T), nodesIdSelection = TRUE, selectedBy = list(variable = "group", highlight = TRUE),
               manipulation = TRUE)%>%
    visEdges(hoverWidth = 3, selectionWidth = 3) %>%
    visNodes(label = NULL, labelHighlightBold = TRUE, borderWidthSelected = 4) %>%
    visGroups(groupname = "a", color = "orange", shape = "circle") %>%
    visGroups(groupname = "b", color = "blue", shape = "triangle") 
}