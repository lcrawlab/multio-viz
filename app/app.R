library(shiny)
library(visNetwork)
library(dplyr)
library(shinyBS)

app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))

server <- function(input, output, session) {
  # dropdown to select graph layout
  graphLayout <- reactive({
    req(input$go)
    switch(input$layout,
           "layout_with_sugiyama" = layout$x,
           "layout_with_kk" = layout$y,
           "layout_nicely" = layout$z,
           "Please Select a Layout" = NULL)
  })
  
  #reactive expression for pip thresholding
  pip <- reactive(input$slider)
  
  # demo_graph <- eventReactive(input$demo,
  #                             # df_mol_lev_1 <- read.csv(paste(app_dir, "/data/simple_ml1.csv", sep = ""))
  #                             # df_mol_lev_2 <- read.csv(paste(app_dir, "/data/simple_ml2.csv", sep = ""))
  #                             # df_map_lev_1_2 <- read.csv(paste(app_dir, "/data/simple_map_ml1_ml2.csv", sep = ""))
  #                             # df_withinmap_lev_1 <- read.csv(paste(app_dir, "/data/simple_map_ml1.csv", sep = ""))
  #                             # df_withinmap_lev_2 <- read.csv(paste(app_dir, "/data/simple_map_ml2.csv", sep = ""))
  #                             )
  
  make_nodes <- eventReactive({
    req(input$go, input$mol_lev_1, input$mol_lev_2)},

    {nodes <- make_nodes(input$mol_lev_1, input$mol_lev_2)
    print(nodes)
    return(nodes)
  })

   make_edges_ml1 <- eventReactive({
    req(input$go, input$input$map_lev_1 | input$no_con_ml1 | input$complete_ml1)}, {
    if (!is.null(input$map_lev_1)){
      df_withinmap_lev_1 <- read.csv(input$map_lev_1$datapath)
      df_withinmap_lev_1 <- as.data.frame(df_withinmap_lev_1, stringsAsFactors = FALSE)
      edgelist_ml1 <- df_withinmap_lev_1
    }
    else if (!is.null(input$no_con_ml1)){
      edgelist_ml1 <- data.frame(matrix(ncol = 2, nrow = 0))
      colnames(edgelist_ml1) <- c('from', 'to')
    }
    else if (!is.null(input$complete_ml1)){
      req(input$mol_lev_1)
      edgelist_ml1 <- complete_edges(input$mol_lev_1)
    }
    return(edgelist_ml1)
  })
  
  make_edges_ml2 <- eventReactive({
    req(input$go, input$input$map_lev_2 | input$no_con_ml2 | input$complete_ml2)}, {
    if (!is.null(input$map_lev_2)){
      df_withinmap_lev_2 <- read.csv(input$map_lev_1$datapath)
      df_withinmap_lev_2 <- as.data.frame(df_withinmap_lev_2, stringsAsFactors = FALSE)
      edgelist_ml2 <- df_withinmap_lev_2
    }
    else if (!is.null(input$no_con_ml2)){
      edgelist_ml2 <- data.frame(matrix(ncol = 2, nrow = 0))
      colnames(edgelist_ml2) <- c('from', 'to')
    }
    else if (!is.null(input$complete_ml2)){
      req(input$mol_lev_2)
      edgelist_ml2 <- complete_edges(input$mol_lev_2)
    }
    return(edgelist_ml2)
  })
  
  make_edges <- eventReactive({
    req(make_edges_ml1(), make_edges_ml2())}, {

    df_map_lev_1_2 <- read.csv(input$map_lev_1_2$datapath)
    df_map_lev_1_2 <- as.data.frame(df_map_lev_1_2, stringsAsFactors = FALSE)

    edgelist_ml1 <- make_edges_ml1()
    edgelist_ml2 <- make_edges_ml2()

    edges <- rbind(edgelist_ml1, edgelist_ml2)
    edges <- rbind(edges, df_map_lev_1_2)
    return(edges)
  })
  
  generate_graph <- eventReactive({req(make_edges(), make_nodes())}, { 
    nodes <- make_nodes()
    edges <- make_edges()
    make_graph(nodes, edges)
  })
  
  #build graph from helper functions
  output$input_graph <- renderVisNetwork({
   generate_graph()
  })
  
  observe({
    visNetworkProxy("input_graph") %>%
      visRemoveNodes(id = input$click)
  })

   output$ml1 <- renderText("Score Name:")
   output$ml2 <- renderText("Score Name:")

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

ui <- fluidPage(  

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
                textInput("txt_ly_1", textOutput("ml1"), width = "100px")
      ),
      
      fluidRow(
        sliderInput("slider2", "Set Threholding for ML2:",
                    min = 0, max = 1, value = 0.5)),
      fluidRow(
        #imageOutput("colorbar2")
        colorbar2 <-
          tags$a(tags$img(
            src = "colorbar2.png",
            height = "auto",
            width = "100%"
        ))),
      
      fluidRow(
        align="center",
        textInput("txt_ly_2", textOutput("ml2"), width = "100px")
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
                            tags$h6("NOTE FOR INPUTS 4 AND 5: If molecular level has fully connected nodes, input empty file to generate all possible edges.")
                          )
                          ),
                 
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
                    )
                  ),
                 
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
                          ))
                 
            
                 ),
        
        tabPanel("Input Graph", visNetworkOutput("input_graph", height = "800px", width = "100%")),
      )
      
    )
  )
)

shinyApp(ui, server)