require(shiny)
require(visNetwork)
library(dplyr)

# Initialize the graph with these nodes/edges.  We have to assign edges an ID
# in case the user edits them later.
init.nodes.df = data.frame(id = c("foo", "bar"),
                           label = c("Foo", "Bar"),
                           stringsAsFactors = F)
init.edges.df = data.frame(id = "foobar",
                           from = "foo", 
                           to = "bar",
                           stringsAsFactors = F)

ui <- fluidPage(
  fluidRow(
    # Display two tables: one with the nodes, one with the edges.
    column(
      width = 6,
      tags$h1("Nodes in the graph:"),
      tableOutput("all_nodes"),
      tags$h1("Edges in the graph:"),
      tableOutput("all_edges")
    ),
    # The graph.
    column(
      width = 6,
      visNetworkOutput("editable_network", height = "400px")
    )
  )
)

server <- function(input, output) {

  # `graph_data` is a list of two data frames: one of nodes, one of edges.
  graph_data = reactiveValues(
    nodes = init.nodes.df,
    edges = init.edges.df
  )

  # Render the graph.
  output$editable_network <- renderVisNetwork({
    visNetwork(graph_data$nodes, graph_data$edges) %>%
      visOptions(manipulation = T)
  })

  # If the user edits the graph, this shows up in
  # `input$[name_of_the_graph_output]_graphChange`.  This is a list whose
  # members depend on whether the user added a node or an edge.  The "cmd"
  # element tells us what the user did.
  observeEvent(input$editable_network_graphChange, {
    # If the user added a node, add it to the data frame of nodes.
    if(input$editable_network_graphChange$cmd == "addNode") {
      temp = bind_rows(
        graph_data$nodes,
        data.frame(id = input$editable_network_graphChange$id,
                   label = input$editable_network_graphChange$label,
                   stringsAsFactors = F)
      )
      graph_data$nodes = temp
    }
    # If the user added an edge, add it to the data frame of edges.
    else if(input$editable_network_graphChange$cmd == "addEdge") {
      temp = bind_rows(
        graph_data$edges,
        data.frame(id = input$editable_network_graphChange$id,
                   from = input$editable_network_graphChange$from,
                   to = input$editable_network_graphChange$to,
                   stringsAsFactors = F)
      )
      graph_data$edges = temp
    }
    # If the user edited a node, update that record.
    else if(input$editable_network_graphChange$cmd == "editNode") {
      temp = graph_data$nodes
      temp$label[temp$id == input$editable_network_graphChange$id] = input$editable_network_graphChange$label
      graph_data$nodes = temp
    }