library(shiny)
library(visNetwork)
library(dplyr)
library(igraph)
library(shinyBS)
library(shinythemes)
library(shinythemes)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyWidgets)
library(shinyjs)
library(shinyalert)
library(data.table)

app_dir <- getwd()
source(paste(app_dir, "/scripts/helpers.R", sep = ""))
source(paste(app_dir, "/scripts/perturb.R", sep = ""))

server <- function(input, output, session) {
  options(shiny.maxRequestSize = 10000 * 1024^2)
  Sys.setenv("R_MAX_VSIZE" = 16e9)

  # initialize reactives for method input
  X_file <- reactive(input$x_model_input$datapath)
  y_file <- reactive(input$y_model_input$datapath)
  mask_file <- reactive(input$mask_input$datapath)
  demo <- reactive(input$demo)
  demo_viz <- reactive(input$demo_viz)

  reactivesModel <- reactiveValues()
  reactivesModel$X <- NULL
  reactivesModel$y <- NULL
  reactivesModel$mask <- NULL

  # initialize reactive for direct visualization
  reactivesViz <- reactiveValues()
  reactivesViz$ML1 <- NULL
  reactivesViz$ML2 <- NULL
  reactivesViz$map <- NULL

  reactiveMapML1 <- reactiveVal()
  reactiveMapML2 <- reactiveVal()

  # reactive expression for rank thresholding
  score_threshold_ml1 <- reactive(input$slider1)
  score_threshold_ml2 <- reactive(input$slider2)

  reactivesGraph <- reactiveValues()
  reactivesGraph$nodes <- NULL
  reactivesGraph$edges <- NULL

  reactivesPerturb <- reactiveValues()
  reactivesPerturb$addedNodesML1 <- list()
  reactivesPerturb$addedNodesML2 <- list()
  reactivesPerturb$addedEdges <- list()

  reactivesPerturb$deletedNodesML1 <- list()
  reactivesPerturb$deletedNodesML2 <- list()
  reactivesPerturb$deletedEdges <- list()

  # set X, y, and mask depending on whether demo is selected
  observe({
    if (isTruthy(input$demo)) {
      X_matrix <- as.matrix(read.table(paste(app_dir, "/data/Xtest.txt", sep = "")), )
    } else if (isTruthy(input$x_model_input)) {
      X_matrix <- as.matrix(read.table(X_file()))
    } else {
      X_matrix <- NULL
    }
    if (isTruthy(input$demo)) {
      y_matrix <- as.matrix(read.table(paste(app_dir, "/data/ytest.txt", sep = "")))
    } else if (isTruthy(input$y_model_input)) {
      y_matrix <- as.matrix(read.table(y_file()))
    } else {
      y_matrix <- NULL
    }
    if (isTruthy(input$demo)) {
      mask_matrix <- as.matrix(read.table(paste(app_dir, "/data/masktest.txt", sep = "")))
    } else if (isTruthy(input$mask_input)) {
      # mask_matrix <- as.matrix(read.table(mask_file(), header = TRUE, row.names = 1, sep='\t'))
      mask_matrix <- as.matrix(fread(mask_file(), sep = "\t", header=TRUE),rownames = 1)
      print(colnames(mask_matrix))
      print(dim(mask_matrix))
    } else {
      mask_matrix <- NULL
    }

    # set SNP and gene labels if mask does not have row/column names
    if (!is.null(mask_matrix) & (isTruthy(input$mask_labels) | isTruthy(input$demo))) {
      s_names <- paste("s", 1:dim(mask_matrix)[1], sep = "")
      g_names <- paste("g", 1:dim(mask_matrix)[2], sep = "")
      rownames(mask_matrix) <- s_names
      colnames(mask_matrix) <- g_names
    }

    if (!is.null(X_matrix) & !is.null(mask_matrix)) {
      colnames(X_matrix) <- rownames(mask_matrix)
    }

    reactivesModel$X <- X_matrix
    reactivesModel$y <- y_matrix
    reactivesModel$mask <- mask_matrix
  })

  # read in viz data if RUN button pressed for viz
  observeEvent(req(isTruthy(input$go)), {
    if (isTruthy(input$demo_viz)) {
      reactivesViz$ML1 <- as.data.frame(read.csv(
        paste(app_dir, "/data/simple_ml1.csv", sep = ""),
        sep = ",", header = TRUE
      ), stringsAsFactors = FALSE)
      reactivesViz$ML2 <- as.data.frame(read.csv(
        paste(app_dir, "/data/simple_ml2.csv", sep = ""),
        sep = ",", header = TRUE
      ), stringsAsFactors = FALSE)
      reactivesViz$map <- as.data.frame(read.csv(
        paste(app_dir, "/data/simple_map_ml1_ml2.csv", sep = ""),
        sep = ",", header = TRUE
      ), stringsAsFactors = FALSE)
    } else {
      reactivesViz$ML1 <- as.data.frame(read.csv(
        file = input$mol_lev_1$datapath,
        sep = ",",
        header = TRUE
      ), stringsAsFactors = FALSE)
      reactivesViz$ML2 <- as.data.frame(read.csv(
        file = input$mol_lev_2$datapath,
        sep = ",",
        header = TRUE
      ), stringsAsFactors = FALSE)
      reactivesViz$map <- as.data.frame(read.csv(
        file = input$map_lev_1_2$datapath,
        sep = ",",
        header = TRUE
      ), stringsAsFactors = FALSE)
    }
  })

  # if RUN pressed under perturb dropdown, run BANN method and sets viz reactives
  observeEvent(req(isTruthy(input$run_model)), {
    shinyalert(
      "
      Performing feature selection and prioritization...
      "
    )
    lst <- runMethod(reactivesModel$X, reactivesModel$mask, reactivesModel$y)

    reactivesViz$ML1 <- lst$ML1
    reactivesViz$ML2 <- lst$ML2
    reactivesViz$map <- lst$map
  })

  # creates nodes and edges and visualizes graph object when RUN is pressed
  observeEvent(
    req(((isTruthy(input$run_model)) | (isTruthy(input$go))) & ((!is.null(reactivesViz$ML1)) & (!is.null(reactivesViz$ML2)) & (!is.null(reactivesViz$map)))),
    {
      # makes nodes
      if (!is.null(reactivesViz$ML1) && !is.null(reactivesViz$ML2)) {
        reactivesGraph$nodes <- make_nodes(reactivesViz$ML1, reactivesViz$ML2, score_threshold_ml1(), score_threshold_ml2())
      } else {
        print("No nodes")
      }

      # makes edges
      if (input$ml1_map == "None") {
        edgelist_ml1 <- data.frame(matrix(ncol = 3, nrow = 0))
        colnames(edgelist_ml1) <- c("from", "to", "arrows")
      } else if (input$ml1_map == "Complete") {
        req(!is.null(reactivesViz$ML1))
        edgelist_ml1 <- complete_edges(reactivesViz$ML1)
        edgelist_ml1["arrows"] <- FALSE
      } else if ((input$ml1_map == "Sparse") & (isTruthy(input$map_lev_1))) {
        df_withinmap_lev_1 <- as.data.frame(read.csv(
          file = input$map_lev_1$datapath,
          sep = ",",
          header = TRUE
        ), stringsAsFactors = FALSE)
        edgelist_ml1 <- df_withinmap_lev_1
        edgelist_ml1["arrows"] <- FALSE
      } else {
        edgelist_ml1 <- data.frame(matrix(ncol = 3, nrow = 0))
        colnames(edgelist_ml1) <- c("from", "to", "arrows")
      }

      if (input$ml2_map == "None") {
        edgelist_ml2 <- data.frame(matrix(ncol = 3, nrow = 0))
        colnames(edgelist_ml2) <- c("from", "to", "arrows")
      } else if (input$ml2_map == "Complete") {
        req(!is.null(reactivesViz$ML2))
        edgelist_ml2 <- complete_edges(reactivesViz$ML2)
        edgelist_ml2["arrows"] <- FALSE
      } else if ((input$ml2_map == "Sparse") & (isTruthy(input$map_lev_2))) {
        df_withinmap_lev_2 <- as.data.frame(read.csv(
          file = input$map_lev_2$datapath,
          sep = ",",
          header = TRUE
        ), stringsAsFactors = FALSE)
        edgelist_ml2 <- df_withinmap_lev_2
        edgelist_ml2["arrows"] <- FALSE
      } else {
        edgelist_ml2 <- data.frame(matrix(ncol = 3, nrow = 0))
        colnames(edgelist_ml2) <- c("from", "to", "arrows")
      }
      edges <- rbind(edgelist_ml1, edgelist_ml2)
      reactivesViz$map["arrows"] <- "to"
      reactivesGraph$edges <- rbind(edges, reactivesViz$map)

      scores = paste0("Score: ", reactivesGraph$nodes$score)
      reactivesGraph$nodes$title = scores

      # makes graph
      if (!is.null(reactivesGraph$nodes) || !is.null(reactivesGraph$edges)) {
        output$input_graph <- renderVisNetwork({
          visNetwork(reactivesGraph$nodes, reactivesGraph$edges) %>%
            visNodes(label = "id", size = 40, shadow = list(enabled = TRUE, size = 10)) %>%
            visLayout(randomSeed = 12) %>%
            visIgraphLayout(input$layout) %>%
            visOptions(manipulation = list(enabled = TRUE, addNodeCols = c("id", "group"), addEdgeCols = c("from", "to", "id")), highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
            visExport(type = "png", name = "network", label = paste0("Export as png"), background = "#fff", float = "left", style = NULL, loadDependencies = TRUE)
        })
      }
    }
  )

  # keeps track of GRN perturbation
  observeEvent(input$input_graph_graphChange, {
    # If the user added a node, add it to the data frame of nodes.
    if (input$input_graph_graphChange$cmd == "addNode") {
      if (input$input_graph_graphChange$group == "ML1") {
        reactivesPerturb$addedNodesML1 <- append(reactivesPerturb$addedNodesML1, input$input_graph_graphChange$id)
      }
      if (input$input_graph_graphChange$group == "ML2") {
        reactivesPerturb$addedNodesML2 <- append(reactivesPerturb$addedNodesML2, input$input_graph_graphChange$id)
      }
    }

    # If the user added an edge, add it to the data frame of edges.
    else if (input$input_graph_graphChange$cmd == "addEdge") {
      row <- c(input$input_graph_graphChange$id, input$input_graph_graphChange$from, input$input_graph_graphChange$to)
      reactivesPerturb$addedEdges <- append(reactivesPerturb$addedEdges, row)
    }

    # If the user edited a node, update that record.
    else if (input$input_graph_graphChange$cmd == "editNode") {
      temp <- reactivesGraph$nodes
      temp$label[temp$id == input$input_graph_graphChange$id] <- input$input_graph_graphChange$label
      reactivesGraph$nodes <- temp
    }

    # If the user edited an edge, update that record.
    else if (input$input_graph_graphChange$cmd == "editEdge") {
      temp <- reactivesGraph$edges
      temp$from[temp$id == input$input_graph_graphChange$id] <- input$input_graph_graphChange$from
      temp$to[temp$id == input$editableinput_graph_graphChange_network_graphChange$id] <- input$input_graph_graphChange$to
      reactivesGraph$edges <- temp
    }

    # If the user deleted something, remove those records.
    else if (input$input_graph_graphChange$cmd == "deleteElements") {
      for (node.id in input$input_graph_graphChange$nodes) {
        r <- reactivesGraph$nodes[reactivesGraph$nodes$id == node.id, ]
        if (r$group == "ML1") {
          reactivesPerturb$deletedNodesML1 <- append(reactivesPerturb$deletedNodesML1, node.id)
        }
        if (r$group == "ML2") {
          reactivesPerturb$deletedNodesML2 <- append(reactivesPerturb$deletedNodesML2, node.id)
        }
      }
      for (edge.id in input$input_graph_graphChange$edges) {
        temp <- reactivesGraph$edges[reactivesGraph$edges$id == edge.id, ]
        row <- c(edge.id, temp$from, temp$to)
        reactivesPerturb$addedEdges <- c(reactivesPerturb$addedEdges, row)
      }
    }
  })

  # generates new GRN if RERUN is clicked
  observeEvent(input$rerun_model, {
    # change reactivesModel based on reactivesPerturb
    reactivesModel$X <- reactivesModel$X[, !colnames(reactivesModel$X) %in% reactivesPerturb$deletedNodesML1]
    reactivesModel$mask <- reactivesModel$mask[!rownames(reactivesModel$mask) %in% reactivesPerturb$deletedNodesML1, !colnames(reactivesModel$mask) %in% reactivesPerturb$deletedNodesML2]
    for (n in reactivesPerturb$deletedEdges) {
      reactivesModel$mask[n[2], n[3]] <- 0
      # if ((n[2] %in% rownames(reactivesModel$mask)) & (n[3] %in% colnames(reactivesModel$mask))) {
      #   reactivesModel$mask[n[2], n[3]] <- 0
      # }
    }

    shinyalert(
      "
      Performing feature selection and prioritization...
      "
    )

    # reruns BANNs with new X, y, and mask
    lst <- runMethod(reactivesModel$X, reactivesModel$mask, reactivesModel$y)
    reactivesViz$ML1 <- lst$ML1
    reactivesViz$ML2 <- lst$ML2
    reactivesViz$map <- lst$map

    # makes new nodes and edges
    if (!is.null(reactivesViz$ML1) && !is.null(reactivesViz$ML2)) {
      reactivesGraph$nodes <- make_nodes(reactivesViz$ML1, reactivesViz$ML2, score_threshold_ml1(), score_threshold_ml2())
    } else {
      print("No nodes")
    }

    if (input$ml1_map == "None") {
      edgelist_ml1 <- data.frame(matrix(ncol = 3, nrow = 0))
      colnames(edgelist_ml1) <- c("from", "to", "arrows")
    } else if (input$ml1_map == "Complete") {
      req(!is.null(reactivesViz$ML1))
      edgelist_ml1 <- complete_edges(reactivesViz$ML1)
      edgelist_ml1["arrows"] <- FALSE
    } else if ((input$ml1_map == "Sparse") & (isTruthy(input$map_lev_1))) {
      df_withinmap_lev_1 <- as.data.frame(read.csv(
        file = input$map_lev_1$datapath,
        sep = ",",
        header = TRUE
      ), stringsAsFactors = FALSE)
      edgelist_ml1 <- df_withinmap_lev_1
      edgelist_ml1["arrows"] <- FALSE
    } else {
      edgelist_ml1 <- data.frame(matrix(ncol = 3, nrow = 0))
      colnames(edgelist_ml1) <- c("from", "to", "arrows")
    }

    if (input$ml2_map == "None") {
      edgelist_ml2 <- data.frame(matrix(ncol = 3, nrow = 0))
      colnames(edgelist_ml2) <- c("from", "to", "arrows")
    } else if (input$ml2_map == "Complete") {
      req(!is.null(reactivesViz$ML2))
      edgelist_ml2 <- complete_edges(reactivesViz$ML2)
      edgelist_ml2["arrows"] <- FALSE
    } else if ((input$ml2_map == "Sparse") & (isTruthy(input$map_lev_2))) {
      df_withinmap_lev_2 <- as.data.frame(read.csv(
        file = input$map_lev_2$datapath,
        sep = ",",
        header = TRUE
      ), stringsAsFactors = FALSE)
      edgelist_ml2 <- df_withinmap_lev_2
      edgelist_ml2["arrows"] <- FALSE
    } else {
      edgelist_ml2 <- data.frame(matrix(ncol = 3, nrow = 0))
      colnames(edgelist_ml2) <- c("from", "to", "arrows")
    }
    reactivesViz$map["arrows"] <- "to"
    edges <- rbind(edgelist_ml1, edgelist_ml2)
    reactivesGraph$edges <- rbind(edges, reactivesViz$map)

    # visualize new GRN
    if (!is.null(reactivesGraph$nodes) || !is.null(reactivesGraph$edges)) {
      output$input_graph <- renderVisNetwork({
        visNetwork(reactivesGraph$nodes, reactivesGraph$edges) %>%
          visNodes(label = "id", size = 40, shadow = list(enabled = TRUE, size = 10)) %>%
          visLayout(randomSeed = 12) %>%
          visIgraphLayout(input$layout) %>%
          visOptions(manipulation = list(enabled = TRUE, addNodeCols = c("id", "group"), addEdgeCols = c("from", "to", "id")), highlightNearest = TRUE, nodesIdSelection = list(enabled = TRUE)) %>%
          visExport(type = "pdf", name = "network", label = paste0("Export as png"), background = "#fff", float = "left", style = NULL, loadDependencies = TRUE)
      })
    }
  })

  # dropdown to select graph layout
  graphLayout <- reactive({
    req(isTruthy(input$run_model) || isTruthy(input$rerun_model))
    switch(input$layout,
      "layout_with_sugiyama" = layout$x,
      "layout_with_kk" = layout$y,
      "layout_nicely" = layout$z,
      "Please Select a Layout" = NULL
    )
  })

  # only allow upload of within ML map if sparse selected
  observeEvent(input$ml1_map, {
    if (input$ml1_map == "Sparse") {
      enable("map_lev_1")
    }
  })

  observeEvent(input$ml2_map, {
    if (input$ml2_map == "Sparse") {
      enable("map_lev_2")
    }
  })

  # UI stuff
  observeEvent("", {
    showModal(modalDialog(
      includeHTML("./www/intro_text.html"),
      easyClose = TRUE,
    ))
  })

  observeEvent(input$quickstart, {
    showModal(modalDialog(
      includeHTML("./www/intro_text2.html"),
      easyClose = TRUE,
    ))
  })

  observeEvent(input$example_data_viz, {
    showModal(modalDialog(
      title = "Example Data for Visualization",
      HTML('<img src="example_data_viz.png" style="width:800px" class = "center"/>'),
      size = "l",
      easyClose = TRUE,
    ))
  })

  observeEvent(input$example_data_perturb, {
    showModal(modalDialog(
      title = "Example Data for Perturbation",
      HTML('<img src="example_data_perturb.png" style="width:800px" class = "center"/>'),
      size = "l",
      easyClose = TRUE,
    ))
  })

  # shinyalerts
  observeEvent(req(isTruthy(input$x_model_input) & isTruthy(input$y_model_input) & isTruthy(input$mask_input)), {
    shinyalert(
      "Input Files Uploaded",
      "X, y, and mask are loaded.
      1) Customize within molecular level mapping.
      2) Set thresholding.
      3) Choose layout.
      4) Click RUN to generate GRN",
      type = "success"
    )
  })

  observeEvent(input$demo, {
    disable("x_model_input")
    disable("y_model_input")
    disable("mask_input")

    shinyalert(
      "Demo Files Uploaded",
      "X, y, and mask are loaded.

      Next Steps:
      1) Click RUN to generate GRN.
      2) Perturb GRN and click RERUN to test hypothesis in-silico

      Optional Changes:
      a) Customize within molecular level mapping.
      b) Set thresholding.
      c) Choose layout
      
      For a) and b), click RUN to view changes
      ",
      type = "success"
    )
  })

  observeEvent(input$demo_viz, {
    disable("mol_lev_1")
    disable("mol_lev_2")
    disable("map_lev_1_2")

    shinyalert(
      "Demo Files Uploaded",
      "ML1, ML2, and map are loaded.
      Click RUN to visualize GRN.

      Optional Changes:
      a) Customize within molecular level mapping.
      b) Set thresholding.
      c) Choose layout
      
      For a) and b), click RUN to view changes
      ",
      type = "success"
    )
  })
}

