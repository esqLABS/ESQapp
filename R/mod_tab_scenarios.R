#' tab_scenarios UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_tab_scenarios_ui <- function(id) {
  ns <- NS(id)
  tagList(
    mod_table_tab_ui(ns("tab_scenarios"))
  )
}

#' tab_scenarios Server Functions
#'
#' @noRd
mod_tab_scenarios_server <- function(id, r) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    mod_table_tab_server(
      id = "tab_scenarios",
      r = r,
      tab_section = "scenarios"
    )

    # Update factor levels
    # observe({
    #   req(r$data$scenarios$Scenarios$modified)
    #   r$data$scenarios$Scenarios$modified$IndividualId <-
    #     factor(r$data$scenarios$Scenarios$modified$IndividualId,
    #       levels = unique(c(
    #         r$data$scenarios$Scenarios$modified$IndividualId,
    #         r$data$individuals$IndividualBiometrics$modified$IndividualId
    #       ))
    #     )
    # })
  })
}

## To be copied in the UI
# mod_tab_scenarios_ui("tab_scenarios_1")

## To be copied in the server
# mod_tab_scenarios_server("tab_scenarios_1")
