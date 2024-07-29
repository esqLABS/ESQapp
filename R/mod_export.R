#' export UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_export_ui <- function(id) {
  ns <- NS(id)
  tagList(
    actionButton(ns("export"), "Export", disabled = TRUE)
  )
}

#' export Server Functions
#'
#' @noRd
mod_export_server <- function(id, r, configuration_path) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Enable the export button when the configuration file is loaded first time
    observeEvent(configuration_path(), {
      updateActionButton(session, inputId = "export", disabled = FALSE)
    }, once = TRUE)


    # Listen to the export button
    observeEvent(input$export, {
      message("exporting data")

      for (config_file in r$data$get_config_files()) {
        if (!golem::app_prod()) {
          export_path <- paste0(fs::path_ext_remove(r$data[[config_file]]$file_path), "_copy.xlsx")
        } else {
          export_path <- r$data[[config_file]]$file_path
        }

        message("Exporting modified", config_file, " to ", export_path)

        sheet_list <- list()

        for (sheet in r$data[[config_file]]$sheets) {
          sheet_list[[sheet]] <- r$data[[config_file]][[sheet]]$modified
        }

        rio::export(
          x = sheet_list,
          file = export_path
        )
      }
    })
  })
}

## To be copied in the UI
# mod_export_ui("export_1")

## To be copied in the server
# mod_export_server("export_1")
