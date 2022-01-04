#install.packages('visNetwork')
#install.packages("shiny")
library(shiny)
library(visNetwork)
library(shiny)
getwd()
#source('~/multio-viz/scripts/Rshiny.R')
source("./scripts/graph_functions.R")

server <- function(input, output) {
  pip_threshold <- reactiveVal(0)

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
      sliderInput("slider", h3("Set PiP Threhold"),
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
