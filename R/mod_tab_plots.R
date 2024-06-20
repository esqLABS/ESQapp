#' tab_plots UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_tab_plots_ui <- function(id) {
  ns <- NS(id)
  div(
    style = "height: 150vh",
    mod_table_tab_ui(ns("tab_plots")),
    card(
      style = "margin-top: 25px;",
      height = 500, full_screen = TRUE,
      card_header(
        class = "d-flex justify-content-between",
        "Preview",
      ),
      card_body(
        class = "align-items-center",
        img(
          src = "https://esqlabs.github.io/esqlabsR/articles/esqlabsR-plot-results_files/figure-html/plot-time-profile-1.png",
          # height = 200,
          width = "50%"
        )
      )
    )
  )
}

#' tab_plots Server Functions
#'
#' @noRd
mod_tab_plots_server <- function(id, r, DROPDOWNS) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    mod_table_tab_server(
      id = "tab_plots",
      r = r,
      tab_section = "plots",
      DROPDOWNS = DROPDOWNS
    )
  })
}

## To be copied in the UI
# mod_tab_plots_ui("tab_plots_1")

## To be copied in the server
# mod_tab_plots_server("tab_plots_1")
