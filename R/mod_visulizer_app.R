#' visulizer_app UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_visulizer_app_ui <- function(id) {
  ns <- NS(id)
  tagList(
    actionButton(inputId = ns("open_esq_viz_app"), label = "Open Visualizer")
  )
}

#' visulizer_app Server Functions
#'
#' @noRd
mod_visulizer_app_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    observeEvent(input$open_esq_viz_app, {
      # Create temporary R script that runs the child app
      script_path <- tempfile(fileext = ".R")
      app_launch_script <- 'esqlabsR.FunctionVisualizer::run_app(options = list(launch.browser = TRUE))'
      writeLines(app_launch_script, con = script_path)

      # Start the child app in a separate R process
      system2(
        file.path(R.home("bin"), "Rscript"),
        args = c("--vanilla", shQuote(script_path)),
        wait = FALSE
      )
    })

  })
}

## To be copied in the UI
# mod_visulizer_app_ui("visulizer_app_1")

## To be copied in the server
# mod_visulizer_app_server("visulizer_app_1")
