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
      width = "60%"
    )),
    titleWidth = 300
  ),
  
dashboardSidebar(width = 1),

dashboardBody(
  width = 12,
    fluidRow(
    box(
            useShinyjs(),
            fluidRow(align = "center", bsButton("quickstart", label = "Quickstart", icon = icon("user"), style = "success", size = 'large')),
            selectInput("layout", "Select Graph Layout:", 
              choices = c("layout_with_sugiyama", "layout_with_kk", "layout_nicely"), 
              selected = "layout_with_kk"),
            chooseSliderSkin("Flat"),
            sliderInput("slider1", "Set Threholding For ML1:",
                    min = 0, max = 1, value = 0),
            colorbar1 <-
              tags$a(tags$img(
              src = "colorbarML1.png",
              height = "auto",
              width = "100%")),
            h4("Score", align="center"),
            chooseSliderSkin("Flat"),
            sliderInput("slider2", "Set Threholding For ML2:",
                    min = 0, max = 1, value = 0),
            colorbar2 <-
              tags$a(tags$img(
              src = "colorbarML2.png",
              height = "auto",
              width = "100%")),
            h4("Score", align="center"),
            fluidRow(align = "center", bsButton("run_model", label = "SET THRESHOLD", style = "danger", size = 'large')),
            hr(),
            fluidRow(align = "center", bsButton("rerun_model", label = "RERUN METHOD", style = "danger", size = 'large')),
            width = 4),
    box(visNetworkOutput("input_graph", height = "800px", width = "100%"), width = 8))
  )
)