#' tab_models UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_tab_models_ui <- function(id) {
  ns <- NS(id)
  tagList(
    mod_table_tab_ui(ns("tab_models"))
  )
}

#' tab_models Server Functions
#'
#' @noRd
mod_tab_models_server <- function(id, r, DROPDOWNS) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns


    mod_table_tab_server(
      id = "tab_models",
      r = r,
      tab_section = "models",
      DROPDOWNS = DROPDOWNS
    )
  })
}

## To be copied in the UI
# mod_tab_models_ui("tab_models_1")

## To be copied in the server
# mod_tab_models_server("tab_models_1")
