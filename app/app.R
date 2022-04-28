library(shiny)
library(visNetwork)
library(dplyr)
library(shinyBS)
library(shinythemes)
#runApp("app")

app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))

server <- function(input, output, session) {

  #reactive expression for pip thresholding
  pip <- reactive(input$slider)

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

    if (is.null(map_ml2_filepath())) {
      return()
    }

    read.csv(file = map_ml2_filepath(),
             sep = ",",
             header = TRUE)
  })
  
  generate_nodes <- eventReactive(
    req((isTruthy(input$go) || isTruthy(input$demo)), read_ml_lev_1(), read_ml_lev_2())
    ,{

      if (!is.null(read_ml_lev_1()) && !is.null(read_ml_lev_1())){
        node <- make_nodes(read_ml_lev_1(), read_ml_lev_2(), pip())
        return(node)
      }
      else {
        print("No nodes")
      }
  })

  generate_edges <- eventReactive(
    req(isTruthy(input$go) || isTruthy(input$demo)), {
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
  
  observeEvent(req(isTruthy(input$go) || isTruthy(input$demo)), {

    node <- generate_nodes()
    edge <- generate_edges()

    if (!is.null(node) || !is.null(edge)){
      print("here")
      print(node)
      output$input_graph <- renderVisNetwork({
      visNetwork(node, edge) %>%
        visNodes(label = "id", size = 20, shadow = list(enabled = TRUE, size = 10)) %>%
        visLayout(randomSeed = 12) %>%
        visIgraphLayout(input$layout) %>% 
        visOptions(manipulation = list(enabled = TRUE, addNodeCols = c("id", "feature", "group", "color", "value")), highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
        visGroups(groupname = "a", shape = "square") %>%
        visGroups(groupname = "b", shape = "triangle") %>%
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
    req(input$go)
    switch(input$layout,
           "layout_with_sugiyama" = layout$x,
           "layout_with_kk" = layout$y,
           "layout_nicely" = layout$z,
           "Please Select a Layout" = NULL)
  })

   output$ml1 <- renderText("PIP Score")
   output$ml2 <- renderText("PIP Score")

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
        fileInput("mol_lev_1", "Choose File for ML1:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
      fluidRow(
        fileInput("mol_lev_2", "Choose File for ML2:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
      
      fluidRow(
        fileInput("map_lev_1_2", "Choose Mapping File from ML1 to ML2:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
      
      fluidRow(
        column(width = 6, 
               fileInput("map_lev_1", "Choose Mapping Type for ML1:",
                         multiple = FALSE,
                         accept = c("text/csv",
                                    "text/comma-separated-values,text/plain",
                                    ".csv"))),
        column(width = 3, checkboxInput("no_con_ml1", "No Connections", FALSE)),
        column(width = 3, checkboxInput("complete_ml1", "Fully Connected", FALSE))
        ),
      
      fluidRow(
        column(width = 6, 
               fileInput("map_lev_2", "Choose Mapping Type for ML2:",
                         multiple = FALSE,
                         accept = c("text/csv",
                                    "text/comma-separated-values,text/plain",
                                    ".csv"))),
        column(width = 3, checkboxInput("no_con_ml2", "No Connections", FALSE)),
        column(width = 3, checkboxInput("complete_ml2", "Fully Connected", FALSE))
      ),
      
      fluidRow(
        align="center",
        actionButton("go", "Generate Graph")
      ),

      fluidRow(
        tags$br()
      ),

      fluidRow(
        align="center",
        actionButton("demo", "Demo")
      ),
      
      fluidRow(
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
        sliderInput("slider", "Set Threholding For ML1:",
                    min = 0, max = 1, value = 0.5)),
      fluidRow(
        #imageOutput("colorbar1"))
        colorbar1 <-
          tags$a(tags$img(
            src = "colorbar1.png",
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
            src = "colorbar2.png",
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

          fluidRow(h4("Multio-viz accepts 5 inputs:"),
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
                 
          fluidRow(
            hr()
          ),
                 
          fluidRow(
            h4("QuickStart:"),
              tags$ol(
                tags$li("Convert data to accepted input formats"), 
                tags$li("Click 'Browse' to input data"),
                tags$li("Click 'Generate Graph'")
              )),
                 
          fluidRow(
            hr()
          ),
                 
          fluidRow(h4("Features:"),
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