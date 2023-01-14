##' Adds attributes to nodes in each molecular level and creates nodes dataframe
##'
##' @param ml1: a dataframe nodes in molecular level 1 with score and id
##' @param ml2: a dataframe nodes in molecular level 2 with score and id
##' @param thres_1: score threshold for nodes in ml1
##' @param thres_2: score threshold for nodes in ml2
##' @return nodes: a dataframe for node attributes
make_nodes <- function(ml1, ml2, thres_1, thres_2) {
  df_mol_lev_1 <- ml1
  df_mol_lev_2 <- ml2
  
  df_mol_lev_1['group'] = "ML1"
  df_mol_lev_2['group'] = "ML2"
  
  color_palette_ml2 = colorRampPalette(c("lightblue", "steelblue4"))
  color_palette_ml1 = colorRampPalette(c("yellow2","goldenrod","darkred"))
  
  df_mol_lev_1["color"] = color_palette_ml1(length(df_mol_lev_1))[as.numeric(cut(df_mol_lev_1$score, breaks = length(df_mol_lev_1)))]
  df_mol_lev_2["color"] = color_palette_ml2(length(df_mol_lev_2))[as.numeric(cut(df_mol_lev_2$score, breaks = length(df_mol_lev_2)))]
  
  df_mol_lev_1["shape"] = 'circle'
  df_mol_lev_2["shape"] = 'square'

  df_mol_lev_1 <- filter(df_mol_lev_1, score > as.double(thres_1))
  df_mol_lev_2 <- filter(df_mol_lev_2, score > as.double(thres_2))
  nodes <- bind_rows(df_mol_lev_1, df_mol_lev_2)
  nodes <- mutate(nodes, value = 40)
  return(nodes)
}

##' Makes mapping dataframe in which nodes in a molecular level make up a complete graph
##'
##' @param nodes: a dataframe of nodes in a molecular level
##' @return edgelist: a dataframe for complete edges between the nodes
complete_edges <- function(nodes){
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

##' Generates network graph from node and edge dataframes
##'
##' @param nodes: a dataframe of nodes and node attributes
##' @param edges: a dataframe of edges
##' @param layout: an igraph network layout
##' @return graph: a graph object to be visualized
make_graph <- function(nodes, edges, layout) {
  if (!is.null(nodes) || !is.null(edges)) {
  graph <- renderVisNetwork({
    visNetwork(nodes, edges) %>%
      visNodes(label = "id", size = 20, shadow = list(enabled = TRUE, size = 10)) %>%
      visLayout(randomSeed = 12) %>%
      visIgraphLayout(layout) %>% 
      visOptions(manipulation = list(enabled = TRUE, addNodeCols = c("id", "group"), addEdgeCols = c("from", "to", "id")), highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
      visGroups(groupname = "a", shape = "triangle") %>%
      visGroups(groupname = "b", shape = "square") %>%
      visExport(type = "png", name = "network", label = paste0("Export as png"), background = "#fff", float = "left", style = NULL, loadDependencies = TRUE)
  })
  return(graph)
  }
}