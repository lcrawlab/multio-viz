#install.packages('visNetwork')
#install.packages("shiny")
library(shiny)
library(visNetwork)
library(shiny)
getwd()
source('~/multio-viz/scripts/new_visnet.R')
#source("./scripts/new_visnet.R")

# Ashley's suggestions:
# Go to file in top left corner in R Studio.
# Select save with encoding
# select UTF-8
# ref: https://stackoverflow.com/questions/46897384/shiny-app-error-sourcing-debug

server <- function(input, output) {
  pip_threshold <- reactiveVal(0)
  
 ''' output$colorbar1 <- renderPlot({
    color.bar(colorRampPalette(c("lightblue", "steelblue4"))(100), 0, 1)
  })
  
  output$colorbar2 <- renderPlot({
    color.bar(colorRampPalette(c("yellow2","goldenrod","darkred"))(100), 0, 1)
  })'''

  observeEvent(input$slider, {
    pip_threshold()
  })
  
  output$subgraph <- renderVisNetwork({
    subgraph(pip_threshold())
    })
}

ui <- fluidPage(
  colorbar <- readImage("/Users/helen/Downloads/colorbar"), 
  
  titlePanel("Multioviz"),
  
  sidebarLayout(
    sidebarPanel(
      sliderInput("slider", h3("Set PIP Threhold"),
                  min = 0, max = 1, value = 0)
    ),
    mainPanel(
      fluidRow(
        imageOutput("colorbar")
        
      ),
      fluidRow(
        visNetworkOutput("subgraph")
      )
    )
  )
)

shinyApp(ui = ui, server = server)
