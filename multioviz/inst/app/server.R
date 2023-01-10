server <- function(input, output, session) {
  options(shiny.maxRequestSize=30*1024^2) 
  app_dir <- getwd()
  source(paste(app_dir, "/multioviz/inst/app/scripts/helpers.R", sep = ""))

  # initialize reactive values for ML model args

  reactivesModel = reactiveValues()
  reactivesModel$X = X
  reactivesModel$y = y
  reactivesModel$mask = mask

  # initialize reactive values for visualization
  reactivesViz = reactiveValues()
  reactivesViz$ML1 = NULL
  reactivesViz$ML2 = NULL
  reactivesViz$map = NULL

  # initialize reactives for rank thresholding
  score_threshold_ml1 <- reactive(input$slider1)
  score_threshold_ml2 <- reactive(input$slider2)
  
  # initialize reactive values to make graph
  reactivesGraph = reactiveValues()
  reactivesGraph$nodes = NULL
  reactivesGraph$edges = NULL

  # initialize reactive values to track graph changes
  reactivesPerturb = reactiveValues()
  reactivesPerturb$addedNodesML1 = list()
  reactivesPerturb$addedNodesML2 = list()
  reactivesPerturb$addedEdges = list()
  reactivesPerturb$deletedNodesML1 = list()
  reactivesPerturb$deletedNodesML2 = list()
  reactivesPerturb$deletedEdges = list()

  observe({
  if(demo){
    # if no arguments, run demo
    source(paste(app_dir, "/multioviz/inst/app/scripts/perturb.R", sep = ""))
    
    # BANNs is run
    lst = runModel(reactivesModel$X, reactivesModel$y, reactivesModel$mask)
  }
  else{
    # run input computational model: depends on user defined function that runs ML model and converts output to required ML1, ML2, map
    source(userScript)
    if(is.null(mask)){
      lst = runModel(reactivesModel$X, reactivesModel$y)
    }
    else{
      lst = runModel(reactivesModel$X, reactivesModel$y, reactivesModel$mask)
    }
  }
  
  # set ML1, ML2, map based on model outputs
  reactivesViz$ML1 = lst$ML1
  reactivesViz$ML2 = lst$ML2
  reactivesViz$map = lst$map
  })

  # visualize graph
  observeEvent(
    req((!is.null(reactivesViz$ML1)) & (!is.null(reactivesViz$ML2)) & (!is.null(reactivesViz$map))),
    {
      reactivesGraph$nodes <- make_nodes(reactivesViz$ML1, reactivesViz$ML2, score_threshold_ml1(), score_threshold_ml2())
      #reactivesGraph$edges <- make_edges(reactivesViz$ML1, reactivesViz$ML2, reactivesViz$map)
      reactivesViz$map['arrows'] = 'to'
      reactivesGraph$edges <- reactivesViz$map
      output$input_graph <- make_graph(reactivesGraph$nodes, reactivesGraph$edges, input$layout)
  })

  observeEvent(input$input_graph_graphChange, {
    print(input$input_graph_graphChange$cmd)
    # If the user added a node, add it to the data frame of nodes.
    if(input$input_graph_graphChange$cmd == "addNode") {
      if(input$input_graph_graphChange$group == 'ML1') {
        reactivesPerturb$addedNodesML1 = append(reactivesPerturb$addedNodesML1, input$input_graph_graphChange$id)
      }
      if(input$input_graph_graphChange$group == 'ML2') {
        reactivesPerturb$addedNodesML2 = append(reactivesPerturb$addedNodesML2, input$input_graph_graphChange$id)
      }
    }

    # If the user added an edge, add it to the data frame of edges.
    else if(input$input_graph_graphChange$cmd == "addEdge") {
      row = c(input$input_graph_graphChange$id, input$input_graph_graphChange$from, input$input_graph_graphChange$to)
      reactivesPerturb$addedEdges = append(reactivesPerturb$addedEdges, row)
    }

    # If the user edited a node, update that record.
    else if(input$input_graph_graphChange$cmd == "editNode") {
      temp = reactivesGraph$nodes
      temp$label[temp$id == input$input_graph_graphChange$id] = input$input_graph_graphChange$label
      reactivesGraph$nodes = temp
    }

    # If the user edited an edge, update that record.
    else if(input$input_graph_graphChange$cmd == "editEdge") {
      temp = reactivesGraph$edges
      temp$from[temp$id == input$input_graph_graphChange$id] = input$input_graph_graphChange$from
      temp$to[temp$id == input$editableinput_graph_graphChange_network_graphChange$id] = input$input_graph_graphChange$to
      reactivesGraph$edges = temp
    }

    # If the user deleted something, remove those records.
    else if(input$input_graph_graphChange$cmd == "deleteElements") {
      for(node.id in input$input_graph_graphChange$nodes) {
        r = reactivesGraph$nodes[reactivesGraph$nodes$id == node.id,]
        if (r$group == 'ML1') {
          reactivesPerturb$deletedNodesML1 = append(reactivesPerturb$deletedNodesML1, node.id)
        }
        if (r$group == 'ML2') {
          reactivesPerturb$deletedNodesML2 = append(reactivesPerturb$deletedNodesML2, node.id)       
        }
      }
      for(edge.id in input$input_graph_graphChange$edges) {
        temp = reactivesGraph$edges[reactivesGraph$edges$id == edge.id,]
        row = c(edge.id, temp$from, temp$to)
        reactivesPerturb$addedEdges = c(reactivesPerturb$addedEdges, row)
      }
    }
  })

  # rerun model with changes (depends on user defined function that takes in lists of changes and making changes to ML model inputs)
  observeEvent(input$rerun_model, {

    reactivesModel$X = reactivesModel$X[,!colnames(reactivesModel$X) %in% reactivesPerturb$deletedNodesML1]
    if(is.null(mask)){
      lst = runModel(reactivesModel$X, reactivesModel$y)
    }
    else{
      reactivesModel$mask = reactivesModel$mask[!rownames(reactivesModel$mask) %in% reactivesPerturb$deletedNodesML1, !colnames(reactivesModel$mask) %in% reactivesPerturb$deletedNodesML2]
      for(n in reactivesPerturb$deletedEdges) {
        if((n[2] %in% rownames(reactivesModel$mask)) & (n[3] %in% colnames(reactivesModel$mask))) {
          reactivesModel$mask[n[2], n[3]] = 0
        }
      }
      lst = runModel(reactivesModel$X, reactivesModel$y, reactivesModel$mask)
    }

    reactivesViz$ML1 = lst$ML1
    reactivesViz$ML2 = lst$ML2
    reactivesViz$map = lst$map

    reactivesGraph$nodes <- make_nodes(reactivesViz$ML1, reactivesViz$ML2, score_threshold_ml1(), score_threshold_ml2())
    #reactivesGraph$edges <- make_edges(reactivesViz$ML1, reactivesViz$ML2, reactivesViz$map)
    reactivesGraph$edges <- reactivesViz$map
    output$input_graph <- make_graph(reactivesGraph$nodes, reactivesGraph$edges)
  })
  
  # graph layout reactive
  graphLayout <- reactive({
    req(isTruthy(input$run_model) || isTruthy(input$rerun_model))
    switch(input$layout,
           "layout_with_sugiyama" = layout$x,
           "layout_with_kk" = layout$y,
           "layout_nicely" = layout$z,
           "Please Select a Layout" = NULL)
  })
 
  # UI stuff
  output$logo <- renderImage({
    list(src = paste(app_dir, "/multioviz/inst/app/www/logo.png", sep = ""), width = "20%", height = "35%", alt = "Alternate text")
  }, deleteFile = FALSE)
   
  output$colorbar1 <- renderImage({
    list(src = paste(app_dir, "/multioviz/inst/app/www/colorbar1.png", sep = ""), width = "100%", height = "25%", alt = "Alternate text")
  }, deleteFile = FALSE)
   
  output$colorbar2 <- renderImage({
    list(src = paste(app_dir, "/multioviz/inst/app/www/colorbar2.png", sep = ""), width = "100%", height = "25%", alt = "Alternate text")
  }, deleteFile = FALSE)


  observeEvent("", {
    showModal(modalDialog(
      includeHTML(paste(app_dir, "/multioviz/inst/app/www/intro_text.html", sep = "")),
      easyClose = TRUE,
    ))
  })

  observeEvent(input$quickstart, {
    showModal(modalDialog(
      includeHTML(paste(app_dir, "/multioviz/inst/app/www/intro_text2.html", sep = "")),
      easyClose = TRUE,
      #footer = actionButton(inputId = "example_data_viz", label = "VIEW EXAMPLE DATA", icon = icon("info-circle"))
    ))
  }) 
}