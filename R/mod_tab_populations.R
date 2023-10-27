#' tab_populations UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_tab_populations_ui <- function(id){
  ns <- NS(id)
  tagList(
    mod_edit_table_ui(ns("tab_populations"))
  )
}

#' tab_populations Server Functions
#'
#' @noRd
mod_tab_populations_server <- function(id, r){
  moduleServer( id, function(input, output, session){
    ns <- session$ns

    mod_edit_table_server("tab_populations",
                          data = reactive(r$imported_data$populations$df)
    )

  })
}

## To be copied in the UI
# mod_tab_populations_ui("tab_populations_1")

## To be copied in the server
# mod_tab_populations_server("tab_populations_1")
