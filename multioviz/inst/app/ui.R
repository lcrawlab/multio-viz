ui <- dashboardPage(
  title = "Multioviz",
  skin = "black",
  dashboardHeader(
    tags$li(class = "dropdown",
      tags$style(".main-header {max-height: 100px}"),
      tags$style(".main-header .logo {height: 80px}")),
    title = tags$a(tags$img(
      src = "logo.png",
      height = "auto",
      width = "50%"
    )),
    titleWidth = 300
  ),
  
  dashboardSidebar(
     width = 300,
     color = 
     sidebarMenu(
          div(class = "inlay", style = "height:15px;width:100%;background-color: #ecf0f5;"),
          HTML("",sep="<br/>"), # new line
          fluidRow(align = "center", bsButton("quickstart", label = "Quickstart", icon = icon("user"), style = "success", size = 'large')),
          menuItem(
            "Visualize",
            tabName = "visualize",
            fluidRow(align = "center", bsButton("example_data_viz", label = "Example Data", style = "success", size = 'large')),
            bsModal("example_data_viz_modal", "Example Data for Visualization", "example_data_viz", size = "large",imageOutput("data_examples_vis")),
            fileInput("mol_lev_1", "Input ML1 Scores:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")),
            fileInput("mol_lev_2", "Input ML2 Scores:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")),
            fileInput("map_lev_1_2", "Input Map:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")),
            fluidRow(align = "center", bsButton("go", label = "GENERATE NETWORK", icon = icon("play-circle"), style = "danger", size = 'large')),
            hr()
          ),
          menuItem(
            "Perturb",
            tabName = "perturb",
            fluidRow(align = "center", bsButton("example_data_perturb", label = "Example Data", style = "success", size = 'large')),
            bsModal("example_data_perturb_modal", "Example Data for Perturbation", "example_data_perturb", size = "large",imageOutput("data_examples_perturb")),
            fluidRow(align = "center", bsButton("demo", label = "Load Demo Files", icon = icon("spinner", class = "spinner-box"),style = "success", size = 'large')),
            fileInput("x_model_input", "Input X:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")),
            fileInput("y_model_input", "Input y:",
                  multiple = FALSE,
                  accept = c("text/csv",
                              "text/comma-separated-values,text/plain",
                              ".csv")),
            fileInput("mask_input", "Input mask:",
                  multiple = FALSE,
                  accept = c("text/csv",
                             "text/comma-separated-values,text/plain",
                             ".csv")),
            selectInput(
              "model_type",
              label = NULL,
              choices = c(
              "Select a model" = "NA",
              "BANNs" = "banns",
              "BIOGRINN" = "biogrinn")),
            fluidRow(
              align = "center", bsButton("run_model", label = "RUN MODEL", icon = icon("play-circle"), style = "danger", size = 'large')
            ),
            fluidRow(
              align = "center", bsButton("rerun_model", label = "RERUN MODEL", icon = icon("play-circle"), style = "danger", size = 'large')),
            hr()
          )

  )),
dashboardBody(
  width = 12,
    fluidRow(
    box(
            useShinyjs(),
            selectInput("ml1_map", "Select Molecular Level 1 (ML1) Connection Type:", 
              choices = c("None", "Complete", "Sparse"), 
              selected = "None"),
            disabled(fileInput("map_lev_1", "Sparse Connections File",
                  multiple = FALSE,
                  accept = c("text/csv",
                              "text/comma-separated-values,text/plain",
                              ".csv"))),
            selectInput("ml2_map", "Select Molecular Level 2 (ML2) Connection Type:", 
              choices = c("None", "Complete", "Sparse"), 
              selected = "None"),
            disabled(fileInput("map_lev_2", "Sparse Connections File",
                  multiple = FALSE,
                  accept = c("text/csv",
                              "text/comma-separated-values,text/plain",
                              ".csv"))),
            hr(),
            selectInput("layout", "Select Graph Layout:", 
              choices = c("layout_with_sugiyama", "layout_with_kk", "layout_nicely"), 
              selected = "layout_with_kk"),
            hr(),
            chooseSliderSkin("Flat"),
            sliderInput("slider1", "Set Threholding For ML1:",
                    min = 0, max = 1, value = 0.5),
            colorbar1 <-
              tags$a(tags$img(
              src = "colorbar2.png",
              height = "auto",
              width = "100%")),
            h4("Score", align="center"),
            chooseSliderSkin("Flat"),
            sliderInput("slider2", "Set Threholding For ML2:",
                    min = 0, max = 1, value = 0.5),
            colorbar1 <-
              tags$a(tags$img(
              src = "colorbar1.png",
              height = "auto",
              width = "100%")),
            h4("Score", align="center")),
    box(visNetworkOutput("input_graph", height = "800px", width = "100%"), width = 6))
  )
)