multioviz <- function(outdir){
  #Sys.sleep(4)
  runApp("app/")
}

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

make_edges <- function(ml1, ml2, map) {
  if (input[['ml1_map']] == "None"){
    edgelist_ml1 <- data.frame(matrix(ncol = 2, nrow = 0))
    colnames(edgelist_ml1) <- c('from', 'to')
  }
  else if (input[['ml1_map']] == "Complete"){
    req(!is.null(ml1))
    edgelist_ml1 <- complete_edges(ml1)
  }
  else if (input[['ml1_map']] == "Sparse"){
    df_withinmap_lev_1 <- as.data.frame(input[['map_lev_1']][['datapath']], stringsAsFactors = FALSE)
    edgelist_ml1 <- df_withinmap_lev_1
  }
  else {
    edgelist_ml1 <- data.frame(matrix(ncol = 2, nrow = 0))
    colnames(edgelist_ml1) <- c('from', 'to')
  }

  if (input[['ml2_map']] == "None"){
    edgelist_ml2 <- data.frame(matrix(ncol = 2, nrow = 0))
    colnames(edgelist_ml2) <- c('from', 'to')
  }
  else if (input[['ml2_map']] == "Complete"){
    req(!is.null(ml2))
    edgelist_ml2 <- complete_edges(ml2)
  }
  else if (input[['ml2_map']] == "Sparse"){
    df_withinmap_lev_2 <- as.data.frame(input[['map_lev_2']][['datapath']], stringsAsFactors = FALSE)
    edgelist_ml2 <- df_withinmap_lev_2
  }
  else{
    edgelist_ml2 <- data.frame(matrix(ncol = 2, nrow = 0))
    colnames(edgelist_ml2) <- c('from', 'to')       
  }

  edges <- rbind(edgelist_ml1, edgelist_ml2)
  edges <- rbind(edges, map)
  return(edges)
}

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

change_graph <- function(graphChange, reactivesGraph, reactivesPerturb) {
    # If the user added a node, add it to the data frame of nodes.
    lst = list()
    if(graphChange$cmd == "addNode") {
      if(graphChange$group == 'ML1') {
        lst$addedNodesML1 <- append(reactivesPerturb$addedNodesML1, graphChange$id)
      }
      if(graphChange$group == 'ML2') {
        lst$addedNodesML2 <- append(reactivesPerturb$addedNodesML2, graphChange$id)
      }
    }

    # If the user added an edge, add it to the data frame of edges.
    else if(graphChange$cmd == "addEdge") {
      row = c(graphChange$id, graphChange$from, graphChange$to)
      lst$addedEdges <- append(reactivesPerturb$addedEdges, row)
    }

    # If the user edited a node, update that record.
    else if(graphChange$cmd == "editNode") {
      temp = reactivesGraph$nodes
      temp$label[temp$id == graphChange$id] = graphChange$label
      lst$nodes <- temp
    }

    # If the user edited an edge, update that record.
    else if(graphChange$cmd == "editEdge") {
      temp = reactivesGraph$edges
      temp$from[temp$id == graphChange$id] = graphChange$from
      temp$to[temp$id == graphChange$id] = graphChange$to
      lst$edges <- temp
    }

    # If the user deleted something, remove those records.
    else if(graphChange$cmd == "deleteElements") {
      for(node.id in graphChange$nodes) {
        r = reactivesGraph$nodes[reactivesGraph$nodes$id == node.id,]
        if (r$group == 'ML1') {
          lst$deletedNodesML1 <- append(reactivesPerturb$deletedNodesML1, node.id)
        }
        if (r$group == 'ML2') {
          lst$deletedNodesML2 <- append(reactivesPerturb$deletedNodesML2, node.id)       
        }
      }
      for(edge.id in graphChange$edges) {
        temp = reactivesGraph$edges[reactivesGraph$edges$id == edge.id,]
        row = c(edge.id, temp$from, temp$to)
        lst$deletedEdges <- c(reactivesPerturb$deletedEdges, row)
      }
    }

    return(lst)
}

