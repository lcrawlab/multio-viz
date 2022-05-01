library(visNetwork)

make_graph <- function(n, e){
  visNetwork(n, e) %>%
    visNodes(label = "id", size = 20, shadow = list(enabled = TRUE, size = 10)) %>%
    visLayout(randomSeed = 12) %>%
    visIgraphLayout(input$layout) %>% 
    visOptions(highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
    visGroups(groupname = "a", shape = "circle") %>%
    visGroups(groupname = "b", shape = "triangle") %>%
    visEvents(doubleClick = "function(nodes) {
                   Shiny.onInputChange('click', nodes.nodes[0]);
                   }")
}

make_nodes <- function(ml1, ml2, pip){

  df_mol_lev_1 <- as.data.frame(ml1, stringsAsFactors = FALSE)
  df_mol_lev_2 <- as.data.frame(ml2, stringsAsFactors = FALSE)
  
  df_mol_lev_1['group'] = "a"
  df_mol_lev_2['group'] = "b"
  
  color_palette_ml2 = colorRampPalette(c("lightblue", "steelblue4"))
  color_palette_ml1 = colorRampPalette(c("yellow2","goldenrod","darkred"))
  
  df_mol_lev_1["color"] = color_palette_ml1(length(df_mol_lev_1))[as.numeric(cut(df_mol_lev_1$score, breaks = length(df_mol_lev_1)))]
  df_mol_lev_2["color"] = color_palette_ml2(length(df_mol_lev_2))[as.numeric(cut(df_mol_lev_2$score, breaks = length(df_mol_lev_2)))]
  
  nodes <- bind_rows(df_mol_lev_1, df_mol_lev_2)
  nodes <- mutate(nodes, value = 40)
  nodes <- filter(nodes, score > as.double(pip))
  return(nodes)
}

complete_edges <- function(nodes){
  nodes <- read.csv(nodes$datapath)
  nodes <- as.data.frame(nodes, stringsAsFactors = FALSE)
  
  node_ids <- nodes$id
  rownumber = 1
  len = length(node_ids)
  iterations = len*(len-1)/2
  edgelist <- matrix(nrow = iterations, ncol = 2)
  
  for (i in 1:(len-1)) 
  {
    val <- node_ids[i]
    for (j in 1:(len-i)) 
    { 
      val2 <- node_ids[j+i]
      edgelist[rownumber, 1] = val
      edgelist[rownumber, 2] = val2
      rownumber = rownumber + 1
    }
  }
  
  edgelist = as.data.frame(edgelist)
  colnames(edgelist) = c("from", "to")
  return(edgelist)
}

graph_from_map <- function(mapping, df_ml_1, df_ml_2){
  edgelist <- data.frame(matrix(ncol = 2, nrow = 0))
  colnames(edgelist) <- c('from', 'to')
  
  for (i in 1: nrow(mapping))
  {
    if ((mapping[i, 1] %in% df_ml_1$id) & (mapping[i, 2] %in% df_ml_2$id))
    {
      edgelist = rbind(edgelist, mapping[i,])
    }
  }
}

# function to plot subgraph
subgraph <- function(df1, df2, df3){
  #gene_file <- read.csv(file = './data/gene_list.csv', header=T, as.is=T)
  #cpg_file <- read.csv(file = './data/cpg_list.csv', header=T, as.is=T)
  #bed_file <- read.csv(file = './data/gene_to_cpg_map.csv', header=T, as.is=T)
  
  gene_list <- as.data.frame(df1, stringsAsFactors = FALSE)
  cpg_list <- as.data.frame(df2, stringsAsFactors = FALSE)
  mapping <- as.data.frame(df3, stringsAsFactors = FALSE)
  
  colnames(gene_list) <- c('score', 'id', 'group', 'color', 'size')
  colnames(cpg_list) <- c('score', 'id', 'group', 'color', 'size')
  
  gene_list['group'] = 'a'
  cpg_list['group'] = 'b'
  
  gene_palette <- colorRampPalette(c("lightblue", "steelblue4"))
  gene_list$color <- gene_palette(length(gene_list))[as.numeric(cut(gene_list$feature, breaks = length(gene_list)))]
  gene_list$score <- as.numeric(gene_list$score)
  
  cpg_palette <- colorRampPalette(c("yellow2","goldenrod","darkred"))
  cpg_list$color <- cpg_palette(length(cpg_list))[as.numeric(cut(cpg_list$feature, breaks = length(cpg_list)))]
  cpg_list$feature <- as.numeric(cpg_list$feature)
  
  gene_list2 <- data.frame(matrix(ncol = 5))
  k = 1
  for (i in 1:length(gene_list$id))
  {
    if (gene_list$feature[i] > 0)
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
    if (cpg_list$feature[i] > 0)
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
  
  return(list(nodes=nodes2, edges=edgelist2))
}

# Function to plot color bar
color.bar <- function(lut, min, max, nticks=11, ticks=seq(min, max, len=nticks), title='') {
 scale = (length(lut)-1)/(max-min)
 #dev.new(width=1.75, height=5)
 plot(c(0,10), c(min,max), type='n', bty='n', xaxt='n', xlab='', yaxt='n', ylab='', main=title)
 axis(2, ticks, las=1)
 for (i in 1:(length(lut)-1)) {
  y = (i-1)/scale + min
   rect(0,y,10,y+1/scale, col=lut[i], border=NA)
 }
}