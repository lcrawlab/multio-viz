library(shiny)
library(visNetwork)
library(dplyr)
library(igraph)
library(shinyBS)
library(shinythemes)
library(shinythemes)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyWidgets)
library(shinyjs)

#library(multioviz) # Followed: https://tinyheero.github.io/jekyll/update/2015/07/26/making-your-first-R-package.html

#for debugging, started R session in multio-viz directory, type "runApp('app/app.R')", and click "demo")
app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))
source(paste(app_dir, "/scripts/perturb.R", sep = ""))

server <- function(input, output, session) {
  options(shiny.maxRequestSize=30*1024^2) 

  X_file = reactive(input$x_model_input$datapath)
  y_file = reactive(input$y_model_input$datapath)
  mask_file = reactive(input$mask_input$datapath)
  demo = reactive(input$demo)

  reactivesModel = reactiveValues()
  reactivesModel$X = NULL
  reactivesModel$y = NULL
  reactivesModel$mask = NULL

  reactivesViz = reactiveValues()
  reactivesViz$ML1 = NULL
  reactivesViz$ML2 = NULL
  reactivesViz$map = NULL

  reactiveMapML1 <- reactiveVal()
  reactiveMapML2 <- reactiveVal()

  #reactive expression for rank thresholding
  score_threshold_ml1 <- reactive(input$slider1)
  score_threshold_ml2 <- reactive(input$slider2)

  reactivesGraph = reactiveValues()
  reactivesGraph$nodes = NULL
  reactivesGraph$edges = NULL

  reactivesPerturb = reactiveValues()
  reactivesPerturb$addedNodesML1 = list()
  reactivesPerturb$addedNodesML2 = list()
  reactivesPerturb$addedEdges = list()

  reactivesPerturb$deletedNodesML1 = list()
  reactivesPerturb$deletedNodesML2 = list()
  reactivesPerturb$deletedEdges = list()
  
  observe({
    if(isTruthy(input$demo)) {
      X_matrix = as.matrix(read.table(paste(app_dir, "/data/Xtest.txt", sep = "")))
    }
    else if(isTruthy(input$x_model_input)) {
      X_matrix = as.matrix(read.table(X_file()))
    }
    else {
      X_matrix = NULL
    }
    if(isTruthy(input$demo)) {
      y_matrix = as.matrix(read.table(paste(app_dir, "/data/ytest.txt", sep = "")))
    }
    else if (isTruthy(input$y_model_input)) {
      y_matrix = as.matrix(read.table(y_file()))
    }
    else {
      y_matrix = NULL
    }
    if(isTruthy(input$demo)) {
      mask_matrix = as.matrix(read.table(paste(app_dir, "/data/masktest.txt", sep = "")))
    }
    else if (isTruthy(input$mask_input)) {
      mask_matrix = as.matrix(read.table(mask_file()))
    }
    else {
      mask_matrix = NULL
    }

    if(!is.null(mask_matrix)) {
      s_names <- paste("s", 1:dim(mask_matrix)[1], sep="")
      g_names <- paste("g", 1:dim(mask_matrix)[2], sep="")
      rownames(mask_matrix) <- s_names
      colnames(mask_matrix) <- g_names
    }

    if(!is.null(X_matrix) & !is.null(mask_matrix)) {
      colnames(X_matrix) <- s_names
    }

    reactivesModel$X = X_matrix
    reactivesModel$y = y_matrix
    reactivesModel$mask = mask_matrix
  })

  observeEvent(req(isTruthy(input$go)), {
      reactivesViz$ML1 = as.data.frame(read.csv(file = input$mol_lev_1$datapath,
             sep = ",",
             header = TRUE), stringsAsFactors = FALSE)
      reactivesViz$ML2 = as.data.frame(read.csv(file = input$mol_lev_2$datapath,
             sep = ",",
             header = TRUE), stringsAsFactors = FALSE)
      reactivesViz$map = as.data.frame(read.csv(file = input$map_lev_1_2$datapath,
             sep = ",",
             header = TRUE), stringsAsFactors = FALSE)
    
  })

  observeEvent(req(isTruthy(input$run_model)), {
      lst = runModel(reactivesModel$X, reactivesModel$mask, reactivesModel$y)
  
      reactivesViz$ML1 = lst$ML1
      reactivesViz$ML2 = lst$ML2
      reactivesViz$map = lst$map
  })
  
#  read_map_ml1 = reactive({
#    if(input$demo) {
#      reactiveMapML1(paste(app_dir, "/data/simple_map_ml1.csv", sep = ""))
#    }
#    else if (isTruthy(input$map_lev_1)) {
#      reactiveMapML1(input$map_lev_1$datapath)
#    }
#    if (is.null(reactiveMapML1())) {
#      return()
#    }
#    read.csv(file = reactiveMapML1(),
#             sep = ",",
#             header = TRUE)
#  })

#  read_map_ml2 = reactive({
#    if(input$demo) {
#      reactiveMapML2(paste(app_dir, "/data/simple_map_ml2.csv", sep = ""))
#    }
#    else if (isTruthy(input$map_lev_2)) {
#      reactiveMapML2(input$map_lev_2$datapath)
#    }
#    if (is.null(reactiveMapML2())) {
#      return()
#    }
#    read.csv(file = reactiveMapML2(),
#             sep = ",",
#             header = TRUE)
#  })

  observeEvent(
    req(((isTruthy(input$run_model)) | (isTruthy(input$go))) & ((!is.null(reactivesViz$ML1)) & (!is.null(reactivesViz$ML2)) & (!is.null(reactivesViz$map)))),
    {
      if (!is.null(reactivesViz$ML1) && !is.null(reactivesViz$ML2)){
        reactivesGraph$nodes <- make_nodes(reactivesViz$ML1, reactivesViz$ML2, score_threshold_ml1(), score_threshold_ml2())
      }
      else {
        print("No nodes")
      }

      if (input$ml1_map == "None"){
        edgelist_ml1 <- data.frame(matrix(ncol = 2, nrow = 0))
        colnames(edgelist_ml1) <- c('from', 'to')
      }
      else if (input$ml1_map == "Complete"){
        req(!is.null(reactivesViz$ML1))
        edgelist_ml1 <- complete_edges(reactivesViz$ML1)
      }
      else if ((input$ml1_map == "Sparse") & (isTruthy(input$sparse_ml1))){
        df_withinmap_lev_1 <- as.data.frame(input$map_lev_1$datapath, stringsAsFactors = FALSE)
        edgelist_ml1 <- df_withinmap_lev_1
      }
      else{
        edgelist_ml1 <- data.frame(matrix(ncol = 2, nrow = 0))
        colnames(edgelist_ml1) <- c('from', 'to')
      }

      if (input$ml2_map == "None"){
        edgelist_ml2 <- data.frame(matrix(ncol = 2, nrow = 0))
        colnames(edgelist_ml2) <- c('from', 'to')
      }
      else if (input$ml2_map == "Complete"){
        req(!is.null(reactivesViz$ML2))
        edgelist_ml2 <- complete_edges(reactivesViz$ML2)
      }
      else if ((input$ml2_map == "Sparse") & (isTruthy(input$sparse_ml2))){
        df_withinmap_lev_2 <- as.data.frame(input$map_lev_2$datapath, stringsAsFactors = FALSE)
        edgelist_ml2 <- df_withinmap_lev_2
      }
      else{
        edgelist_ml2 <- data.frame(matrix(ncol = 2, nrow = 0))
        colnames(edgelist_ml2) <- c('from', 'to')       
      }
      edges <- rbind(edgelist_ml1, edgelist_ml2)
      reactivesGraph$edges <- rbind(edges, reactivesViz$map)

      if (!is.null(reactivesGraph$nodes) || !is.null(reactivesGraph$edges)) {
      output$input_graph <- renderVisNetwork({
        visNetwork(reactivesGraph$nodes, reactivesGraph$edges) %>%
          visNodes(label = "id", size = 20, shadow = list(enabled = TRUE, size = 10)) %>%
          visLayout(randomSeed = 12) %>%
          visIgraphLayout(input$layout) %>% 
          visOptions(manipulation = list(enabled = TRUE, addNodeCols = c("id", "group"), addEdgeCols = c("from", "to", "id")), highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
          visGroups(groupname = "a", shape = "triangle") %>%
          visGroups(groupname = "b", shape = "square") %>%
          visExport(type = "png", name = "network", label = paste0("Export as png"), background = "#fff", float = "left", style = NULL, loadDependencies = TRUE)
      })
    }
  })

  observeEvent(input$input_graph_graphChange, {
    # If the user added a node, add it to the data frame of nodes.
    if(input$input_graph_graphChange$cmd == "addNode") {
      if(input$input_graph_graphChange$group == 'ML1') {
        reactivesPerturb$addedNodesML1 = append(reactivesPerturb$addedNodesML1, input$input_graph_graphChange$id)
      }
      if(input$input_graph_graphChange$group == 'ML2') {
        reactivesPerturb$addedNodesML2 = append(reactivesPerturb$addedNodesML2, input$input_graph_graphChange$id)
      }
    }

    # If the user added an edge, add it to the data frame of edges.
    else if(input$input_graph_graphChange$cmd == "addEdge") {
      row = c(input$input_graph_graphChange$id, input$input_graph_graphChange$from, input$input_graph_graphChange$to)
      reactivesPerturb$addedEdges = append(reactivesPerturb$addedEdges, row)
    }

    # If the user edited a node, update that record.
    else if(input$input_graph_graphChange$cmd == "editNode") {
      temp = reactivesGraph$nodes
      temp$label[temp$id == input$input_graph_graphChange$id] = input$input_graph_graphChange$label
      reactivesGraph$nodes = temp
    }

    # If the user edited an edge, update that record.
    else if(input$input_graph_graphChange$cmd == "editEdge") {
      temp = reactivesGraph$edges
      temp$from[temp$id == input$input_graph_graphChange$id] = input$input_graph_graphChange$from
      temp$to[temp$id == input$editableinput_graph_graphChange_network_graphChange$id] = input$input_graph_graphChange$to
      reactivesGraph$edges = temp
    }

    # If the user deleted something, remove those records.
    else if(input$input_graph_graphChange$cmd == "deleteElements") {
      for(node.id in input$input_graph_graphChange$nodes) {
        r = reactivesGraph$nodes[reactivesGraph$nodes$id == node.id,]
        if (r$group == 'ML1') {
          reactivesPerturb$deletedNodesML1 = append(reactivesPerturb$deletedNodesML1, node.id)
        }
        if (r$group == 'ML2') {
          reactivesPerturb$deletedNodesML2 = append(reactivesPerturb$deletedNodesML2, node.id)       
        }
      }
      for(edge.id in input$input_graph_graphChange$edges) {
        temp = reactivesGraph$edges[reactivesGraph$edges$id == edge.id,]
        row = c(edge.id, temp$from, temp$to)
        reactivesPerturb$addedEdges = c(reactivesPerturb$addedEdges, row)
      }
    }
  })

  observeEvent(input$rerun_model, {
    reactivesModel$X = reactivesModel$X[,!colnames(reactivesModel$X) %in% reactivesPerturb$deletedNodesML1]
    reactivesModel$mask = reactivesModel$mask[!rownames(reactivesModel$mask) %in% reactivesPerturb$deletedNodesML1, !colnames(reactivesModel$mask) %in% reactivesPerturb$deletedNodesML2]
    for(n in reactivesPerturb$deletedEdges) {
      if((n[2] %in% rownames(reactivesModel$mask)) & (n[3] %in% colnames(reactivesModel$mask))) {
        reactivesModel$mask[n[2], n[3]] = 0
      }
    }

    lst = runModel(reactivesModel$X, reactivesModel$mask, reactivesModel$y)
    reactivesViz$ML1 = lst$ML1
    reactivesViz$ML2 = lst$ML2
    reactivesViz$map = lst$map

      if (!is.null(reactivesViz$ML1) && !is.null(reactivesViz$ML2)){
        reactivesGraph$nodes <- make_nodes(reactivesViz$ML1, reactivesViz$ML2, score_threshold_ml1(), score_threshold_ml2())
      }
      else {
        print("No nodes")
      }
      
      if (input$ml1_map == "None"){
        edgelist_ml1 <- data.frame(matrix(ncol = 2, nrow = 0))
        colnames(edgelist_ml1) <- c('from', 'to')
      }
      else if (input$ml1_map == "Complete"){
        req(!is.null(reactivesViz$ML1))
        edgelist_ml1 <- complete_edges(reactivesViz$ML1)
      }
      else if ((input$ml1_map == "Sparse") & (isTruthy(input$sparse_ml1))){
        df_withinmap_lev_1 <- as.data.frame(input$map_lev_1$datapath, stringsAsFactors = FALSE)
        edgelist_ml1 <- df_withinmap_lev_1
      }
      else{
        edgelist_ml1 <- data.frame(matrix(ncol = 2, nrow = 0))
        colnames(edgelist_ml1) <- c('from', 'to')
      }

      if (input$ml2_map == "None"){
        edgelist_ml2 <- data.frame(matrix(ncol = 2, nrow = 0))
        colnames(edgelist_ml2) <- c('from', 'to')
      }
      else if (input$ml2_map == "Complete"){
        req(!is.null(reactivesViz$ML2))
        edgelist_ml2 <- complete_edges(reactivesViz$ML2)
      }
      else if ((input$ml2_map == "Sparse") & (isTruthy(input$sparse_ml2))){
        df_withinmap_lev_2 <- as.data.frame(input$map_lev_2$datapath, stringsAsFactors = FALSE)
        edgelist_ml2 <- df_withinmap_lev_2
      }
      else{
        edgelist_ml2 <- data.frame(matrix(ncol = 2, nrow = 0))
        colnames(edgelist_ml2) <- c('from', 'to')       
      }
      edges <- rbind(edgelist_ml1, edgelist_ml2)
      reactivesGraph$edges <- rbind(edges, reactivesViz$map)

      if (!is.null(reactivesGraph$nodes) || !is.null(reactivesGraph$edges)) {
      output$input_graph <- renderVisNetwork({
        visNetwork(reactivesGraph$nodes, reactivesGraph$edges) %>%
          visNodes(label = "id", size = 20, shadow = list(enabled = TRUE, size = 10)) %>%
          visLayout(randomSeed = 12) %>%
          visIgraphLayout(input$layout) %>% 
          visOptions(manipulation = list(enabled = TRUE, addNodeCols = c("id", "group"), addEdgeCols = c("from", "to", "id")), highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
          visGroups(groupname = "a", shape = "triangle") %>%
          visGroups(groupname = "b", shape = "square") %>%
          visExport(type = "png", name = "network", label = paste0("Export as png"), background = "#fff", float = "left", style = NULL, loadDependencies = TRUE)
      })
    }
  })
  
  #dropdown to select graph layout
  graphLayout <- reactive({
    req(isTruthy(input$run_model) || isTruthy(input$rerun_model))
    switch(input$layout,
           "layout_with_sugiyama" = layout$x,
           "layout_with_kk" = layout$y,
           "layout_nicely" = layout$z,
           "Please Select a Layout" = NULL)
  })

  observeEvent(input$ml1_map, {
    if(input$ml1_map == "Sparse"){
      enable('map_lev_1')
    }
  })

  observeEvent(input$ml2_map, {
    if(input$ml2_map == "Sparse"){
      enable('map_lev_2')
    }
  })

  output$ml1 <- renderText("Rank")
  output$ml2 <- renderText("Rank")

  output$logo <- renderImage({
    list(src = "./www/logo.png", width = "20%", height = "35%", alt = "Alternate text")
  }, deleteFile = FALSE)
   
  output$colorbar1 <- renderImage({
    list(src = "./www/colorbar1.png", width = "100%", height = "25%", alt = "Alternate text")
  }, deleteFile = FALSE)
   
  output$colorbar2 <- renderImage({
    list(src = "./www/colorbar2.png", width = "100%", height = "25%", alt = "Alternate text")
  }, deleteFile = FALSE)
   
  output$data_examples_vis <- renderImage({
    list(src = "./www/example_data.jpeg", width = "85%", height = "100%", style = "display: block; margin-left: auto; margin-right: auto;", alt = "Alternate text")
  }, deleteFile = FALSE)

  output$data_examples_perturb <- renderImage({
    list(src = "./www/model_example_data.png", width = "100%", style = "display: block; margin-left: auto; margin-right: auto;", alt = "Alternate text")
  }, deleteFile = FALSE)

  observeEvent("", {
    showModal(modalDialog(
      includeHTML("./www/intro_text.html"),
      easyClose = TRUE,
    ))
  })

  observeEvent(input$quickstart, {
    showModal(modalDialog(
      includeHTML("./www/intro_text2.html"),
      easyClose = TRUE,
      #footer = actionButton(inputId = "example_data_viz", label = "VIEW EXAMPLE DATA", icon = icon("info-circle"))
    ))
  }) 

  # observeEvent(input$"example_data_viz", {
  #   showModal(modalDialog(
  #     title = 'Example Data for Visualization',
  #     HTML('<img src="./www/example_data.jpeg"="250" ="400" />'),
  #     easyClose = TRUE,
  #   ))
  # }) 

  # observeEvent(input$"example_data_perturb", {
  #   showModal(modalDialog(
  #     title = 'Example Data for Perturbation',
  #     HTML('<img src="./www/model_example_data.jpeg" />'),
  #     easyClose = TRUE,
  #   ))
  # }) 
}

ui <- dashboardPage(
  title = "Multioviz",
  skin = "black",
  dashboardHeader(
    tags$li(class = "dropdown",
      tags$style(".main-header {max-height: 100px}"),
      tags$style(".main-header .logo {height: 80px}")),
    title = tags$a(tags$img(
      src = "logo.png",
      height = "auto",
      width = "50%"
    )),
    titleWidth = 300
  ),
  
  dashboardSidebar(
     width = 300,
     color = 
     sidebarMenu(
          div(class = "inlay", style = "height:15px;width:100%;background-color: #ecf0f5;"),
          HTML("",sep="<br/>"), # new line
          fluidRow(align = "center", bsButton("quickstart", label = "Quickstart", icon = icon("user"), style = "success", size = 'large')),
          menuItem(
            "Visualize",
            tabName = "visualize",
            fluidRow(align = "center", bsButton("example_data_viz", label = "Example Data", style = "success", size = 'large')),
            bsModal("example_data_viz_modal", "Example Data for Visualization", "example_data_viz", size = "large",imageOutput("data_examples_vis")),
            fileInput("mol_lev_1", "Input ML1 Scores:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")),
            fileInput("mol_lev_2", "Input ML2 Scores:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")),
            fileInput("map_lev_1_2", "Input Map:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")),
            fluidRow(align = "center", bsButton("go", label = "GENERATE NETWORK", icon = icon("play-circle"), style = "danger", size = 'large')),
            hr()
          ),
          menuItem(
            "Perturb",
            tabName = "perturb",
            fluidRow(align = "center", bsButton("example_data_perturb", label = "Example Data", style = "success", size = 'large')),
            bsModal("example_data_perturb_modal", "Example Data for Perturbation", "example_data_perturb", size = "large",imageOutput("data_examples_perturb")),
            fluidRow(align = "center", bsButton("demo", label = "Load Demo Files", icon = icon("spinner", class = "spinner-box"),style = "success", size = 'large')),
            fileInput("x_model_input", "Input X:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")),
            fileInput("y_model_input", "Input y:",
                  multiple = FALSE,
                  accept = c("text/csv",
                              "text/comma-separated-values,text/plain",
                              ".csv")),
            fileInput("mask_input", "Input mask:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")),
            selectInput(
              "model_type",
              label = NULL,
              choices = c(
              "Select a model" = "NA",
              "BANNs" = "banns",
              "BIOGRINN" = "biogrinn")),
            fluidRow(
              align = "center", bsButton("run_model", label = "RUN MODEL", icon = icon("play-circle"), style = "danger", size = 'large')
            ),
            fluidRow(
              align = "center", bsButton("rerun_model", label = "RERUN MODEL", icon = icon("play-circle"), style = "danger", size = 'large')),
            hr()
          )
          # menuItem(
          #   "Edit Graph",
          #   selectInput("layout", "Select Graph Layout:", 
          #     choices = c("layout_with_sugiyama", "layout_with_kk", "layout_nicely"), 
          #     selected = "layout_with_sugiyama"),
          #   hr(),
          #   chooseSliderSkin("Flat"),
          #   sliderInput("slider1", "Set Threholding For ML1:",
          #           min = 0, max = 1, value = 0.5),
          #   colorbar1 <-
          #     tags$a(tags$img(
          #     src = "colorbar2.png",
          #     height = "auto",
          #     width = "100%")),
          #   h6("Score", align="center"),
          #   hr(),
          #   chooseSliderSkin("Flat"),
          #   sliderInput("slider2", "Set Threholding For ML2:",
          #           min = 0, max = 1, value = 0.5),
          #   colorbar1 <-
          #     tags$a(tags$img(
          #     src = "colorbar1.png",
          #     height = "auto",
          #     width = "100%")),
          #   h6("Score", align="center")          
          # ),
          #fluidRow(align = "center", bsButton("go", label = "GENERATE NETWORK", icon = icon("play-circle"), style = "danger", size = 'large'))

  )),
