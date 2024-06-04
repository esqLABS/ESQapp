#' sidebar UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_sidebar_ui <- function(id) {
  ns <- NS(id)
  bslib::sidebar(
    mod_import_ui(ns("import_project_configuration_1")),
    hr(),
    mod_export_ui(ns("export_1"))
  )
}

#' sidebar Server Functions
#'
#' @noRd
mod_sidebar_server <- function(id, r, DROPDOWNS) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    configuration_path <- mod_import_server("import_project_configuration_1", r, DROPDOWNS)

    mod_export_server("export_1", r, configuration_path = configuration_path)
  })
}

## To be copied in the UI
# mod_sidebar_ui("sidebar_1")

## To be copied in the server
# mod_sidebar_server("sidebar_1")
