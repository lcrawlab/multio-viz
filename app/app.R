library(shiny)
library(visNetwork)
library(dplyr)
library(shinyBS)

app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))

server <- function(input, output, session) {
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
  
  make_graph <- eventReactive(input$go, {
    df_mol_lev_1 <- read.csv(input$mol_lev_1$datapath)
    df_mol_lev_2 <- read.csv(input$mol_lev_2$datapath)
    df_map_lev_1_2 <- read.csv(input$map_lev_1_2$datapath)
    df_withinmap_lev_1 <- read.csv(input$map_lev_1$datapath)
    df_withinmap_lev_2 <- read.csv(input$map_lev_2$datapath)
    
    colnames(df_mol_lev_1) <- c('feature', 'id')
    colnames(df_mol_lev_2) <- c('feature', 'id')
    
    colnames(df_withinmap_lev_1) <- c('from', 'to')
    colnames(df_withinmap_lev_2) <- c('from', 'to')
    colnames(df_map_lev_1_2) <- c('from', 'to')
    
    df_mol_lev_1['level'] = 1
    df_mol_lev_2['level'] = 2
    
    print(df_withinmap_lev_1)
    
    color_palette_ml1 = colorRampPalette(c("lightblue", "steelblue4"))
    color_palette_ml2 = colorRampPalette(c("yellow2","goldenrod","darkred"))
    
    df_mol_lev_1$color = color_palette_ml1(length(df_mol_lev_1))[as.numeric(cut(df_mol_lev_1$feature, breaks = length(df_mol_lev_1)))]
    df_mol_lev_2$color = color_palette_ml2(length(df_mol_lev_2))[as.numeric(cut(df_mol_lev_2$feature, breaks = length(df_mol_lev_2)))]
    
    nodes = bind_rows(df_mol_lev_1, df_mol_lev_2)
    nodes <- nodes %>% mutate(font.size = 40)
    nodes <- nodes %>% filter(feature > as.double(pip()))
    
    colnames(nodes) <- c('feature', 'id', 'level', 'color')
    
    #create edgelist
    edges <- data.frame(matrix(ncol = 2, nrow = 0))
    colnames(edgelist) <- c('from', 'to')
    
    #edges for molecular level 1
    if (file.info(input$mol_lev_1$datapath)$size == 0) {
      edges_ml1 <- complete_graph(df_mol_lev_1)
    } else {
      edges_ml1 <- df_withinmap_lev_1
    }
    
    #edges for molecular level 2
    if (file.info(input$mol_lev_2$datapath)$size == 0) {
      edges_ml2 <- complete_graph(df_mol_lev_2)
    } else {
      edges_ml2 <- df_withinmap_lev_2
    }
    
    edges <- rbind(edges_ml1, edges_ml2)
    edges <- rbind(edges, df_map_lev_1_2)
    
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
  
  #build graph from helper function
  output$input_graph <- renderVisNetwork({
    # req(input$mol_lev_1)
    # req(input$mol_lev_2)
    # req(input$map_lev_1_2)
    
    make_graph()
  })
  
  observe({
    visNetworkProxy("input_graph") %>%
      visRemoveNodes(id = input$click)
  })
  
  # colorbar (still working on this!)
  # output$colorbar1 <- renderPlot({
  #   img <- htmltools::capturePlot({
  #     color.bar(colorRampPalette(c("yellow2","goldenrod","darkred"))(100), 0, 1, title='molecular_level_1')
  #   }, height = 400, width = 400)
  #   list(src = img, width = 100, height = 100)
  # })
  # 
  # 
  #  output$colorbar2 <- renderImage({
  #    img <- htmltools::capturePlot({
  #      color.bar(colorRampPalette(c("lightblue", "steelblue4"))(100), 0, 1)
  #    }, height = 100, width = 400)
  #    list(src = img, width = "100%", height = "100%")
  # })
   
   output$ml1 <- renderText("Score Name:")
   output$ml2 <- renderText("Score Name:")

   output$logo <- renderImage({
     #width  <- session$clientData$output_logo_width
     #height <- session$clientData$output_logo_height
    
     list(src = "./www/logo.png", width = "20%", height = "35%", alt = "Alternate text")
   }, deleteFile = FALSE)
   
   output$colorbar1 <- renderImage({
     list(src = "./www/colorbar1.png", width = "100%", height = "25%", alt = "Alternate text")
   })
   
   output$colorbar2 <- renderImage({
     list(src = "./www/colorbar2.png", width = "100%", height = "25%", alt = "Alternate text")
   })
   
   output$data_examples <- renderImage({
     list(src = "./www/example_data.jpeg", width = "85%", height = "100%", style = "display: block; margin-left: auto; margin-right: auto;", alt = "Alternate text")
   })
   
}

ui <- fluidPage(  
  #titlePanel(tags$img(src = "logo.png", height="8%", width="8%")),
  
  titlePanel(
    imageOutput("logo")
  ),
  
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
        fileInput("map_lev_1", "Choose Mapping File for ML1:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
      
      fluidRow(
        fileInput("map_lev_2", "Choose Mapping File for ML2:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
      
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
        #img(src="colorbar1.png", align = "left", width = "440px", height = "50px")
        imageOutput("colorbar1")),
      
      fluidRow(
                align="center",
                textInput("txt_ly_1", textOutput("ml1"), width = "100px")
      ),
      
      fluidRow(
        sliderInput("slider2", "Set Threholding for ML2:",
                    min = 0, max = 1, value = 0.5)),
      fluidRow(
        #img(src="colorbar2.png", align = "left", width = "440px", height = "60px")
        imageOutput("colorbar2")),
      
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