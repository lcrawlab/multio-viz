#install.packages('visNetwork')
#install.packages("shiny")
library(shiny)
library(visNetwork)
print(getwd())(.)
#source('~/multio-viz/scripts/Rshiny.R')
app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))



server <- function(input, output) {
  pip_threshold <- reactiveVal(0.5)

  observeEvent(input$slider, {
    pip_threshold()
  })
  
  output$subgraph <- renderVisNetwork({
    subgraph(pip_threshold())
    par(mar=c(1,1,1,1))
    })
}

ui <- fluidPage(
  colorbar <- renderImage("./app/www/colorbar.png"), 
  
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