dashboardBody(
  width = 12,
    fluidRow(
    box(
            useShinyjs(),
            selectInput("ml1_map", "Select ML1 Connection Type:", 
              choices = c("None", "Complete", "Sparse"), 
              selected = "None"),
            disabled(fileInput("map_lev_1", "Sparse Connections File",
                  multiple = FALSE,
                  accept = c("text/csv",
                              "text/comma-separated-values,text/plain",
                              ".csv"))),
            selectInput("ml2_map", "Select ML2 Connection Type:", 
              choices = c("None", "Complete", "Sparse"), 
              selected = "None"),
            disabled(fileInput("map_lev_2", "Sparse Connections File",
                  multiple = FALSE,
                  accept = c("text/csv",
                              "text/comma-separated-values,text/plain",
                              ".csv"))),
            hr(),
            selectInput("layout", "Select Graph Layout:", 
              choices = c("layout_with_sugiyama", "layout_with_kk", "layout_nicely"), 
              selected = "layout_with_kk"),
            hr(),
            chooseSliderSkin("Flat"),
            sliderInput("slider1", "Set Threholding For ML1:",
                    min = 0, max = 1, value = 0.5),
            colorbar1 <-
              tags$a(tags$img(
              src = "colorbar2.png",
              height = "auto",
              width = "100%")),
            h4("Score", align="center"),
            chooseSliderSkin("Flat"),
            sliderInput("slider2", "Set Threholding For ML2:",
                    min = 0, max = 1, value = 0.5),
            colorbar1 <-
              tags$a(tags$img(
              src = "colorbar1.png",
              height = "auto",
              width = "100%")),
            h4("Score", align="center")),
    box(visNetworkOutput("input_graph", height = "800px", width = "100%"), width = 6))
  )
)

shinyApp(ui, server)