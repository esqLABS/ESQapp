#' sidebar UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_sidebar_ui <- function(id){
  ns <- NS(id)
  bslib::sidebar(
    mod_import_project_configuration_ui(ns("import_project_configuration_1"))
  )
}

#' sidebar Server Functions
#'
#' @noRd
mod_sidebar_server <- function(id, r){
  moduleServer( id, function(input, output, session){
    ns <- session$ns

    mod_import_project_configuration_server("import_project_configuration_1", r)

  })
}

## To be copied in the UI
# mod_sidebar_ui("sidebar_1")

## To be copied in the server
# mod_sidebar_server("sidebar_1")
