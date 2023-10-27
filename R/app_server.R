#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic
  r <- reactiveValues()

  r$states <- reactiveValues()

  mod_sidebar_server("sidebar_1", r)
  mod_main_panel_server("main_panel_1", r)
}
