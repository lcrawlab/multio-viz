library(shiny)
library(visNetwork)
library(dplyr)

app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))

server <- function(input, output) {
  pip_threshold <- reactiveVal(0.5)

  observeEvent(input$slider, {
    pip_threshold()
  })
  
  output$subgraph <- renderVisNetwork({
    subgraph(pip_threshold())
    nodes <- nodes %>% mutate(font.size = 40)

    visNetwork(nodes, edges) %>%
    visNodes(label = "id", size = 100, shadow = list(enabled = TRUE, size = 10)) %>%
    visLayout(randomSeed = 12) %>%
    visIgraphLayout(layout = "layout_with_kk") %>% # layout_with_sugiyama
    # TODO: Allow for other graph layouts https://search.r-project.org/CRAN/refmans/igraph/html/layout_nicely.html
    visOptions(highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
    
    # visNetwork(res_graph$nodes, res_graph$edges) %>%
    # visIgraphLayout(layout = "layout_with_kk") %>%
    # visOptions(highlightNearest = list(enabled =TRUE, degree = 2, hover = T), 
    #             nodesIdSelection = TRUE, 
    #             selectedBy = list(variable = "group", highlight = TRUE),
    #             manipulation = TRUE)%>%
    # visEdges(hoverWidth = 3, selectionWidth = 3) %>%
    # visNodes(label = NULL, labelHighlightBold = TRUE, borderWidthSelected = 4) %>%
    #visGroups(groupname = "a", color = "orange", shape = "circle", icon = list(size = 75))
    # visGroups(groupname = "b", color = "blue", shape = "triangle", icon = list(size = 75)) 
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
        img(src="colorbar.png", align = "left", width = "250px", height = "400px"))
    ),
    
    mainPanel(
        visNetworkOutput("subgraph", height = "800px", width = "100%"),
    )
  )
)

shinyApp(ui, server)