#' main_panel UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_main_panel_ui <- function(id) {
  ns <- NS(id)
  list(
    nav_panel(
      title = "Scenarios",
      mod_tab_scenarios_ui(ns("tab_scenarios_1"))
    ),
    nav_panel(
      title = "Individuals",
      mod_tab_individuals_ui(ns("tab_individuals_1"))
    ),
    nav_panel(
      title = "Populations",
      mod_tab_populations_ui(ns("tab_populations_1"))
    ),
    nav_panel(
      title = "Parameter sets",
      mod_tab_models_ui(ns("tab_models_1"))
    ),
    nav_panel(
      title = "Applications",
      mod_tab_applications_ui(ns("tab_applications_1"))
    ),
    nav_panel(
      title = "Plots",
      mod_tab_plots_ui(ns("tab_plots_1"))
    )
  )
}

#' main_panel Server Functions
#'
#' @noRd
mod_main_panel_server <- function(id, r, DROPDOWNS) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    mod_tab_scenarios_server("tab_scenarios_1", r, DROPDOWNS)

    mod_tab_individuals_server("tab_individuals_1", r, DROPDOWNS)

    mod_tab_populations_server("tab_populations_1", r, DROPDOWNS)

    mod_tab_models_server("tab_models_1", r, DROPDOWNS)

    mod_tab_applications_server("tab_applications_1", r, DROPDOWNS)

    mod_tab_plots_server("tab_plots_1", r, DROPDOWNS)
  })
}

## To be copied in the UI
# mod_main_panel_ui("main_panel_1")

## To be copied in the server
# mod_main_panel_server("main_panel_1")
