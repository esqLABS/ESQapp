#' tab_applications UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_tab_applications_ui <- function(id) {
  ns <- NS(id)
  tagList(
    mod_manage_parameter_sets_ui(ns("manage_parameters_applications")),
    mod_table_tab_ui(ns("tab_applications"))
  )
}

#' tab_applications Server Functions
#'
#' @noRd
mod_tab_applications_server <- function(id, r, DROPDOWNS){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    mod_table_tab_server(
      id = "tab_applications",
      r = r,
      tab_section = "applications",
      DROPDOWNS = DROPDOWNS
    )

    mod_manage_parameter_sets_server(
      id = "manage_parameters_applications",
      r = r,
      tab_section = "applications",
      state_name = "edit_mode_applications"
    )

  })
}

## To be copied in the UI
# mod_tab_applications_ui("tab_applications_1")

## To be copied in the server
# mod_tab_applications_server("tab_applications_1")
