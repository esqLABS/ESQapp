#' tab_individuals UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_tab_individuals_ui <- function(id){
  ns <- NS(id)
  tagList(
    mod_edit_table_ui(ns("tab_individuals"))
  )
}

#' tab_individuals Server Functions
#'
#' @noRd
mod_tab_individuals_server <- function(id, r){
  moduleServer( id, function(input, output, session){
    ns <- session$ns

    mod_edit_table_server("tab_individuals",
                          data = reactive(r$imported_data$individuals$df)
    )

  })
}

## To be copied in the UI
# mod_tab_individuals_ui("tab_individuals_1")

## To be copied in the server
# mod_tab_individuals_server("tab_individuals_1")
