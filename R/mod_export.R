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
    tags$div(
      style = "display: flex; flex-direction: column; gap: 10px; width: 100%;",
      save_dropdown_ui(
        ns = ns,
        esqapp_id = "downloadEsqapp",
        zip_id = "downloadZip",
        disabled = TRUE
      )
    )
  )
}

#' export Server Functions
#'
#' @noRd
mod_export_server <- function(id, r, configuration_path) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Enable the export and download buttons when the configuration file is loaded first time
    observeEvent(configuration_path(),
      {
        shinyjs::enable("downloadButton")
      },
      once = TRUE
    )


    # Download handler for .esqapp file
    output$downloadEsqapp <- downloadHandler(
      filename = function() {
        project_name <- if (!is.null(configuration_path()) && !is.null(configuration_path()$projectName)) {
          gsub("[^A-Za-z0-9_-]", "_", configuration_path()$projectName)
        } else {
          "project"
        }
        paste0(project_name, "_", format(Sys.Date(), "%Y%m%d"), ".esqapp")
      },
      content = function(file) {
        # Get the project root directory
        config_path <- configuration_path()
        if (!is.null(config_path) && !is.null(config_path$projectConfigurationFilePath)) {
          original_project_root <- dirname(config_path$projectConfigurationFilePath)
        } else if (!is.null(r$config$project_root)) {
          original_project_root <- r$config$project_root
        } else {
          showNotification("Cannot determine project root directory", type = "error")
          return(NULL)
        }

        # Use the utility function to create the .esqapp file
        create_esqapp_shiny(
          original_project_root = original_project_root,
          r = r,
          output_file = file,
          DROPDOWN_COLUMN_TYPE_LIST = DROPDOWN_COLUMN_TYPE_LIST,
          NUMERIC_COLUMN_TYPE_LIST = NUMERIC_COLUMN_TYPE_LIST
        )
      }
    )

    # Download handler for .zip file
    output$downloadZip <- downloadHandler(
      filename = function() {
        project_name <- if (!is.null(configuration_path()) && !is.null(configuration_path()$projectName)) {
          gsub("[^A-Za-z0-9_-]", "_", configuration_path()$projectName)
        } else {
          "project"
        }
        paste0(project_name, "_", format(Sys.Date(), "%Y%m%d"), ".zip")
      },
      content = function(file) {
        # Get the project root directory
        config_path <- configuration_path()
        if (!is.null(config_path) && !is.null(config_path$projectConfigurationFilePath)) {
          original_project_root <- dirname(config_path$projectConfigurationFilePath)
        } else if (!is.null(r$config$project_root)) {
          original_project_root <- r$config$project_root
        } else {
          showNotification("Cannot determine project root directory", type = "error")
          return(NULL)
        }

        # Use the utility function to create the .zip file (same as .esqapp, just different extension)
        create_esqapp_shiny(
          original_project_root = original_project_root,
          r = r,
          output_file = file,
          DROPDOWN_COLUMN_TYPE_LIST = DROPDOWN_COLUMN_TYPE_LIST,
          NUMERIC_COLUMN_TYPE_LIST = NUMERIC_COLUMN_TYPE_LIST
        )
      }
    )
  })
}

## To be copied in the UI
# mod_export_ui("export_1")

## To be copied in the server
# mod_export_server("export_1")
