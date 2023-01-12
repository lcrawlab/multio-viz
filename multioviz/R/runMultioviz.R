#' Run Shiny App
#'
#' This function takes in parameters for a computational model that performs feature selection and prioritization and the wrapper script for the method and runs the multioviz Shiny application
#'
#' @param X N x J matrix where N is the number of samples and J is the size of the set of molecular variables for molecular level one
#' @param y N-dimensional matrix of quantitative traits
#' @param mask J x G matrix of pre-defined annotations where J is the number of molecular variables for molecular level 1 and G is the number of molecular variables for molecular level 2
#' @export
runMultioviz <- function(X = NULL, y = NULL, mask = NULL, userScript = NULL){

    if(is.null(X) & is.null(y) & is.null(mask)){
        X <- multioviz:::X_test
        y <- multioviz:::y_test
        mask <- multioviz:::mask_test
    }

    if(is.null(userScript)){
        demo <- TRUE
    }
    else{
        demo <- FALSE
    }

    appDir <- system.file("app", "app.R", package = "multioviz")
    if (appDir == "") {
        stop("Could not find directory. Try re-installing `multioviz`.", call. = FALSE)
    }

    ui <- server <- NULL # avoid NOTE about undefined globals
    source(appDir, local = TRUE, chdir = TRUE)
    
    server_env <- environment(server)
    server_env$X <- X
    server_env$y <- y
    server_env$mask <- mask
    server_env$userScript <- userScript
    server_env$demo <- demo

    hi <- shiny::shinyApp(ui, server)
    shiny::runApp(hi)
}