install.packages('visNetwork')
install.packages('s2dverification')
library('shiny')
library('visNetwork')
library(s2dverification)

#replace this file path with file path for your dataframe
my_path = 'downloads/nodes2.csv'

print("TEST")

server <- function(input, output) {
  output$colorbar <- renderPlot({
    ColorBar(vertical = TRUE, var_limits = c(0, 1.0), color_fun = colorRampPalette(c("lightblue", "steelblue4")), title = "Pip Score")
  })
  output$default <- renderVisNetwork({
    #create node dataframe
    data1 <- read.csv(file = my_path, header=T, as.is=T)
    data2 <- matrix(ncol = 4)
    prev_id = NULL
    length = nrow(data1)
    d2_row = 0
    
    for (i in 1:length)
    {
      cur_cpg = as.character(data1[i, 1])
      cur_cpg_pip = data1[i, 2]
      cur_id = data1[i, 3]
      cur_pip = data1[i, 4]
      
      if (i == 1)
      {
        data2[d2_row + 1, 1] <- cur_id
        data2[d2_row + 1, 2] <- cur_pip
        data2[d2_row + 1, 3] <- cur_cpg
        data2[d2_row + 1, 4] <- cur_cpg_pip
        d2_row = d2_row + 1
      }
      else if (cur_id != prev_id)
      {
        data2 <- rbind(data2, c(0, 0, 0, 0))
        data2[d2_row + 1, 1] <- cur_id
        data2[d2_row + 1, 2] <- cur_pip
        data2[d2_row + 1, 3] <- cur_cpg
        data2[d2_row + 1, 4] <- cur_cpg_pip
        d2_row = d2_row + 1
      }
      else 
      {
        data2[d2_row, 3] = paste(data2[d2_row, 3], ",", cur_cpg, sep="")
        data2[d2_row, 4] = paste(data2[d2_row, 4], ", ", cur_cpg_pip, sep="")
      }
      prev_id = cur_id
    }
    
    nodes <- as.data.frame(data2, stringsAsFactors = FALSE)
    colnames(nodes) <- c('id', 'pip', 'cpg', 'cpg_pip')
    
    nodes$pip <- as.numeric(nodes$pip)
    
    #create edgelist
    genes <- nodes$id
    rownumber = 1
    len = length(genes)
    iterations = len*(len-1)/2
    edgelist <- matrix(nrow = iterations, ncol = 2)
    
    for (i in 1:(len-1)) 
    {
      val <- genes[i]
      for (j in 1:(len-i)) 
      { 
        val2 <- genes[j+i]
        edgelist[rownumber, 1] = val
        edgelist[rownumber, 2] = val2
        rownumber = rownumber + 1
      }
    }
    edges <- as.data.frame(edgelist)
    colnames(edges) <- c('from', 'to')
    
    #assign node and edges attributes for default graph
    nodes$title  <- nodes$cpg
    nodes$size   <- nodes$pip*30
    edges$color <- "lightblue"
    palette <- colorRampPalette(c("lightblue", "steelblue4"))
    nodes$col <- palette(length(nodes))[as.numeric(cut(nodes$pip, breaks = length(nodes)))]
    print(nodes$pip)
    nodes$color <- nodes$col
    
    #default graph
    visNetwork(nodes, edges) %>%
      visIgraphLayout() %>%
      visOptions(highlightNearest = list(enabled =TRUE, degree = 2, hover = T), nodesIdSelection = TRUE, manipulation = TRUE)%>%
      visEdges(hoverWidth = 3, selectionWidth = 3) %>%
      visNodes(labelHighlightBold = TRUE, borderWidthSelected = 4) %>%
      visInteraction(tooltipDelay = 0)
    
  })
  output$subgraph <- renderVisNetwork({
    #create node dataframe
    data1 <- read.csv(file = my_path, header=T, as.is=T)
    data2 <- matrix(ncol = 4)
    prev_id = NULL
    length = nrow(data1)
    d2_row = 0
    
    for (i in 1:length)
    {
      cur_cpg = as.character(data1[i, 1])
      cur_cpg_pip = data1[i, 2]
      cur_id = data1[i, 3]
      cur_pip = data1[i, 4]
      
      if (i == 1)
      {
        data2[d2_row + 1, 1] <- cur_id
        data2[d2_row + 1, 2] <- cur_pip
        data2[d2_row + 1, 3] <- cur_cpg
        data2[d2_row + 1, 4] <- cur_cpg_pip
        d2_row = d2_row + 1
      }
      else if (cur_id != prev_id)
      {
        data2 <- rbind(data2, c(0, 0, 0, 0))
        data2[d2_row + 1, 1] <- cur_id
        data2[d2_row + 1, 2] <- cur_pip
        data2[d2_row + 1, 3] <- cur_cpg
        data2[d2_row + 1, 4] <- cur_cpg_pip
        d2_row = d2_row + 1
      }
      else 
      {
        data2[d2_row, 3] = paste(data2[d2_row, 3], ",", cur_cpg, sep="")
        data2[d2_row, 4] = paste(data2[d2_row, 4], ", ", cur_cpg_pip, sep="")
      }
      prev_id = cur_id
    }
    
    nodes <- as.data.frame(data2, stringsAsFactors = FALSE)
    colnames(nodes) <- c('id', 'pip', 'cpg', 'cpg_pip')
    
    nodes$pip <- as.numeric(nodes$pip)
    is.numeric(nodes$pip)
    
    #create nodes dataframe for subgraph
    nodes2 <- data.frame(matrix(ncol = 4))
    k = 1
    for (i in 1:len)
    {
      if (nodes$pip[i] > 0.60)
      {
        nodes2[k, ] <- nodes[i, ]
        k = k+1
      }
    }
    colnames(nodes2) <- c('id', 'pip', 'cpg', 'cpg_pip')
    
    #create edgelist2
    genes2 <- nodes2$id
    rownumber2 = 1
    len2 = length(genes2)
    iterations2 = len2*(len2-1)/2
    edgelist2 <- matrix(nrow = iterations2, ncol = 2)
    
    for (i in 1:(len-1)) 
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
    edges2 <- as.data.frame(edgelist2)
    edges2
    colnames(edges2) <- c('from', 'to')
    
    #assign node and edges attributes for subgraph
    nodes2$title  <- nodes2$cpg
    nodes2$size   <- nodes2$pip*30
    edges2$color <- "lightblue"
    palette2 <- colorRampPalette(c("lightblue", "steelblue4"))
    nodes2$col <- palette2(length(nodes))[as.numeric(cut(nodes2$pip, breaks = length(nodes2)))]
    nodes2$color <- nodes2$col
    
    #subgraph
    visNetwork(nodes2, edges2) %>%
      visIgraphLayout() %>%
      visOptions(highlightNearest = list(enabled =TRUE, degree = 2, hover = T), nodesIdSelection = TRUE, manipulation = TRUE)%>%
      visEdges(hoverWidth = 3, selectionWidth = 3) %>%
      visNodes(labelHighlightBold = TRUE, borderWidthSelected = 4) %>%
      visInteraction(tooltipDelay = 0)
  })
  
}

ui <- fluidPage(
  titlePanel("Multioviz"),
  
  sidebarLayout(
    sidebarPanel(
      plotOutput("colorbar")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("All Nodes", visNetworkOutput("default")),
        tabPanel("PIP > 0.50", visNetworkOutput("subgraph"))
      )
    )
  )
)

shinyApp(ui = ui, server = server)
