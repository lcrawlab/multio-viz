library('shiny')
library('visNetwork')

server <- function(input, output) {
    output$network <- renderVisNetwork({
        #replace this file path with file path for your dataframe
        nodes <- read.csv(file = 'downloads/nodes2.csv', header=T, as.is=T)
        
        genes <- nodes$gene
        rownumber = 1
        len = length(genes)
        iterations = len*(len-1)/2
        edgelist <- matrix(nrow = iterations, ncol = 2)
        
        for (i in 1:(len-1)) 
        {
            val <- genes[i]
            for (j in 1:(len-i)) 
            { 
                val2 <- genes[j+i]
                edgelist[rownumber, 1] = val
                edgelist[rownumber, 2] = val2
                rownumber = rownumber + 1
            }
        }
        
        edges <- as.data.frame(edgelist)
        colnames(edges) <- c('from', 'to')
        
        nodes$title  <- nodes$name
        nodes$size   <- nodes$pip*20
        nodes$color <- ifelse(nodes$type == "DNA", "blue", ifelse(nodes$type == "RNA", "red", "purple"))
        edges$color <- "lightblue"
        
        visNetwork(nodes, edges) %>%
            visIgraphLayout() %>%
            visOptions(highlightNearest = list(enabled =TRUE, degree = 2, hover = T), nodesIdSelection = TRUE, selectedBy= "type", manipulation = TRUE)
        
    })
}

ui <- fluidPage(
    visNetworkOutput("network")
)

shinyApp(ui = ui, server = server)

