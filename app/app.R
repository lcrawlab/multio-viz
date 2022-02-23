library(shiny)
library(visNetwork)
library(dplyr)

app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))

server <- function(input, output) {
  
  output$layer1 = renderText({input$txt1})
  output$layer2 = renderText({input$txt2})
  output$thres = renderText({input$txt3})
  
  # dropdown to select graph layout
  graphLayout <- reactive({
    switch(input$layout,
           "layout_with_sugiyama" = layout$x,
           "layout_with_kk" = layout$y,
           "layout_nicely" = layout$z,
           "Please Select a Layout" = NULL)
  })
  
  #reactive expression for pip thresholding
  pip <- reactive(input$slider)
  #build graph from helper function
  output$subgraph <- renderVisNetwork({
    req(input$file1)
    req(input$file2)
    req(input$file3)
    
    df1 <- read.csv(input$file1$datapath)
    df2 <- read.csv(input$file2$datapath)
    df3 <- read.csv(input$file3$datapath)
    
    gene_list <- as.data.frame(df1, stringsAsFactors = FALSE)
    cpg_list <- as.data.frame(df2, stringsAsFactors = FALSE)
    mapping <- as.data.frame(df3, stringsAsFactors = FALSE)
    
    colnames(gene_list) <- c('feature', 'id', 'group', 'color', 'size')
    colnames(cpg_list) <- c('feature', 'id', 'group', 'color', 'size')
    
    gene_list['group'] = 'a'
    cpg_list['group'] = 'b'
    
    gene_palette <- colorRampPalette(c("lightblue", "steelblue4"))
    gene_list$color <- gene_palette(length(gene_list))[as.numeric(cut(gene_list$feature, breaks = length(gene_list)))]
    gene_list$feature <- as.numeric(gene_list$feature)
    
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
    
    nodes=nodes2
    edges=edgelist2

    nodes <- nodes %>% mutate(font.size = 40)
    nodes <- nodes %>% filter(feature > as.double(pip()))
    
    visNetwork(nodes, edges) %>%
      visNodes(label = "id", size = 100, shadow = list(enabled = TRUE, size = 10)) %>%
      visLayout(randomSeed = 12) %>%
      visIgraphLayout(input$layout) %>% 
      visOptions(highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
      visGroups(groupname = "a", shape = "circle") %>%
      visGroups(groupname = "b", shape = "triangle") %>%
      visEvents(doubleClick = "function(nodes) {
                   Shiny.onInputChange('click', nodes.nodes[0]);
                   }")
  })
  
  observe({
    visNetworkProxy("subgraph") %>%
      visRemoveNodes(id = input$click)
  })
  
  # colorbar (still working on this!)
  output$colorbar1 <- renderPlot({
    color.bar(colorRampPalette(c("yellow2","goldenrod","darkred"))(100), 0, 1)
  })
  
  output$colorbar2 <- renderPlot({
    color.bar(colorRampPalette(c("lightblue", "steelblue4"))(100), 0, 1)
  })
}

ui <- fluidPage(  
  titlePanel("Multioviz"),
  
  sidebarLayout(
    sidebarPanel(
      fluidRow(
        sliderInput("slider", "Set PIP Threhold",
                    min = 0, max = 1, value = 0)),
      fluidRow(
        selectInput("layout", "Select Graph Layout", 
                    choices = c("layout_with_sugiyama", "layout_with_kk", "layout_nicely"), 
                    selected = "layout_with_sugiyama")),
      
      fluidRow(
        column(width = 4,
        textInput("txt3", "statistical_ranking:"))
      ),
      
      fluidRow(
      img(src="colorbar.png", align = "left", width = "200px", height = "400px")),
      
      # fluidRow(
      #   column(width = 12,plotOutput(
      #     "colorbar1",
      #     width = "100%",
      #     height = "400px")),
        # column(width = 12, plotOutput(
        #   "colorbar2",
        #   width = "100%",
        #   height = "400px"))
      #),
      
      fluidRow(
        column(width = 4, textInput("txt1", "molecular_level_1:")),
        column(width = 4, textInput("txt2", "molecular_level_2:"))
      ),
    ),
    
    mainPanel(
      tabsetPanel(
      tabPanel("File Input",
        fluidRow(
        fileInput("file1", "Choose File for Molecular Level 1",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
        fluidRow(
        fileInput("file2", "Choose File for Molecular Level 3",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
        fluidRow(
        fileInput("file3", "Choose Bed File",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
      ),
      tabPanel("View Graph", visNetworkOutput("subgraph", height = "800px", width = "100%"))
      )
    )
  )
)

shinyApp(ui, server)