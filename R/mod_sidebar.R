#' sidebar UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_sidebar_ui <- function(id) {
  ns <- NS(id)
  bslib::sidebar(
    mod_import_ui(ns("import_project_configuration_1")),
    hr(class = "hr-dvivder-esqapp"),
    mod_visulizer_app_ui(ns("visulizer_app")),
    hr(class = "hr-dvivder-esqapp"),
    mod_export_ui(ns("export_1")),
    tags$footer(
      style = "
        position: fixed;
        bottom: 0;
        left: 0;
        width: 100%;
        text-align: center;
        padding: 8px 0;
        background-color: #f8f9fa;
        color: #6c757d;
        font-size: 12px;
        border-top: 1px solid #e0e0e0;
        z-index: 1000;
      ",
      HTML(sprintf(
        '<a href="https://esqlabs.github.io/ESQapp/" target="_blank" style="text-decoration:none; color:inherit;">
          v%s
         </a> • © %s ESQLabs GmbH',
        app_version(),
        format(Sys.Date(), "%Y")
      ))
    )

  )
}

#' sidebar Server Functions
#'
#' @noRd
mod_sidebar_server <- function(id, r, DROPDOWNS, METADATA) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    configuration_path <- mod_import_server("import_project_configuration_1", r, DROPDOWNS, METADATA)

    mod_visulizer_app_server("visulizer_app")
    mod_export_server("export_1", r, configuration_path = configuration_path)
  })
}

## To be copied in the UI
# mod_sidebar_ui("sidebar_1")

## To be copied in the server
# mod_sidebar_server("sidebar_1")
