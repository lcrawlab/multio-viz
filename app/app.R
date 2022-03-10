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
  output$input_graph <- renderVisNetwork({
    req(input$file1)
    req(input$file2)
    req(input$file3)
    
    df1 <- read.csv(input$file1$datapath)
    df2 <- read.csv(input$file2$datapath)
    df3 <- read.csv(input$file3$datapath)

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
  
  output$our_graph <- renderVisNetwork({
   
    nodes <- nodes %>% mutate(font.size = 40)
    nodes <- nodes %>% filter(feature > as.double(pip()))
    
    visNetwork(nodes, edges) %>%
      visNodes(label = "id", size = 100, shadow = list(enabled = TRUE, size = 10)) %>%
      visLayout(randomSeed = 12) %>%
      visIgraphLayout(input$layout) %>% 
      visOptions(highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE), manipulation = TRUE) %>%
      visGroups(groupname = "a", shape = "circle") %>%
      visGroups(groupname = "b", shape = "triangle") %>%
      visEvents(doubleClick = "function(nodes) {
                   Shiny.onInputChange('click', nodes.nodes[0]);
                   }")
  })
  
  observe({
    visNetworkProxy("our_graph") %>%
      visRemoveNodes(id = input$click)
  })
  
  # colorbar (still working on this!)
  output$colorbar1 <- renderPlot({
    img <- htmltools::capturePlot({
      color.bar(colorRampPalette(c("yellow2","goldenrod","darkred"))(100), 0, 1, title='molecular_level_1')
    }, height = 400, width = 400)
    list(src = img, width = 100, height = 100)
  })
  
   output$colorbar2 <- renderPlot({
     img <- htmltools::capturePlot({
       color.bar(colorRampPalette(c("lightblue", "steelblue4"))(100), 0, 1)
     }, height = 400, width = 400)
     list(src = img, width = 100, height = 100)
  })
   
   output$TEST <- renderPlot({
     par(mar=c(1, 1, 1, 1), xpd=TRUE)
     plot(1:20,20:1,type="l")
     legend("topright", inset=c(-0.2,0.4), legend=c("A","B"), pch=c(1,3), title="Group")})
   
   output$ml1 <- renderText({ input$txt1 })
   
}

ui <- fluidPage(  
  titlePanel(tags$img(src = "logo.png", height="8%", width="8%")),
  
  sidebarLayout(
    sidebarPanel(
      
      fluidRow(
        fileInput("file1", "Choose File for Molecular Level 1",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv"))),
      fluidRow(
        fileInput("file2", "Choose File for Molecular Level 2",
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
      
      fluidRow(
        selectInput("layout", "Select Graph Layout", 
                    choices = c("layout_with_sugiyama", "layout_with_kk", "layout_nicely"), 
                    selected = "layout_with_sugiyama")),
      
      fluidRow(
        sliderInput("slider", "Set Threholding For Molecular Level 1",
                    min = 0, max = 1, value = 0.5)),
      fluidRow(
        img(src="colorbar1.png", align = "left", width = "440px", height = "50px")),
      
      fluidRow(
        sliderInput("slider2", "Set Threholding for Molecular Level 2",
                    min = 0, max = 1, value = 0.5)),
      fluidRow(
        img(src="colorbar2.png", align = "left", width = "440px", height = "50px")),
      
      fluidRow(
        textInput("txt1", textOutput("ml1")),
       # textOutput("ml1"),
      ),
      
      
      # fluidRow(
      #   column(width = 4,
      #   textInput("txt3", "statistical_ranking:"))
      # ),
      # 
      # 
      # fluidRow(
      #   column(width = 4,plotOutput(
      #     "colorbar1",
      #     )
      #    ),
      # column(width = 4, plotOutput(
      #   "colorbar2",
      #   ))
      # ),
      # 
      # fluidRow(
      #   column(width = 4, textInput("txt1", "molecular_level_1:")),
      #   column(width = 4, textInput("txt2", "molecular_level_2:"))
      # ),
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Instructions"),
        tabPanel("Example Graph", visNetworkOutput("our_graph", height = "800px", width = "100%")),
        tabPanel("Input Graph", visNetworkOutput("input_graph", height = "800px", width = "100%")),
      )
      
    )
  )
)

shinyApp(ui, server)