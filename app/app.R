library(shiny)
library(visNetwork)
library(dplyr)

app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))

server <- function(input, output) {
  graphLayout <- reactive({
    switch(input$layout,
           "layout_with_sugiyama" = layout$x,
           "layout_with_kk" = layout$y,
           "layout_nicely" = layout$z,
           "Please Select a Layout" = NULL)
  })
  
  pip <- reactive(input$slider)
  
  #output$selected_var <- renderText({
  # paste("You have selected", pip())
  #g})
  
  #pip_threshold = reactiveVal(0.9)
  
  #observeEvent(input$slider, {pip_threshold}) --> unused
  
  output$subgraph <- renderVisNetwork({
    # subgraph(pip_threshold()) --> unused
    
    nodes <- nodes %>% mutate(font.size = 40)
    nodes <- nodes %>% filter(feature > as.double(pip()))
    
    visNetwork(nodes, edges) %>%
      visNodes(label = "id", size = 100, shadow = list(enabled = TRUE, size = 10)) %>%
      visLayout(randomSeed = 12) %>%
      visIgraphLayout(input$layout) %>% # layout_with_sugiyama
      # TODO: Allow for other graph layouts https://search.r-project.org/CRAN/refmans/igraph/html/layout_nicely.html
      visOptions(highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
      visGroups(groupname = "a", shape = "circle") %>%
      visGroups(groupname = "b", shape = "triangle") 
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
                    selected = "Age 18-24")),
      fluidRow(
        img(src="colorbar.png", align = "left", width = "200px", height = "400px")),
    ),
    
    mainPanel(
      textOutput("selected_var"),
      visNetworkOutput("subgraph", height = "800px", width = "100%"),
      tableOutput('table'),
    )
  )
)

shinyApp(ui, server)