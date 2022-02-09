library(shiny)
library(visNetwork)
app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))

server <- function(input, output) {
  pip_threshold <- reactiveVal(0.5)

  observeEvent(input$slider, {
    pip_threshold()
  })
  
  output$subgraph <- renderVisNetwork({
    subgraph(pip_threshold())
    })
}

ui <- fluidPage(  
  titlePanel("Multioviz"),
  
  sidebarLayout(
    sidebarPanel(
      fluidRow(
      sliderInput("slider", h3("Set PiP Threhold"),
                           min = 0, max = 1, value = 0)),
      fluidRow(
        img(src="colorbar.png", align = "right", width = 250, height = 400))
    ),
    
    mainPanel(
        visNetworkOutput("subgraph"),
    )
  )
)

shinyApp(ui, server)