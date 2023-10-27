#' tab_edit_table UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_edit_table_ui <- function(id) {
  ns <- NS(id)
  tagList(
    editbl::eDTOutput(ns("df_editor"))
  )
}

#' tab_edit_table Server Functions
#'
#' @noRd
mod_edit_table_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    editbl::eDT(
      id = "df_editor",
      data = reactive({
        req(data())
        data()
      }),
      options = list(
        searching = TRUE,
        paging = FALSE
      )
    )
  })
}

## To be copied in the UI
# mod_edit_table_ui("tab_scenario_1")

## To be copied in the server
# mod_edit_table_server("tab_scenario_1")
