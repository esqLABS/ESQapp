#' tab_scenarios UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_tab_scenarios_ui <- function(id){
  ns <- NS(id)
  tagList(
    navset_pill(
      nav_panel(title = "scenarios",
                mod_edit_table_ui(ns("tab_scenarios"))),
      nav_panel(title = "Output Paths",
                mod_edit_table_ui(ns("tab_output_paths"))),
    )
  )
}

#' tab_scenarios Server Functions
#'
#' @noRd
mod_tab_scenarios_server <- function(id, r){
  moduleServer( id, function(input, output, session){
    ns <- session$ns

    mod_edit_table_server("tab_scenarios",
                          data = reactive(r$imported_data$scenarios$df))

    mod_edit_table_server("tab_output_paths",
                          data = reactive(r$imported_data$scenarios$output_paths))
  })
}

## To be copied in the UI
# mod_tab_scenarios_ui("tab_scenarios_1")

## To be copied in the server
# mod_tab_scenarios_server("tab_scenarios_1")
