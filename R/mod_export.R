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

      export_success <- TRUE  # Track overall success

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

        # Try exporting and catch any errors
        tryCatch(
          {
            rio::export(
              x = sheet_list,
              file = export_path
            )
            message("Export successful: ", export_path)
          },
          error = function(e) {
            message("Error exporting ", config_file, ": File might be open or locked. Please close it and try again.")
            r$states$export_xlsx_status <- list(
              status = "Error: XLSX file might be open",
              message = paste0("File might be open or locked. Please close ", fs::path_file(export_path),
                               " and try again."
              )
            )
            export_success <<- FALSE  # Mark failure
          }
        )

      }

      # Set success message if no errors occurred
      if (export_success) {
        r$states$export_xlsx_status <- list(
          status = "Success",
          message = "Export completed successfully!"
        )
      }
    })


  })
}

## To be copied in the UI
# mod_export_ui("export_1")

## To be copied in the server
# mod_export_server("export_1")
