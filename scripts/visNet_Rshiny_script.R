
library('shiny')
library('visNetwork')

server <- function(input, output) {
    output$network <- renderVisNetwork({
        nodes <- read.csv(file = 'downloads/nodes.csv', header=T, as.is=T)
        links <- read.csv(file = 'downloads/edges.csv', header=T, as.is=T)
        
        vis.nodes <- nodes
        vis.links <- links
        
        vis.nodes$title  <- vis.nodes$gene.number
        vis.nodes$size   <- vis.nodes$pip.score*15
        visNetwork(vis.nodes, vis.links)    })
}

ui <- fluidPage(
    visNetworkOutput("network")
)

shinyApp(ui = ui, server = server)