ui <- dashboardPage(
  title = "Multioviz",
  skin = "black",
  dashboardHeader(
    tags$li(
      class = "dropdown",
      tags$style(".main-header {max-height: 100px}"),
      tags$style(".main-header .logo {height: 80px}")
    ),
    title = tags$a(tags$img(
      src = "logo.png",
      height = "auto",
      width = "60%"
    )),
    titleWidth = 300
  ),
  dashboardSidebar(
    width = 300,
    color =
      sidebarMenu(
        div(class = "inlay", style = "height:15px;width:100%;background-color: #ecf0f5;"),
        HTML("", sep = "<br/>"), # new line
        fluidRow(align = "center", bsButton("quickstart", label = "Quickstart", style = "success", size = "medium")),
        menuItem(
          "Visualize",
          tabName = "visualize",
          fluidRow(align = "center", bsButton("example_data_viz", label = "Data Format", style = "success", size = "medium")),
          fluidRow(align = "center", bsButton("demo_viz", label = "Load Demo Files", style = "success", size = "medium")),
          fileInput("mol_lev_1", "Input ML1 Scores:",
            multiple = FALSE,
            accept = c(
              "text/csv",
              "text/comma-separated-values,text/plain",
              ".csv"
            )
          ),
          fileInput("mol_lev_2", "Input ML2 Scores:",
            multiple = FALSE,
            accept = c(
              "text/csv",
              "text/comma-separated-values,text/plain",
              ".csv"
            )
          ),
          fileInput("map_lev_1_2", "Input Between Molecular Level Map:",
            multiple = FALSE,
            accept = c(
              "text/csv",
              "text/comma-separated-values,text/plain",
              ".csv"
            )
          ),
          fluidRow(align = "center", bsButton("go", label = "RUN", style = "danger", size = "medium")),
          hr()
        ),
        menuItem(
          "Perturb",
          tabName = "perturb",
          fluidRow(align = "center", bsButton("example_data_perturb", label = "Data Format", style = "success", size = "medium")),
          fluidRow(align = "center", bsButton("demo", label = "Load Demo Files", style = "success", size = "medium")),
          fileInput("x_model_input", "Input X:",
            multiple = FALSE,
            accept = c(
              "text/csv",
              "text/comma-separated-values,text/plain",
              ".csv"
            )
          ),
          fileInput("y_model_input", "Input y:",
            multiple = FALSE,
            accept = c(
              "text/csv",
              "text/comma-separated-values,text/plain",
              ".csv"
            )
          ),
          fileInput("mask_input", "Input between ML mask:",
            multiple = FALSE,
            accept = c(
              "text/csv",
              "text/comma-separated-values,text/plain",
              ".csv"
            )
          ),
          checkboxInput("mask_labels", "Check if mask does not have row and column names", FALSE),
          fluidRow(
            align = "center", bsButton("run_model", label = "RUN", style = "danger", size = "medium")
          ),
          fluidRow(
            align = "center", bsButton("rerun_model", label = "RERUN", style = "danger", size = "medium")
          ),
          hr()
        )
      )
  ),
  dashboardBody(
    width = 12,
    fluidRow(
      box(
        useShinyjs(),
        h5("Customize map type for within a molecular level (ML) and click RUN", align = "center"),
        selectInput("ml1_map", "Set ML1 map type:",
          choices = c("None", "Complete", "Sparse"),
          selected = "None"
        ),
        disabled(fileInput("map_lev_1", "If 'sparse' connections chosen above, upload mapping file:",
          multiple = FALSE,
          accept = c(
            "text/csv",
            "text/comma-separated-values,text/plain",
            ".csv"
          )
        )),
        selectInput("ml2_map", "Select ML2 map type:",
          choices = c("None", "Complete", "Sparse"),
          selected = "None"
        ),
        disabled(fileInput("map_lev_2", "If 'sparse' connections chosen above, upload mapping file:",
          multiple = FALSE,
          accept = c(
            "text/csv",
            "text/comma-separated-values,text/plain",
            ".csv"
          )
        )),
        hr(),
        h5("Threshold features by statistical significance and click RUN", align = "center"),
        chooseSliderSkin("Flat"),
        sliderInput("slider1", "Set ML1 threshold:",
          min = 0, max = 1, value = 0.5
        ),
        colorbar1 <-
          tags$a(tags$img(
            src = "colorbar2.png",
            height = "auto",
            width = "100%"
          )),
        h6("Score", align = "center"),
        chooseSliderSkin("Flat"),
        sliderInput("slider2", "Set ML2 threshold:",
          min = 0, max = 1, value = 0.5
        ),
        colorbar1 <-
          tags$a(tags$img(
            src = "colorbar1.png",
            height = "auto",
            width = "100%"
          )),
        h6("Score", align = "center"),
        hr(),
        h5("Change gene regulatory network (GRN) layout", align = "center"),
        selectInput("layout", "Select layout:",
          choices = c("layout_with_sugiyama", "layout_with_kk", "layout_nicely"),
          selected = "layout_with_kk"
        ),
        width = 4,
        collapsible = TRUE,
        collapsed = FALSE
      ),
      box(visNetworkOutput("input_graph", height = "800px", width = "100%"), width = 8)
    )
  )
)

shinyApp(ui, server)