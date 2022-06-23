library(shiny)
library(visNetwork)
library(dplyr)
library(shinyBS)
library(shinythemes)
library(multioviz) # Followed: https://tinyheero.github.io/jekyll/update/2015/07/26/making-your-first-R-package.html

app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))
#source(paste(app_dir, "/scripts/perturb.R", sep = ""))

server <- function(input, output, session) {

  #reactive expression for rank thresholding
  score_threshold_ml1 <- reactive(input$slider1)
  score_threshold_ml2 <- reactive(input$slider2)

  ml1_filepath = reactiveVal()
  ml2_filepath = reactiveVal()
  map_between_filepath = reactiveVal()
  map_ml1_filepath = reactiveVal()
  map_ml2_filepath = reactiveVal()
  
  read_ml_lev_1 = reactive({
    if(input$demo) {
      ml1_filepath(paste(app_dir, "/data/simple_ml1.csv", sep = ""))
    }
    else if (isTruthy(input$mol_lev_1)) {
      ml1_filepath(input$mol_lev_1$datapath)
    }
    else if (input$run_model) {
      ml1_filepath(paste("/Users/ashleyconard/Desktop/multio-viz/results/ML1_pip.csv", sep = ""))
    }
    else if (input$rerun_model) {
      ml1_filepath(paste("/Users/ashleyconard/Desktop/multio-viz/results/ML1_pip_hyp.csv", sep = ""))
    }
    
    

    if (is.null(ml1_filepath())) {
      return()
    }

    read.csv(file = ml1_filepath(),
             sep = ",",
             header = TRUE)
  })

  read_ml_lev_2 = reactive({
    if(input$demo) {
      ml2_filepath(paste(app_dir, "/data/simple_ml2.csv", sep = ""))
    }
    else if (isTruthy(input$mol_lev_2)) {
      ml2_filepath(input$mol_lev_2$datapath)
    }
    else if (input$run_model) {
      ml2_filepath(paste("/Users/ashleyconard/Desktop/multio-viz/results/ML2_pip.csv", sep = ""))
    }
    else if (input$rerun_model) {
      ml2_filepath(paste("/Users/ashleyconard/Desktop/multio-viz/results/ML2_pip_hyp.csv", sep = ""))
    }

    if (is.null(ml2_filepath())) {
      return()
    }

    read.csv(file = ml2_filepath(),
             sep = ",",
             header = TRUE)
  })

  read_map_btw = reactive({
    if(input$demo) {
      map_between_filepath(paste(app_dir, "/data/simple_map_ml1_ml2.csv", sep = ""))
    }
    else if (isTruthy(input$map_lev_1_2)) {
      map_between_filepath(input$map_lev_1_2$datapath)
    }
    else if (input$run_model) {
      map_between_filepath(paste("/Users/ashleyconard/Desktop/multio-viz/results/btw_ML_map.csv", sep = ""))
    }
    else if (input$rerun_model) {
      map_between_filepath(paste("/Users/ashleyconard/Desktop/multio-viz/results/btw_ML_map_hyp.csv", sep = ""))
    }

    if (is.null(map_between_filepath())) {
      return()
    }

    read.csv(file = map_between_filepath(),
             sep = ",",
             header = TRUE)
  })

  read_map_ml1 = reactive({
    if(input$demo) {
      map_ml1_filepath(paste(app_dir, "/data/simple_map_ml1.csv", sep = ""))
    }
    else if (isTruthy(input$map_lev_1)) {
      map_ml1_filepath(input$map_lev_1$datapath)
    }
    else if (input$run_model) {
      map_ml1_filepath(paste(app_dir, "/data/simple_map_ml1.csv", sep = ""))
    }
    else if (input$rerun_model) {
      map_ml1_filepath(paste(app_dir, "/data/simple_map_ml1.csv", sep = ""))
    }


    if (is.null(map_ml1_filepath())) {
      return()
    }

    read.csv(file = map_ml1_filepath(),
             sep = ",",
             header = TRUE)
  })

    read_map_ml2 = reactive({
    if(input$demo) {
      map_ml2_filepath(paste(app_dir, "/data/simple_map_ml2.csv", sep = ""))
    }
    else if (isTruthy(input$map_lev_2)) {
      map_ml2_filepath(input$map_lev_2$datapath)
    }
    else if (input$run_model) {
      map_ml2_filepath(paste("/Users/ashleyconard/Desktop/multio-viz/results/ML2_map.csv", sep = ""))
    }
    else if (input$rerun_model) {
      map_ml2_filepath(paste("/Users/ashleyconard/Desktop/multio-viz/results/ML2_map.csv", sep = ""))
    }

    if (is.null(map_ml2_filepath())) {
      return()
    }

    read.csv(file = map_ml2_filepath(),
             sep = ",",
             header = TRUE)
  })
  
  generate_nodes <- eventReactive(
    req((isTruthy(input$go) || isTruthy(input$demo) || isTruthy(input$run_model) || isTruthy(input$rerun_model)), read_ml_lev_1(), read_ml_lev_2())
    ,{

      if (!is.null(read_ml_lev_1()) && !is.null(read_ml_lev_1())){
        node <- make_nodes(read_ml_lev_1(), read_ml_lev_2(), score_threshold_ml1(), score_threshold_ml2())
        return(node)
      }
      else {
        print("No nodes")
      }
  })

  generate_edges <- eventReactive(
    req(isTruthy(input$go) || isTruthy(input$demo)|| isTruthy(input$run_model) || isTruthy(input$rerun_model)), {
      if (is.null(read_map_ml1())){
        if (isTruthy(input$no_con_ml1)){
          edgelist_ml1 <- data.frame(matrix(ncol = 2, nrow = 0))
          colnames(edgelist_ml1) <- c('from', 'to')
          }
        else if (isTruthy(input$complete_ml1)){
          req(input$mol_lev_1)
          edgelist_ml1 <- complete_edges(input$mol_lev_1)
          }
      }
      else{
        df_withinmap_lev_1 <- as.data.frame(read_map_ml1(), stringsAsFactors = FALSE)
        edgelist_ml1 <- df_withinmap_lev_1
      }

      if (is.null(read_map_ml2())){
        if (isTruthy(input$no_con_ml2)){
          edgelist_ml2 <- data.frame(matrix(ncol = 2, nrow = 0))
          colnames(edgelist_ml2) <- c('from', 'to')
          }
        else if (isTruthy(input$complete_ml2)){
          req(input$mol_lev_2)
          edgelist_ml2 <- complete_edges(input$mol_lev_2)
          }
      }
      else{
        df_withinmap_lev_2 <- as.data.frame(read_map_ml2(), stringsAsFactors = FALSE)
        edgelist_ml2 <- df_withinmap_lev_2
      }

      df_map_lev_1_2 <- as.data.frame(read_map_btw(), stringsAsFactors = FALSE)
      edge <- rbind(edgelist_ml1, edgelist_ml2)
      edge <- rbind(edge, df_map_lev_1_2)
      return(edge)
    }
  )
  
  observeEvent(req(isTruthy(input$go) || isTruthy(input$demo) || isTruthy(input$run_model) || isTruthy(input$rerun_model) ), {

    node <- generate_nodes()
    edge <- generate_edges()

    if (!is.null(node) || !is.null(edge)){
      print(node)
      output$input_graph <- renderVisNetwork({
      visNetwork(node, edge) %>%
        visNodes(label = "id", size = 20, shadow = list(enabled = TRUE, size = 10)) %>%
        visLayout(randomSeed = 12) %>%
        visIgraphLayout(input$layout) %>% 
        visOptions(manipulation = list(enabled = TRUE, addNodeCols = c("id", "score", "group", "color", "value")), highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
        visGroups(groupname = "a", shape = "triangle") %>%
        visGroups(groupname = "b", shape = "square") %>%
        visExport(type = "png", name = "network", label = paste0("Export as png"), background = "#fff", float = "left", style = NULL, loadDependencies = TRUE) %>%
        visEvents(doubleClick = "function(nodes) {
                      Shiny.onInputChange('click', nodes.nodes[0]);
                      }")
    })
    }
  })
  
  observe({
    visNetworkProxy("input_graph") %>%
      visRemoveNodes(id = input$click)
  })

  #dropdown to select graph layout
  graphLayout <- reactive({
    req(input$go || isTruthy(input$run_model) || isTruthy(input$rerun_model))
    switch(input$layout,
           "layout_with_sugiyama" = layout$x,
           "layout_with_kk" = layout$y,
           "layout_nicely" = layout$z,
           "Please Select a Layout" = NULL)
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
   
   output$data_examples <- renderImage({
     list(src = "./www/example_data.jpeg", width = "85%", height = "100%", style = "display: block; margin-left: auto; margin-right: auto;", alt = "Alternate text")
   }, deleteFile = FALSE)

   output$model_data_examples <- renderImage({
     list(src = "./www/model_example_data.png", width = "100%", style = "display: block; margin-left: auto; margin-right: auto;", alt = "Alternate text")
   }, deleteFile = FALSE)
   
}


ui <- fluidPage(theme = shinytheme("cosmo"),  

  title <-
    tags$a(tags$img(
      src = "logo.png",
      height = "auto",
      width = "20%"
    )),
  

  
  sidebarLayout(
    sidebarPanel(
            
      fluidRow(
        column(6,
        h1("Visualize", align="center"),
        fileInput("mol_lev_1", "Choose File for ML1:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
          column(6, 
          h1("Perturb", align="center"),
          fileInput("x_model_input", "Choose X:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")))),                             
      fluidRow(
        column(6,
        fileInput("mol_lev_2", "Choose File for ML2:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
        column(6, 
        fileInput("y_model_input", "Choose y:",
                multiple = FALSE,
                accept = c("text/csv",
                            "text/comma-separated-values,text/plain",
                            ".csv")))), 
      
      fluidRow(
        column(6,
        fileInput("map_lev_1_2", "Choose Mapping File from ML1 to ML2:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
        column(6, 
          fileInput("mask_input", "Choose mask:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")))), 
      fluidRow(
        column(width = 6, 
               fileInput("map_lev_1", "Choose Mapping Type for ML1:",
                         multiple = FALSE,
                         accept = c("text/csv",
                                    "text/comma-separated-values,text/plain",
                                    ".csv")),
        column(width = 6, checkboxInput("no_con_ml1", "No Connections", FALSE)),
        column(width = 6, checkboxInput("complete_ml1", "Fully Connected", FALSE))),
        column(6, 
        selectInput(
          "organism",
          label = NULL,
          choices = c(
          "Select a method" = "NA",
          "BANNs" = "banns",
          "BIOGRINN" = "biogrinn")))
        ),
      
      fluidRow(
        column(width = 6, 
               fileInput("map_lev_2", "Choose Mapping Type for ML2:",
                         multiple = FALSE,
                         accept = c("text/csv",
                                    "text/comma-separated-values,text/plain",
                                    ".csv")),
        column(width = 6, checkboxInput("no_con_ml2", "No Connections", FALSE)),
        column(width = 6, checkboxInput("complete_ml2", "Fully Connected", FALSE))),

        column(6,
        align="center",
        actionButton("run_model", "Run Model"),
        actionButton("rerun_model", "Rerun Model"))
      ),
      
      fluidRow(
        column(6,
        align="center",
        actionButton("demo", "Demo")),
        column(6,
        align="center",
        actionButton("demo", "Demo"))
      ),
      
      fluidRow(
        align="center",
        actionButton("go", "Generate Graph"),
        hr()
      ),
      
      
      fluidRow(
        selectInput("layout", "Select Graph Layout:", 
          choices = c("layout_with_sugiyama", "layout_with_kk", "layout_nicely"), 
          selected = "layout_with_sugiyama")),
      
      fluidRow(
        hr()
      ),
      
      fluidRow(
        sliderInput("slider1", "Set Threholding For ML1:",
                    min = 0, max = 1, value = 0.5)),
      fluidRow(
        #imageOutput("colorbar1"))
        colorbar1 <-
          tags$a(tags$img(
            src = "colorbar2.png",
            height = "auto",
            width = "100%"
          ))),
        
      
      fluidRow(
        align="center",
        #textInput("txt_ly_1", textOutput("ml1"), width = "100px"),
        textOutput("ml1")
      ),
      
      fluidRow(
        sliderInput("slider2", "Set Threholding for ML2:",
                    min = 0, max = 1, value = 0.5)),
      fluidRow(
        colorbar2 <-
          tags$a(tags$img(
            src = "colorbar1.png",
            height = "auto",
            width = "100%"
        ))),
      
      fluidRow(
        align="center",
        #textInput("txt_ly_2", textOutput("ml2"), width = "100px"),
        textOutput("ml2")
      ),
      
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Instructions",
                 
          fluidRow(h1("Welcome! Thank you for using Multio-viz.")),
                 
          fluidRow(
            hr()
          ),

          fluidRow(h3("Multio-viz accepts 5 inputs for visualization:"),
            tags$ol(
              tags$li("A csv file for vertices of Molecular Level 1"), 
              tags$li("A csv file for vertices of Molecular Level 2"), 
              tags$li("A csv file mapping vertices of Molecular Level 1 to vertices of Molecular Level 2"),
              tags$li("A csv file mapping vertices within Molecular Level 1"),
              tags$li("A csv file mapping vertices within Molecular Level 2"),
              tags$h6("NOTE FOR INPUTS 4 AND 5: If molecular level has complete edges, check 'Full Connections'. If molecular level has trivial edges, check 'No Connections' in lieu of file input.")
            )),  
          fluidRow(
            actionButton("data", "View Example Data"),
            bsModal("modalExamples", "Example Data", "data", size = "large",imageOutput("data_examples"))
          ),

          fluidRow(h3("Multio-viz accepts 4 inputs for perturbation:"),
            tags$ol(
              tags$li("A text file X of samples by Molecular Level 1 feature."), 
              tags$li("A text file y of Molecular Level 2 feature for all samples."), 
              tags$li("A text file mask of mapping between Molecular Levels 1 and 2.")
            )),
            fluidRow(
            actionButton("model_data", "View Example Data"),
            bsModal("model_data_Examples", "Example Data", "model_data", size = "large",imageOutput("model_data_examples"))
          ),
                 
          fluidRow(
            hr()
          ),
                 
          fluidRow(
            h3("QuickStart: Visualize"),
              tags$ol(
                tags$li("Convert data to accepted input formats."), 
                tags$li("Click 'Browse' to input data."),
                tags$li("Click 'Generate Graph' to generate gene regulatory network.")
              ),
            
            h3("QuickStart: Perturb"),
              tags$ol(
                tags$li("Convert data to accepted input formats."), 
                tags$li("Click 'Browse' to input data."),
                tags$li("Click 'Run Model' to generate gene regulatory network'.")
              )),

          fluidRow(
            hr()
          ),
                 
          fluidRow(h3("Features:"),
            tags$ul(
              tags$li("Choose graph layout with 'Select Graph Layout Dropdown'"), 
              tags$li("Filter out nodes  by statistical ranking with slider"),
              tags$li("Single click on node to highlight connected edges and nodes"),
              tags$li("Double click on node to remove node and connected edges"),
              tags$li("Click 'Edit' to add edges and nodes"),
            ))),
        
        tabPanel("View Graph", visNetworkOutput("input_graph", height = "800px", width = "100%")),
      )
    )
  )
)

shinyApp(ui, server)