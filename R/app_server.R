#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic
  r <- list()

  r$states <- reactiveValues()

  r$data <- DataStructure$new()

  r$warnings <- WarningHandler$new()

  DROPDOWNS <- dropdown_values()

  mod_sidebar_server("sidebar_1", r, DROPDOWNS)
  mod_main_panel_server("main_panel_1", r, DROPDOWNS)
  mod_warning_server("warning_modal", r) # Call warnings module

  # Call utils logic
  mod_simulationtime_module_server("simulationtime_logic")

  # Show export status modal
  observeEvent(r$states$export_xlsx_status, {
    showModal(
      modalDialog(
        title = r$states$export_xlsx_status$status,
        p(
          r$states$export_xlsx_status$message
        ),
        easyClose = TRUE
      )
    )
    r$states$export_xlsx_status <- NULL
  })
}
